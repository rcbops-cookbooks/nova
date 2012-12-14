#
# Cookbook Name:: nova
# Recipe:: nova-common
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

include_recipe "nova::nova-rsyslog"
include_recipe "osops-utils::autoetchosts"

if not node['package_component'].nil?
  release = node['package_component']
else
  release = "essex-final"
end

platform_options = node["nova"]["platform"][release]

platform_options["common_packages"].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options["package_overrides"]
  end
end

directory "/etc/nova" do
  action :create
  owner "nova"
  group "nova"
  mode "0755"
end

# Public interface needs to be the bridge if the public interface is in the bridge
# if node["nova"]["networks"][0]["bridge_dev"] == node["nova"]["network"]["public_interface"]
  # node.set["nova"]["network"]["public_interface"] = node["nova"]["networks"][0]["bridge"]
# end

mysql_info = get_access_endpoint("mysql-master", "mysql", "db")
rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")

# nova::nova-setup does not need to be double escaped here
nova_setup_info = get_settings_by_role("nova-setup", "nova")
keystone = get_settings_by_role("keystone", "keystone")

# find the node attribute endpoint settings for the server holding a given role
ks_admin_endpoint = get_access_endpoint("keystone", "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint("keystone", "keystone", "service-api")
xvpvnc_endpoint = get_access_endpoint("nova-vncproxy", "nova", "xvpvnc")
novnc_endpoint = get_access_endpoint("nova-vncproxy", "nova", "novnc-server")
novnc_proxy_endpoint = get_bind_endpoint("nova", "novnc")

# NOTE:(mancdaz) we need to account for potentially many glance-api servers here, until
# https://bugs.launchpad.net/nova/+bug/1084138 is fixed
glance_endpoints = get_realserver_endpoints("glance-api", "glance", "api")
glance_servers = glance_endpoints.each.inject([]) {|output, k| output << [k['host'],k['port']].join(":") }
glance_serverlist = glance_servers.join(",")

nova_api_endpoint = get_access_endpoint("nova-api-os-compute", "nova", "api")
ec2_public_endpoint = get_access_endpoint("nova-api-ec2", "nova", "ec2-public")

if not node['package_component'].nil?
  release = node['package_component']
else
  release = "essex-final"
end

nova_conf "Create nova.conf" do
	release "#{release}"
        action :create
end

# TODO: need to re-evaluate this for accuracy
# template "/etc/nova/nova.conf" do
  # source "#{release}/nova.conf.erb"
  # owner "root"
  # group "root"
  # mode "0644"
  # variables(
    # "use_syslog" => node["nova"]["syslog"]["use"],
    # "log_facility" => node["nova"]["syslog"]["facility"],
    # "db_ipaddress" => mysql_info["host"],
    # "user" => node["nova"]["db"]["username"],
    # "passwd" => nova_setup_info["db"]["password"],
    # "db_name" => node["nova"]["db"]["name"],
    # "vncserver_listen" => "0.0.0.0",
    # "vncserver_proxyclient_address" => novnc_proxy_endpoint["host"],
    # "novncproxy_base_url" => novnc_endpoint["uri"],
    # "xvpvncproxy_bind_host" => xvpvnc_endpoint["host"],
    # "xvpvncproxy_bind_port" => xvpvnc_endpoint["port"],
    # "xvpvncproxy_base_url" => xvpvnc_endpoint["uri"],
    # "rabbit_ipaddress" => rabbit_info["host"],
    # "rabbit_port" => rabbit_info["port"],
    # "keystone_api_ipaddress" => ks_admin_endpoint["host"],
    # "keystone_service_port" => ks_service_endpoint["port"],
    # "glance_serverlist" => glance_serverlist,
    # "iscsi_helper" => platform_options["iscsi_helper"],
    # "fixed_range" => node["nova"]["networks"][0]["ipv4_cidr"],
    # "public_interface" => node["nova"]["network"]["public_interface"],
    # "network_manager" => node["nova"]["network"]["network_manager"],
    # "multi_host" => node["nova"]["network"]["multi_host"],
    # "scheduler_driver" => node["nova"]["scheduler"]["scheduler_driver"],
    # "scheduler_default_filters" => platform_options["nova_scheduler_default_filters"].join(","),
    # "scheduler_least_cost_functions" => node["nova"]["scheduler"]["least_cost_functions"],
    # "availability_zone" => node["nova"]["config"]["availability_zone"],
    # "default_schedule_zone" => node["nova"]["config"]["default_schedule_zone"],
    # "virt_type" => node["nova"]["libvirt"]["virt_type"],
    # "remove_unused_base_images" => node["nova"]["libvirt"]["remove_unused_base_images"],
    # "remove_unused_resized_minimum_age_seconds" => node["nova"]["libvirt"]["remove_unused_resized_minimum_age_seconds"],
    # "remove_unused_original_minimum_age_seconds" => node["nova"]["libvirt"]["remove_unused_original_minimum_age_seconds"],
    # "checksum_base_images" => node["nova"]["libvirt"]["checksum_base_images"],
    # "libvirt_inject_key" => node["nova"]["libvirt"]["libvirt_inject_key"],
    # "force_dhcp_release" => node["nova"]["network"]["force_dhcp_release"],
    # "send_arp_for_ha" => node["nova"]["network"]["send_arp_for_ha"],
    # "auto_assign_floating_ip" => node["nova"]["network"]["auto_assign_floating_ip"],
    # "force_raw_images" => node["nova"]["config"]["force_raw_images"],
    # "dmz_cidr" => node["nova"]["network"]["dmz_cidr"],
    # "allow_same_net_traffic" => node["nova"]["config"]["allow_same_net_traffic"],
    # "osapi_max_limit" => node["nova"]["config"]["osapi_max_limit"],
    # "cpu_allocation_ratio" => node["nova"]["config"]["cpu_allocation_ratio"],
    # "ram_allocation_ratio" => node["nova"]["config"]["ram_allocation_ratio"],
    # "snapshot_image_format" => node["nova"]["config"]["snapshot_image_format"],
    # "start_guests_on_host_boot" => node["nova"]["config"]["start_guests_on_host_boot"],
    # "resume_guests_state_on_host_boot" => node["nova"]["config"]["resume_guests_state_on_host_boot"],
    # "quota_security_groups" => node["nova"]["config"]["quota_security_groups"],
    # "quota_security_group_rules" => node["nova"]["config"]["quota_security_group_rules"],
    # "dhcp_domain" => node["nova"]["network"]["dhcp_domain"],
    # "use_single_default_gateway" => node["nova"]["config"]["use_single_default_gateway"],
    # "scheduler_max_attempts" => node["nova"]["config"]["scheduler_max_attempts"]
  # )
# end

# TODO: need to re-evaluate this for accuracy
template "/root/openrc" do
  source "openrc.erb"
  owner "root"
  group "root"
  mode "0600"
  variables(
    "user" => keystone["admin_user"],
    "tenant" => keystone["users"][keystone["admin_user"]]["default_tenant"],
    "password" => keystone["users"][keystone["admin_user"]]["password"],
    "keystone_api_ipaddress" => ks_service_endpoint["host"],
    "keystone_service_port" => ks_service_endpoint["port"],
    "nova_api_ipaddress" => nova_api_endpoint["host"],
    "nova_api_version" => "1.1",
    "keystone_region" => node["nova"]["compute"]["region"],
    "auth_strategy" => "keystone",
    "ec2_url" => ec2_public_endpoint["uri"],
    "ec2_access_key" => node["credentials"]["EC2"]["admin"]["access"],
    "ec2_secret_key" => node["credentials"]["EC2"]["admin"]["secret"]
  )
end

# NOTE(shep): this is for backwards compatability with Alamo
link "/root/.novarc" do
  to "/root/openrc"
  link_type :symbolic
  only_if { File.exists? "/root/openrc" }
end

execute "enable nova login" do
  command "usermod -s /bin/sh nova"
end

dsh_group "nova" do
  user "nova"
  admin_user "nova"
  group "nova"
end
