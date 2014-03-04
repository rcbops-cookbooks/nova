#
# Cookbook Name:: nova
# Recipe:: vncproxy
#
# Copyright 2012-2013, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "nova::nova-common"

platform_options = node["nova"]["platform"]

platform_options["nova_vncproxy_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

# required for vnc console authentication
platform_options["nova_vncproxy_consoleauth_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

service platform_options["nova_vncproxy_service"] do
  service_name platform_options["nova_vncproxy_service"]
  supports :status => true, :restart => true
  action [:enable, :start]
  subscribes :restart, "nova_conf[/etc/nova/nova.conf]", :delayed
end

service platform_options["nova_vncproxy_consoleauth_service"] do
  service_name platform_options["nova_vncproxy_consoleauth_service"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, "nova_conf[/etc/nova/nova.conf]", :delayed
end

if node["nova"]["services"]["novnc-proxy"]["scheme"] == "https"
  cert_file = "#{node["nova"]["ssl"]["dir"]}/certs/#{node["nova"]["services"]["novnc-proxy"]["cert_file"]}"
  key_file = "#{node["nova"]["ssl"]["dir"]}/private/#{node["nova"]["services"]["novnc-proxy"]["key_file"]}"

  cookbook_file cert_file do
    source node["nova"]["services"]["novnc-proxy"]["cert_file"]
    mode 0644
    owner "root"
    group "root"
  end

  case node["platform"]
  when "ubuntu", "debian"
    key_grp = "ssl-cert"
    group "ssl-cert" do
      action :modify
      members "nova"
      append true
    end
  else
    key_grp = "root"
  end

  cookbook_file key_file do
    source node["nova"]["services"]["novnc-proxy"]["key_file"]
    mode 0640
    owner "root"
    group key_grp
  end
end
#
# Workaround to ensure that novnc web server doesn't show file listings
# https://github.com/kanaka/noVNC/issues/226
cookbook_file "/usr/share/novnc/index.html" do
  source "blank.html"
  mode 0644
  owner "root"
  group "root"
end
cookbook_file "/usr/share/novnc/include/index.html" do
  source "blank.html"
  mode 0644
  owner "root"
  group "root"
end

cookbook_file "/usr/share/novnc/favicon.ico" do
  source "novncproxy.ico"
  mode 0644
  owner "root"
  group "root"
end
