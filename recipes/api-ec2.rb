#
# Cookbook Name:: nova
# Recipe:: api-ec2
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

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "nova::nova-common"
include_recipe "monitoring"


# Set a secure keystone service password
node.set_unless['nova']['service_pass'] = secure_password

if not node['package_component'].nil?
  release = node['package_component']
else
  release = "folsom"
end

platform_options=node["nova"]["platform"][release]

directory "/var/lock/nova" do
    owner "nova"
    group "nova"
    mode "0700"
    action :create
end

package "python-keystone" do
  action :install
end

platform_options["api_ec2_packages"].each do |pkg|
  package pkg do
    action :install
    options platform_options["package_overrides"]
  end
end

service "nova-api-ec2" do
  service_name platform_options["api_ec2_service"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, resources(:nova_conf => "/etc/nova/nova.conf"), :delayed
  subscribes :restart, resources(:template => "/etc/nova/logging.conf"), :delayed
end

monitoring_procmon "nova-api-ec2" do
  service_name = platform_options["api_ec2_service"]
  pname = platform_options["api_ec2_process_name"]
  process_name pname
  script_name service_name
end

monitoring_metric "nova-api-ec2-proc" do
  type "proc"
  proc_name "nova-api-ec2"
  proc_regex platform_options["api_ec2_service"]

  alarms(:failure_min => 2.0)
end


ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint("keystone", "keystone", "service-api")
keystone = get_settings_by_role("keystone","keystone")
ec2_public_endpoint = get_bind_endpoint("nova", "ec2-public")
ec2_admin_endpoint = get_bind_endpoint("nova", "ec2-admin")

# Register Service Tenant
keystone_tenant "Register Service Tenant" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["nova"]["service_tenant_name"]
  tenant_description "Service Tenant"
  tenant_enabled "true" # Not required as this is the default
  action :create
end

# Register Service User
keystone_user "Register Service User" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["nova"]["service_tenant_name"]
  user_name node["nova"]["service_user"]
  user_pass node["nova"]["service_pass"]
  user_enabled "true" # Not required as this is the default
  action :create
end

## Grant Admin role to Service User for Service Tenant ##
keystone_role "Grant 'admin' Role to Service User for Service Tenant" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["nova"]["service_tenant_name"]
  user_name node["nova"]["service_user"]
  role_name node["nova"]["service_role"]
  action :grant
end

# Register EC2 Service
keystone_service "Register EC2 Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_name "ec2"
  service_type "ec2"
  service_description "EC2 Compatibility Layer"
  action :create
end

template "/etc/nova/api-paste.ini" do
  source "#{release}/api-paste.ini.erb"
  owner "nova"
  group "nova"
  mode "0600"
  variables(:component  => node["package_component"],
            :service_port => ks_service_endpoint["port"],
            :keystone_api_ipaddress => ks_service_endpoint["host"],
            :admin_port => ks_admin_endpoint["port"],
            :admin_token => keystone["admin_token"]
  )
  notifies :restart, resources(:service => "nova-api-ec2"), :delayed
end

# Register EC2 Endpoint
keystone_endpoint "Register Compute Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_type "ec2"
  endpoint_region node["nova"]["compute"]["region"]
  endpoint_adminurl ec2_admin_endpoint["uri"]
  endpoint_internalurl ec2_public_endpoint["uri"]
  endpoint_publicurl ec2_public_endpoint["uri"]
  action :create
end
