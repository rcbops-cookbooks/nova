#
# Cookbook Name:: nova
# Recipe:: scheduler
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

platform_options["nova_scheduler_packages"].each do |pkg|
  package pkg do
    options platform_options["package_options"]
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
  end
end

service "nova-scheduler" do
  service_name platform_options["nova_scheduler_service"]
  supports :status => true, :restart => true
  action [:enable, :start]
  subscribes :restart, "nova_conf[/etc/nova/nova.conf]", :delayed
end

include_recipe "nova::nova-scheduler-patch"
