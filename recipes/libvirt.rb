#
# Cookbook Name:: nova
# Recipe:: libvirt
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

platform_options = node["nova"]["platform"]

platform_options["libvirt_packages"].each do |pkg|
  package pkg do
    action node["osops"]["do_package_upgrades"] == true ? :upgrade : :install
    options platform_options["package_options"]
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
#
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
  notifies :restart, "service[libvirt-bin]", :immediately
end

template "/etc/default/libvirt-bin" do
  source "libvirt-bin.erb"
  owner "nova"
  group "nova"
  mode "0600"
  notifies :restart, "service[libvirt-bin]", :immediately
  only_if { platform?(%w{ubuntu debian}) }
end

template "/etc/sysconfig/libvirtd" do
  source "libvirtd.erb"
  owner "nova"
  group "nova"
  mode "0600"
  notifies :restart, "service[libvirt-bin]", :immediately
  only_if { platform?(%w{fedora redhat centos}) }
end

# remove default libvirt network
execute "remove libvirt default network" do
  command "virsh net-destroy default && virsh net-autostart default --disable"
  action :run
  only_if "virsh net-list | grep default"
end

# is cinder using rbd for volumes? If so, we can configure the libvirt secret
# so that nova can boot from those volumes
cinder_opts = get_settings_by_role('cinder-volume', 'cinder')

unless cinder_opts.nil?
  if cinder_opts['storage']['provider'] == 'rbd'

    if rcb_safe_deref(node, "ceph.config.fsid")

      include_recipe 'ceph::repo'
      include_recipe 'ceph'
      include_recipe 'ceph::conf'
    end

    rbd_user = cinder_opts['storage']['rbd']['rbd_user']
    rbd_secret_uuid = cinder_opts['storage']['rbd']['rbd_secret_uuid']
    rbd_user_key = cinder_opts['storage']['rbd']['rbd_user_key']

    template "/tmp/secret.xml" do
      source "secret.xml.erb"
      variables(
        "rbd_user" =>  rbd_user,
        "rbd_secret_uuid" => rbd_secret_uuid
      )
    end

    execute "define libvirt secret" do
      command "virsh secret-define --file /tmp/secret.xml"
      not_if "virsh secret list | grep #{rbd_secret_uuid}"
    end

    execute "set libvirt secret value" do
      command "virsh secret-set-value --secret #{rbd_secret_uuid} #{rbd_user_key}"
      not_if "virsh secret-get-value #{rbd_secret_uuid} | grep #{rbd_user_key}"
    end

    file "/tmp/secret.xml" do
      action :delete
    end

  else
    Chef::Log.debug('no cinder-volume found, or rbd not being used,
    so not configuring libvirt secret for rbd')
  end
end
