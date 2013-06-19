#
# Cookbook Name:: nova
# Recipe:: volume
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
include_recipe "nova::api-os-volume"
include_recipe "monitoring"

if not node['package_component'].nil?
  release = node['package_component']
else
  release = "folsom"
end

platform_options = node["nova"]["platform"][release]

package "python-keystone" do
  action :install
end

platform_options["nova_volume_packages"].each do |pkg|
  package pkg do
    action :install
    options platform_options["package_overrides"]
  end
end

if node["nova"]["volumes"]["enabled"] == true
  iscsi_service_state=[ :enable, :start ]
else
  iscsi_service_state=[ :disable, :stop ]
end

service "iscsitarget" do
  service_name platform_options["iscsi_service"]
  supports :status => true, :restart => true
  action iscsi_service_state
end

service "nova-volume" do
  service_name platform_options["nova_volume_service"]
  supports :status => true, :restart => true
  action iscsi_service_state
  subscribes :restart, "template[/etc/nova/nova.conf]", :delayed
  subscribes :restart, "template[/etc/nova/logging.conf]", :delayed
end

monitoring_procmon "nova-compute" do
  service_name=platform_options["nova_volume_service"]
  process_name "nova-volume"
  script_name service_name
  only_if { node["nova"]["volumes"]["enabled"] == true }
end

ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint("keystone-api", "keystone", "service-api")
keystone = get_settings_by_role("keystone","keystone")
volume_endpoint = get_access_endpoint("nova-volume", "nova", "volume")

# Register Volume Service
keystone_service "Register Volume Service" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_name "Volume Service"
  service_type "volume"
  service_description "Nova Volume Service"
  action :create
end

# Register Image Endpoint
keystone_endpoint "Register Volume Endpoint" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  service_type "volume"
  endpoint_region "RegionOne"
  endpoint_adminurl volume_endpoint["uri"]
  endpoint_internalurl volume_endpoint["uri"]
  endpoint_publicurl volume_endpoint["uri"]
  action :create
end
