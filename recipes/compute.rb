#
# Cookbook Name:: nova
# Recipe:: compute
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

# NOTE(shep): Copying to a new array
# this is due to Chef::Exceptions::ImmutableAttributeModification error
# see http://www.opscode.com/blog/2013/02/05/chef-11-in-depth-attributes-changes/
nova_compute_packages =
  platform_options["nova_compute_packages"].each.collect { |x| x }

if platform?(%w(ubuntu))
  case node["nova"]["libvirt"]["virt_type"]
  when "kvm"
    nova_compute_packages.push("nova-compute-kvm")
  when "qemu"
    nova_compute_packages.push("nova-compute-qemu")
  end
end

nova_compute_packages.each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
  end
end

cinder_setup_info = get_settings_by_role("cinder-setup", "cinder")

# NOTE(wilk): Copying to a new array
# this is due to Chef::Exceptions::ImmutableAttributeModification error
# see http://www.opscode.com/blog/2013/02/05/chef-11-in-depth-attributes-changes/
cinder_multipath_packages =
  platform_options["cinder_multipath_packages"].each.collect { |x| x }

if not cinder_setup_info.nil? and
  cinder_setup_info["storage"]["provider"] == "emc" and
  cinder_setup_info["storage"]["enable_multipath"] == true
  cinder_multipath_packages.each do |pkg|
    package pkg do
      action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
      options platform_options["package_options"]
    end
  end
  template "/etc/multipath.conf" do
    source "emc_multipath.conf.erb"
    owner "root"
    group "root"
    mode "700"
  end
  include_recipe "nova::nova-volume-multipath-patches"
end

cookbook_file "/etc/nova/nova-compute.conf" do
  source "nova-compute.conf"
  mode "0600"
  owner "nova"
  group "nova"
  action :create
end

template "/var/lib/nova/.ssh/config" do
  source "libvirtd-ssh-config.erb"
  owner "nova"
  group "nova"
  mode "0600"
end

service "nova-compute" do
  service_name platform_options["nova_compute_service"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, "nova_conf[/etc/nova/nova.conf]", :delayed
end

include_recipe "nova::libvirt"

# Sysctl tunables
sysctl_multi "nova" do
  instructions "net.ipv4.ip_forward" => "1"
end
