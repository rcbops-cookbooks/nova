#
# Cookbook Name:: nova
# Recipe:: nova-setup
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

# Allow for using a well known db password
if node["developer_mode"] == true
  node.set_unless["nova"]["db"]["password"] = "nova"
else
  node.set_unless["nova"]["db"]["password"] = secure_password
end

include_recipe "nova::nova-common"
include_recipe "mysql::client"
include_recipe "mysql::ruby"

# Search for keystone endpoint info
ks_api_role = "keystone-api"
ks_ns = "keystone"
ks_service_endpoint = get_access_endpoint(ks_api_role, ks_ns, "service-api")
# Get settings from role[keystone-setup]
keystone = get_settings_by_role("keystone-setup", "keystone")

keystone_admin_user = keystone["admin_user"]
keystone_admin_password = keystone["users"][keystone_admin_user]["password"]
keystone_admin_tenant = keystone["users"][keystone_admin_user]["default_tenant"]

#creates db and user
#function defined in osops-utils/libraries
create_db_and_user(
  "mysql",
  node["nova"]["db"]["name"],
  node["nova"]["db"]["username"],
  node["nova"]["db"]["password"])

execute "nova-manage db sync" do
  command "nova-manage db sync"
  user "nova"
  group "nova"
  action :run
  #  not_if "nova-manage db version && test $(nova-manage db version) -gt 0"
end

execute "nova reservations_index_deleted" do
  user "nova"
  group "nova"
  environment ({'PATH' => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'})
  command <<-EOH
    mysql -u #{node["nova"]["db"]["username"]} \
    -p#{node["nova"]["db"]["password"]} \
    -e "create index \"rax_ix_reservations_deleted\" on reservations (deleted);" \
    #{node["nova"]["db"]["name"]}
  EOH
  not_if <<-EOH
    mysql -s -N -u#{node["nova"]["db"]["username"]} \
    -p#{node["nova"]["db"]["password"]} \
    -e "show index from token where key_name = 'rax_ix_reservations_deleted'" \
    #{node["nova"]["db"]["name"]} | grep -o rax_ix_reservations_deleted
    EOH
  action :nothing
  subscribes :run, "execute[nova-manage db sync]", :immediately
end

execute "nova instances_index_deleted" do
  user "nova"
  group "nova"
  environment ({'PATH' => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'})
  command <<-EOH
    mysql -u #{node["nova"]["db"]["username"]} \
    -p#{node["nova"]["db"]["password"]} \
    -e "create index \"rax_ix_instances_deleted\" on instances (deleted);" \
    #{node["nova"]["db"]["name"]}
  EOH
  not_if <<-EOH
    mysql -s -N -u#{node["nova"]["db"]["username"]} \
    -p#{node["nova"]["db"]["password"]} \
    -e "show index from token where key_name = 'rax_ix_instances_deleted'" \
    #{node["nova"]["db"]["name"]} | grep -o rax_ix_instances_deleted
    EOH
  action :nothing
  subscribes :run, "execute[nova-manage db sync]", :immediately
end
