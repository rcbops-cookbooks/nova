#
# Cookbook Name:: nova
# Recipe:: nova-volume-multipath-patches
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

include_recipe "osops-utils"

# lp: https://bugs.launchpad.net/nova/+bug/1178893
# detach volume fails when using multipath iscsi
template "/usr/share/pyshared/nova/virt/libvirt/volume.py" do
  source "patches/volume.py.multipath_detach_fails.3c845399da5a872ccd8412c636e8f9926a6e4c3e.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, "service[nova-compute]", :delayed
end

# lp: https://bugs.launchpad.net/nova/+bug/1180497
# FC attach code doesn't discover multipath service
template "/usr/share/pyshared/nova/storage/linuxscsi.py" do
  source "patches/linuxscsi.py.multipath_missing_device_name.4933c15575589ea5877694b6fd874c9893f54d75.erb"
  owner "root"
  group "root"
  mode "0644"
  notifies :restart, "service[nova-compute]", :immediately
end
