action :create do
   log "Creating the nova.conf #{new_resource.version}"
   mysql_info = get_access_endpoint("mysql-master", "mysql", "db")
   rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
   nova_setup_info = get_settings_by_role("nova-setup", "nova")
   keystone = get_settings_by_role("keystone", "keystone")
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

   net_provider = node["nova"]["network"]["provider"]
   if net_provider == "quantum"
       quantum_info = get_settings_by_recipe("nova-network\\:\\:nova-controller", "quantum")
       quantum_endpoint = get_access_endpoint("nova-network-controller", "quantum", "api")
       nova_info = get_access_endpoint("nova-api-os-compute", "nova", "api")
       metadata_ip = nova_info["host"]
   end

   platform_options = node["nova"]["platform"][new_resource.version]

   # Case nova or quantum
   # network_options assemble hash here
   network_options = {}
   case net_provider
   when "nova"
	   network_options["network_manager"] = node[net_provider]["network"]["network_manager"]
	   network_options["multi_host"] = node[net_provider]["network"]["multi_host"]
	   network_options["public_interface"] = node[net_provider]["network"]["public_interface"]
	   network_options["fixed_range"] = node[net_provider]["networks"][0]["ipv4_cidr"]
	   network_options["dmz_cidr"] = node[net_provider]["network"]["dmz_cidr"]
	   network_options["force_dhcp_release"] = node[net_provider]["network"]["force_dhcp_release"]
	   network_options["send_arp_for_ha"] = node[net_provider]["network"]["send_arp_for_ha"]
	   network_options["auto_assign_floating_ip"] = node[net_provider]["network"]["auto_assign_floating_ip"]
	   network_options["dhcp_domain"] = node[net_provider]["network"]["dhcp_domain"]
	   network_options["dhcpbridge_flagfile"] = "/etc/nova/nova.conf"
	   network_options["dhcpbridge"] = "/usr/bin/nova-dhcpbridge"
	   #network_options["use_single_default_gateway"] = node[net_provider]["config"]["use_single_default_gateway"]
	   #network_options["virt_type"] = node[net_provider]["libvirt"]["virt_type"]
   when "quantum"
	   network_options["quantum_url"] = quantum_endpoint["uri"]
	   network_options["quantum_admin_tenant_name"] = quantum_info["service_tenant_name"]
           network_options["quantum_admin_username"] = quantum_info["service_user"]
	   network_options["quantum_admin_password"] = quantum_info["service_pass"]
	   network_options["quantum_admin_auth_url"] = ks_admin_endpoint["uri"]
	   network_options["network_api_class"] = node[net_provider]["network_api_class"]
	   network_options["quantum_auth_strategy"] = node[net_provider]["auth_strategy"]
	   network_options["libvirt_vif_driver"] = node[net_provider]["libvirt_vif_driver"]
	   network_options["linuxnet_interface_driver"] = node[net_provider]["linuxnet_interface_driver"]
	   network_options["firewall_driver"] = node[net_provider]["firewall_driver"]
	   network_options["metadata_host"] = metadata_ip
   end

   t = template "/etc/nova/nova.conf" do
	   source "#{new_resource.version}/nova.conf.erb"
	   owner "nova"
	   group "nova"
	   mode "0600"
	   cookbook "nova"
	   variables(
		"use_syslog" => node["nova"]["syslog"]["use"],
		"log_facility" => node["nova"]["syslog"]["facility"],
		"db_ipaddress" => mysql_info["host"],
		"user" => node["nova"]["db"]["username"],
		"passwd" => nova_setup_info["db"]["password"],
		"db_name" => node["nova"]["db"]["name"],
		"vncserver_listen" => "0.0.0.0",
		"vncserver_proxyclient_address" => novnc_proxy_endpoint["host"],
		"novncproxy_base_url" => novnc_endpoint["uri"],
		"xvpvncproxy_bind_host" => xvpvnc_endpoint["host"],
		"xvpvncproxy_bind_port" => xvpvnc_endpoint["port"],
		"xvpvncproxy_base_url" => xvpvnc_endpoint["uri"],
		"rabbit_ipaddress" => rabbit_info["host"],
		"rabbit_port" => rabbit_info["port"],
		"keystone_api_ipaddress" => ks_admin_endpoint["host"],
		"keystone_service_port" => ks_service_endpoint["port"],
		"glance_serverlist" => glance_serverlist,
		"iscsi_helper" => platform_options["iscsi_helper"],
		"scheduler_driver" => node["nova"]["scheduler"]["scheduler_driver"],
		"scheduler_default_filters" => platform_options["nova_scheduler_default_filters"].join(","),
		"scheduler_least_cost_functions" => node["nova"]["scheduler"]["least_cost_functions"],
		"availability_zone" => node["nova"]["config"]["availability_zone"],
		"default_schedule_zone" => node["nova"]["config"]["default_schedule_zone"],
		"virt_type" => node["nova"]["libvirt"]["virt_type"],
		"remove_unused_base_images" => node["nova"]["libvirt"]["remove_unused_base_images"],
		"remove_unused_resized_minimum_age_seconds" => node["nova"]["libvirt"]["remove_unused_resized_minimum_age_seconds"],
		"remove_unused_original_minimum_age_seconds" => node["nova"]["libvirt"]["remove_unused_original_minimum_age_seconds"],
		"checksum_base_images" => node["nova"]["libvirt"]["checksum_base_images"],
		"libvirt_inject_key" => node["nova"]["libvirt"]["libvirt_inject_key"],
		"force_raw_images" => node["nova"]["config"]["force_raw_images"],
		"allow_same_net_traffic" => node["nova"]["config"]["allow_same_net_traffic"],
		"osapi_max_limit" => node["nova"]["config"]["osapi_max_limit"],
		"cpu_allocation_ratio" => node["nova"]["config"]["cpu_allocation_ratio"],
		"ram_allocation_ratio" => node["nova"]["config"]["ram_allocation_ratio"],
		"snapshot_image_format" => node["nova"]["config"]["snapshot_image_format"],
		"start_guests_on_host_boot" => node["nova"]["config"]["start_guests_on_host_boot"],
		"resume_guests_state_on_host_boot" => node["nova"]["config"]["resume_guests_state_on_host_boot"],
		"quota_security_groups" => node["nova"]["config"]["quota_security_groups"],
		"quota_security_group_rules" => node["nova"]["config"]["quota_security_group_rules"],
		"use_single_default_gateway" => node["nova"]["config"]["use_single_default_gateway"],
		"network_options" => network_options,
		"scheduler_max_attempts" => node["nova"]["config"]["scheduler_max_attempts"],
      	        "vpn_image_id" => node["nova"]["config"]["vpn_image_id"]
	)
   end
   new_resource.updated_by_last_action(t.updated_by_last_action?)
end
