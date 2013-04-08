#
# Cookbook Name:: nova
# Recipe:: compute
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

platform_options = node["nova"]["platform"]

nova_compute_packages = platform_options["nova_compute_packages"]

if platform?(%w(ubuntu))
  if node["nova"]["libvirt"]["virt_type"] == "kvm"
    nova_compute_packages << "nova-compute-kvm"
  elsif node["nova"]["libvirt"]["virt_type"] == "qemu"
    nova_compute_packages << "nova-compute-qemu"
  end
end

nova_compute_packages.each do |pkg|
  package pkg do
    action :install
    options platform_options["package_overrides"]
  end
end

template "/etc/nova/nova-compute.conf" do
  source "nova-compute.conf.erb"
  owner "nova"
  group "nova"
  mode "0600"
  action :create
  only_if { node["nova"]["network"]["provider"] == "quantum" }
end

cookbook_file "/etc/nova/nova-compute.conf" do
  source "nova-compute.conf"
  mode "0600"
  owner "nova"
  group "nova"
  action :create
  not_if { node["nova"]["network"]["provider"] == "quantum" }
end

template "/var/lib/nova/.ssh/config" do
  source "libvirtd-ssh-config"
  owner "nova"
  group "nova"
  mode "0600"
end

service "nova-compute" do
  service_name platform_options["nova_compute_service"]
  supports :status => true, :restart => true
  action :enable
  subscribes :restart, resources(:nova_conf => "/etc/nova/nova.conf"), :delayed
  subscribes :restart, resources(:template => "/etc/nova/logging.conf"), :delayed
end

monitoring_procmon "nova-compute" do
  service_name=platform_options["nova_compute_service"]
  process_name "nova-compute"
  script_name service_name
end

monitoring_metric "nova-compute-proc" do
  type "proc"
  proc_name "nova-compute"
  proc_regex platform_options["nova_compute_service"]

  alarms(:failure_min => 2.0)
end

include_recipe "nova::libvirt"

execute "remove vhost-net module" do
    command "rmmod vhost_net"
    notifies :restart, "service[nova-compute]"
    notifies :restart, "service[libvirt-bin]"
    only_if "lsmod | grep vhost_net"
end

# Sysctl tunables
sysctl_multi "nova" do
  instructions "net.ipv4.ip_forward" => "1"
end
