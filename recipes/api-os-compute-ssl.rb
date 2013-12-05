#
# Cookbook Name:: nova
# Recipe:: nova-ssl
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

include_recipe "apache2"
include_recipe "apache2::mod_wsgi"
include_recipe "apache2::mod_rewrite"
include_recipe "osops-utils::mod_ssl"
include_recipe "osops-utils::ssl_packages"

# Remove monit conf file if it exists
if node.attribute?"monit"
  if node["monit"].attribute?"conf.d_dir"
    file "#{node['monit']['conf.d_dir']}/nova-api-os-compute.conf" do
      action :delete
      notifies :reload, "service[monit]", :immediately
    end
  end
end

# setup cert files
case node["platform"]
when "ubuntu", "debian"
  grp = "ssl-cert"
else
  grp = "root"
end

cookbook_file "#{node["nova"]["ssl"]["dir"]}/certs/#{node["nova"]["services"]["api"]["cert_file"]}" do
  source "nova_osapi.pem"
  mode 0644
  owner "root"
  group "root"
end

cookbook_file "#{node["nova"]["ssl"]["dir"]}/private/#{node["nova"]["services"]["api"]["key_file"]}" do
  source "nova_osapi.key"
  mode 0644
  owner "root"
  group grp
end

unless node["nova"]["services"]["api"]["chain_file"].nil?
  cookbook_file "#{node["nova"]["ssl"]["dir"]}/certs/#{node["nova"]["services"]["api"]["chain_file"]}" do
    source node["nova"]["services"]["api"]["chain_file"]
    mode 0644
    owner "root"
    group "root"
  end
end

# setup wsgi file

directory "#{node["apache"]["dir"]}/wsgi" do
  action :create
  owner "root"
  group "root"
  mode "0755"
end

cookbook_file "#{node["apache"]["dir"]}/wsgi/#{node["nova"]["services"]["api"]["wsgi_file"]}" do
  source "osapi_modwsgi.py"
  mode 0644
  owner "root"
  group "root"
end

api_bind = get_bind_endpoint("nova", "api")

unless node["nova"]["services"]["api"].attribute?"cert_override"
  cert_location = "#{node["nova"]["ssl"]["dir"]}/certs/#{node["nova"]["services"]["api"]["cert_file"]}"
else
  cert_location = node["nova"]["services"]["api"]["cert_override"]
end

unless node["nova"]["services"]["api"].attribute?"key_override"
  key_location = "#{node["nova"]["ssl"]["dir"]}/private/#{node["nova"]["services"]["api"]["key_file"]}"
else
  key_location = node["nova"]["services"]["api"]["key_override"]
end

unless node["nova"]["services"]["api"]["chain_file"].nil?
  chain_location = "#{node["nova"]["ssl"]["dir"]}/certs/#{node["nova"]["services"]["api"]["chain_file"]}"
else
  chain_location = "donotset"
end

template value_for_platform(
  ["ubuntu", "debian", "fedora"] => {
    "default" => "#{node["apache"]["dir"]}/sites-available/openstack-nova-osapi"
  },
  "fedora" => {
    "default" => "#{node["apache"]["dir"]}/vhost.d/openstack-nova-osapi"
  },
  ["redhat", "centos"] => {
    "default" => "#{node["apache"]["dir"]}/conf.d/openstack-nova-osapi"
  },
  "default" => {
    "default" => "#{node["apache"]["dir"]}/openstack-nova-osapi"
  }
) do
  source "modwsgi_vhost.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :listen_ip => api_bind["host"],
    :service_port => api_bind["port"],
    :cert_file => cert_location,
    :key_file => key_location,
    :chain_file => chain_location,
    :wsgi_file  => "#{node["apache"]["dir"]}/wsgi/#{node["nova"]["services"]["api"]["wsgi_file"]}",
    :proc_group => "nova-osapi",
    :log_file => "/var/log/nova/osapi.log"
  )
  notifies :reload, "service[apache2]", :delayed
end

apache_site "openstack-nova-osapi" do
  enable true
  notifies :restart, "service[apache2]", :immediately
end
