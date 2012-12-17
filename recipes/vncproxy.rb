#
# Cookbook Name:: nova
# Recipe:: vncproxy
#
# Copyright 2012, Rackspace US, Inc.
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
include_recipe "monitoring"


if not node['package_component'].nil?
  release = node['package_component']
else
  release = "essex-final"
end

platform_options = node["nova"]["platform"][release]

platform_options["nova_vncproxy_packages"].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options["package_overrides"]
  end
end

# required for vnc console authentication
platform_options["nova_vncproxy_consoleauth_packages"].each do |pkg|
  package pkg do
    action :upgrade
  end
end

service "nova-vncproxy" do
  service_name platform_options["nova_vncproxy_service"]
  supports :status => true, :restart => true
  action [ :enable, :start ]
  subscribes :restart, resources(:nova_conf => "nova.conf"), :delayed
end

monitoring_procmon "nova-vncproxy" do
  service_name=platform_options["nova_vncproxy_service"]
  process_name "nova-novncproxy"
  script_name service_name
end

monitoring_metric "nova-vncproxy-proc" do
  type "proc"
  proc_name "nova-vncproxy"
  proc_regex platform_options["nova_vncproxy_service"]

  alarms(:failure_min => 2.0)
end

service "nova-consoleauth" do
  service_name platform_options["nova_vncproxy_consoleauth_service"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, resources(:nova_conf => "nova.conf"), :delayed
end

monitoring_procmon "nova-consoleauth" do
  service_name=platform_options["nova_vncproxy_consoleauth_service"]
  pname=platform_options["nova_vncproxy_consoleauth_process_name"]
  process_name pname
  script_name service_name
end

monitoring_metric "nova-consoleauth-proc" do
  type "proc"
  proc_name "nova-consoleauth"
  proc_regex platform_options["nova_vncproxy_consoleauth_service"]

  alarms(:failure_min => 1.0)
end
