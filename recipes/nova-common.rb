#
# Cookbook Name:: nova
# Recipe:: nova-common
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

include_recipe "osops-utils::autoetchosts"

platform_options = node["nova"]["platform"]

# fix ownership of /var/log/nova/nova.log
file "/var/log/nova/nova.log" do
  owner "nova"
  group "nova"
  mode "0600"
  only_if { ::File.exists?("/var/log/nova/nova.log") }
end

# remove openstack-nova-volume on RHEL to cleanup package dependencies
package "openstack-nova-volume" do
  action :remove
  only_if { node["platform_family"] == "rhel" }
end

platform_options["common_packages"].each do |pkg|
  include_recipe "osops-utils::#{pkg}"
end

directory "/etc/nova" do
  action :create
  owner "nova"
  group "nova"
  mode "0700"
end

# Search for keystone endpoint info
ks_api_role = "keystone-api"
ks_ns = "keystone"
ks_admin_endpoint = get_access_endpoint(ks_api_role, ks_ns, "admin-api")
# DE153 replacing public endpoint default for openrc with internal endpoint
ks_internal_endpoint = get_access_endpoint(ks_api_role, ks_ns, "internal-api")
# Get settings from role[keystone-setup]
keystone = get_settings_by_role("keystone-setup", "keystone")
# Get credential settings from role[keystone-setup]
ec2_creds = get_settings_by_role("keystone-setup", "credentials")
# Search for nova api endpoint info
nova_api_endpoint = get_access_endpoint("nova-api-os-compute", "nova", "api")
# Search for nova ec2 api endpoint info
ec2_public_endpoint = get_access_endpoint("nova-api-ec2", "nova", "ec2-public")

nova_conf "/etc/nova/nova.conf" do
  action :create
end

# TODO: need to re-evaluate this for accuracy
template "/root/openrc" do
  source "openrc.erb"
  owner "nova"
  group "nova"
  mode "0600"
  vars = {
    "user" => keystone["admin_user"],
    "tenant" => keystone["users"][keystone["admin_user"]]["default_tenant"],
    "password" => keystone["users"][keystone["admin_user"]]["password"],
    "keystone_auth_uri" => ks_internal_endpoint["uri"],
    "nova_api_version" => "1.1",
    "nova_region" => node["osops"]["region"],
    "auth_strategy" => "keystone",
    "ec2_url" => ec2_public_endpoint["uri"],
    "ec2_access_key" => ec2_creds["EC2"][keystone['admin_user']]["access"],
    "ec2_secret_key" => ec2_creds["EC2"][keystone['admin_user']]["secret"]
  }
  variables(vars)
end

# NOTE(shep): this is for backwards compatability with Alamo
link "/root/.novarc" do
  to "/root/openrc"
  link_type :symbolic
  only_if { File.exists? "/root/openrc" }
end

execute "enable nova login" do
  command "usermod -s /bin/sh nova"
  not_if 'test $(getent passwd nova |cut -f7 -d:) = /bin/sh'
end

dsh_group "nova" do
  user "nova"
  admin_user "nova"
  group "nova"
end
