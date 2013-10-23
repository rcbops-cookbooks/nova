#
# Cookbook Name:: nova
# Recipe:: api-metadata
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

directory "/var/lock/nova" do
  owner "nova"
  group "nova"
  mode "0700"
  action :create
end

include_recipe "osops-utils::python-keystone"

platform_options["api_metadata_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

service "nova-api-metadata" do
  service_name platform_options["api_metadata_service"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, "nova_conf[/etc/nova/nova.conf]", :delayed
end

# Search for keystone endpoint info
ks_api_role = "keystone-api"
ks_ns = "keystone"
ks_admin_endpoint = get_access_endpoint(ks_api_role, ks_ns, "admin-api")
ks_service_endpoint = get_access_endpoint(ks_api_role, ks_ns, "service-api")
# Get settings from role[keystone-setup]
keystone = get_settings_by_role("keystone-setup", "keystone")

template "/etc/nova/api-paste.ini" do
  source "api-paste.ini.erb"
  owner "nova"
  group "nova"
  mode "0600"
  variables(
    "keystone_api_ipaddress" => ks_admin_endpoint["host"],
    "admin_port" => ks_admin_endpoint["port"],
    "admin_protocol" => ks_admin_endpoint["scheme"],
    "service_port" => ks_service_endpoint["port"],
    "service_protocol" => ks_service_endpoint["scheme"],
    "admin_token" => keystone["admin_token"]
  )
  notifies :restart, "service[nova-api-metadata]", :delayed
end
