#
# Cookbook Name:: nova
# Recipe:: libvirt
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

include_recipe "monitoring"

if not node['package_component'].nil?
  release = node['package_component']
else
  release = "essex-final"
end

platform_options = node["nova"]["platform"][release]

platform_options["libvirt_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

# oh fedora...
bash "create libvirtd group" do
  cwd "/tmp"
  user "root"
  code <<-EOH
      groupadd -f libvirtd
      usermod -G libvirtd nova
  EOH
  only_if { platform?(%w{fedora redhat centos}) }
end

# oh redhat
# http://fedoraproject.org/wiki/Getting_started_with_OpenStack_EPEL#Installing_within_a_VM
# ln -s /usr/libexec/qemu-kvm /usr/bin/qemu-system-x86_64
link "/usr/bin/qemu-system-x86_64" do
  to "/usr/libexec/qemu-kvm"
  only_if { platform?(%w{fedora redhat centos}) }
end

service "libvirt-bin" do
  service_name platform_options["libvirt_service"]
  supports :status => true, :restart => true
  action :enable
end

monitoring_procmon "libvirt-bin" do
  service_name=platform_options["libvirt_service"]
  process_name "libvirtd"
  script_name service_name
end

monitoring_metric "libvirtd-proc" do
  type "proc"
  proc_name "libvirtd-consoleauth"
  proc_regex platform_options["libvirt_service"]

  alarms(:failure_min => 1.0)
end

#
# TODO(breu): this section needs to be rewritten to support key privisioning
#
template "/etc/libvirt/libvirtd.conf" do
  source "libvirtd.conf.erb"
  owner "nova"
  group "nova"
  mode "0600"
  variables(
    :auth_tcp => node["nova"]["libvirt"]["auth_tcp"]
  )
  notifies :restart, resources(:service => "libvirt-bin"), :immediately
end

template "/etc/default/libvirt-bin" do
  source "libvirt-bin.erb"
  owner "nova"
  group "nova"
  mode "0600"
  notifies :restart, resources(:service => "libvirt-bin"), :immediately
  only_if { platform?(%w{ubuntu debian}) }
end

template "/etc/sysconfig/libvirtd" do
  source "libvirtd.erb"
  owner "nova"
  group "nova"
  mode "0600"
  notifies :restart, resources(:service => "libvirt-bin"), :immediately
  only_if { platform?(%w{fedora redhat centos}) }
end

monitoring_metric "libvirt" do
  type "libvirt"
end

# remove default libvirt network
execute "remove libvirt default network" do
  command "virsh net-destroy default && virsh net-autostart default --disable"
  action :run
  only_if "virsh net-list | grep default"
end
