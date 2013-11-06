#
# Cookbook Name:: nova
# Recipe:: nova-osapi-patch
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

nova_api_endpoint = get_bind_endpoint("nova", "api")

# lp:bug https://bugs.launchpad.net/ubuntu/+bug/1235220
# incorrect headers delivered by nova osapi
template "/usr/lib/python2.7/dist-packages/nova/api/openstack/compute/servers.py" do
  source "patches/servers.py.2013.1.3-0ubuntu1~cloud0.erb"
  owner "root"
  group "root"
  mode "0644"
  unless nova_api_endpoint["scheme"] == "https"
    notifies :restart, "service[nova-api-os-compute]", :delayed
  else
    notifies :restart, "service[apache2]", :delayed
  end
  only_if {
    ::Chef::Recipe::Patch.check_package_version(
      "python-nova",
      "1:2013.1.3-0ubuntu1~cloud0",
      node
    )
  }
end
