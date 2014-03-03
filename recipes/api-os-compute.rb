#
# Cookbook Name:: nova
# Recipe:: api-os-compute
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

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "nova::nova-common"

# Set a secure keystone service password
node.set_unless['nova']['service_pass'] = secure_password

platform_options = node["nova"]["platform"]

directory "/var/lock/nova" do
  owner "nova"
  group "nova"
  mode "0700"
  action :create
end

include_recipe "osops-utils::python-keystone"

platform_options["api_os_compute_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

api_endpoint = get_bind_endpoint("nova", "api")
api_internal_endpoint = get_bind_endpoint("nova", "internal-api")
api_admin_endpoint = get_bind_endpoint("nova", "admin-api")

service "nova-api-os-compute" do
  service_name platform_options["api_os_compute_service"]
  supports :status => true, :restart => true
  unless api_endpoint["scheme"] == "https"
    action :enable
    subscribes :restart, "nova_conf[/etc/nova/nova.conf]", :delayed
  else
    action [ :disable, :stop ]
  end
end

# Setup SSL
if api_endpoint["scheme"] == "https"
  include_recipe "nova::api-os-compute-ssl"
else
  if node.recipe?"apache2"
    apache_site "openstack-nova-osapi" do
      enable false
      notifies :restart, "service[apache2]", :immediately
    end
  end
end

# Search for keystone endpoint info
ks_api_role = "keystone-api"
ks_ns = "keystone"
ks_admin_endpoint = get_access_endpoint(ks_api_role, ks_ns, "admin-api")
ks_service_endpoint = get_access_endpoint(ks_api_role, ks_ns, "service-api")
# Get settings from role[keystone-setup]
keystone = get_settings_by_role("keystone-setup", "keystone")

# Register Service Tenant
keystone_tenant "Register Service Tenant" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["nova"]["service_tenant_name"]
  tenant_description "Service Tenant"
  tenant_enabled true # Not required as this is the default
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
  user_enabled true # Not required as this is the default
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

# Register Compute Service
keystone_service "Register Compute Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_name "nova"
  service_type "compute"
  service_description "Nova Compute Service"
  action :create
end

template "/etc/nova/api-paste.ini" do
  source "api-paste.ini.erb"
  owner "nova"
  group "nova"
  mode "0600"
  variables(
    "keystone_api_ipaddress" => ks_service_endpoint["host"],
    "service_port" => ks_service_endpoint["port"],
    "service_protocol" => ks_service_endpoint["scheme"],
    "admin_port" => ks_admin_endpoint["port"],
    "admin_protocol" => ks_admin_endpoint["scheme"],
    "admin_token" => keystone["admin_token"]
  )
  unless api_endpoint["scheme"] == "https"
    notifies :restart, "service[nova-api-os-compute]", :delayed
  else
    notifies :restart, "service[apache2]", :immediately
  end
end

# Register Compute Endpoint
keystone_endpoint "Register Compute Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_type "compute"
  endpoint_region node["osops"]["region"]
  endpoint_adminurl api_admin_endpoint["uri"]
  endpoint_internalurl api_internal_endpoint["uri"]
  endpoint_publicurl api_endpoint["uri"]
  action :recreate
end

include_recipe "nova::nova-osapi-patch"
