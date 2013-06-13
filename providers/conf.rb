action :create do
  log "Creating the nova.conf"

  # Search for mysql endpoint info
  mysql_info = get_access_endpoint("mysql-master", "mysql", "db")
  # Search for rabbit endpoint info
  rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
  # Get settings from role[nova-setup]
  nova_setup_info = get_settings_by_role("nova-setup", "nova")
  # Search for keystone endpoint info
  ks_api_role = "keystone-api"
  ks_ns = "keystone"
  ks_admin_endpoint = get_access_endpoint(ks_api_role, ks_ns, "admin-api")
  ks_service_endpoint = get_access_endpoint(ks_api_role, ks_ns, "service-api")
  # Search for glance endpoint info
  glance_endpoint = get_access_endpoint("glance-api", "glance", "api")
  # Get endpoint info for nova-api
  api_bind = get_bind_endpoint("nova", "api")
  # Get endpoint info for nova-api-ec2
  ec2_bind = get_bind_endpoint("nova", "ec2-public")
  # Search for xvpvnc endpoint info
  vnc_role = "nova-vncproxy"
  xvpvncproxy_endpoint = get_access_endpoint(vnc_role, "nova", "xvpvnc-proxy")
  novncproxy_endpoint = get_access_endpoint(vnc_role, "nova", "novnc-proxy")
  # Get bind info for vnc
  xvpvncproxy_bind = get_bind_endpoint("nova", "xvpvnc-proxy")
  novncserver_bind = get_bind_endpoint("nova", "novnc-server")
  novncproxy_bind = get_bind_endpoint("nova", "novnc-proxy")

  net_provider = node["nova"]["network"]["provider"]
  if net_provider == "quantum"
    # Get settings from recipe[nova-network::nova-controller]
    recipe = "nova-network\\:\\:nova-controller"
    quantum_info = get_settings_by_recipe(recipe, "quantum")
    # Search for quantum enpoint info
    nova_net_role = "nova-network-controller"
    quantum_endpoint = get_access_endpoint(nova_net_role, "quantum", "api")
    # Search for nova api endpoint info
    nova_info = get_access_endpoint("nova-api-os-compute", "nova", "api")
    metadata_ip = nova_info["host"]
  end

  platform_options = node["nova"]["platform"]

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
    network_options["libvirt_vif_type"] = node[net_provider]["libvirt_vif_type"]
    network_options["linuxnet_interface_driver"] = node[net_provider]["linuxnet_interface_driver"]
    network_options["firewall_driver"] = node[net_provider]["firewall_driver"]
    network_options["security_group_api"] = node[net_provider]["security_group_api"]
    network_options["service_quantum_metadata_proxy"] = node[net_provider]["service_quantum_metadata_proxy"]
    network_options["quantum_metadata_proxy_shared_secret"] = quantum_info["quantum_metadata_proxy_shared_secret"]
    network_options["metadata_host"] = metadata_ip
  end

  template node["nova"]["config"]["dnsmasq_config_file"] do
    source "dnsmasq-nova.conf.erb"
    owner "root"
    group "root"
    mode "0644"
    cookbook "nova"
    variables(
      "hardware_gateway" => node["nova"]["config"]["hardware_gateway"],
      "dns_servers" => node["nova"]["config"]["dns_servers"]
    )
  end

  t = template "/etc/nova/nova.conf" do
    source "nova.conf.erb"
    owner "nova"
    group "nova"
    mode "0600"
    cookbook "nova"
    variables(
      "debug" => node["nova"]["debug"],
      "db_ipaddress" => mysql_info["host"],
      "user" => node["nova"]["db"]["username"],
      "passwd" => nova_setup_info["db"]["password"],
      "db_name" => node["nova"]["db"]["name"],
      "vncserver_listen" => novncserver_bind["host"],
      "vncserver_proxyclient_address" => novncserver_bind["host"],
      "novncproxy_base_url" => novncproxy_endpoint["uri"],
      "xvpvncproxy_bind_host" => xvpvncproxy_bind["host"],
      "xvpvncproxy_bind_port" => xvpvncproxy_bind["port"],
      "novncproxy_bind_host" => novncproxy_bind["host"],
      "novncproxy_bind_port" => novncproxy_bind["port"],
      "xvpvncproxy_base_url" => xvpvncproxy_endpoint["uri"],
      "rabbit_ipaddress" => rabbit_info["host"],
      "rabbit_port" => rabbit_info["port"],
      "keystone_api_ipaddress" => ks_admin_endpoint["host"],
      "keystone_service_port" => ks_service_endpoint["port"],
      "glance_serverlist" => "#{glance_endpoint["host"]}:#{glance_endpoint["port"]}",
      "iscsi_helper" => platform_options["iscsi_helper"],
      "scheduler_driver" => node["nova"]["scheduler"]["scheduler_driver"],
      "scheduler_default_filters" => platform_options["nova_scheduler_default_filters"].join(","),
      "scheduler_least_cost_functions" => node["nova"]["scheduler"]["least_cost_functions"],
      "availability_zone" => node["nova"]["config"]["availability_zone"],
      "default_schedule_zone" => node["nova"]["config"]["default_schedule_zone"],
      "connection_type" => node["nova"]["compute"]["connection_type"],
      "virt_type" => node["nova"]["libvirt"]["virt_type"],
      "remove_unused_base_images" => node["nova"]["libvirt"]["remove_unused_base_images"],
      "remove_unused_resized_minimum_age_seconds" => node["nova"]["libvirt"]["remove_unused_resized_minimum_age_seconds"],
      "remove_unused_original_minimum_age_seconds" => node["nova"]["libvirt"]["remove_unused_original_minimum_age_seconds"],
      "checksum_base_images" => node["nova"]["libvirt"]["checksum_base_images"],
      "libvirt_inject_key" => node["nova"]["libvirt"]["libvirt_inject_key"],
      "force_raw_images" => node["nova"]["config"]["force_raw_images"],
      "allow_same_net_traffic" => node["nova"]["config"]["allow_same_net_traffic"],
      "quota_instances" => node["nova"]["config"]["quota_instances"],
      "quota_fixed_ips" => node["nova"]["config"]["quota_fixed_ips"],
      "dnsmasq_config_file" => node["nova"]["config"]["dnsmasq_config_file"],
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
      "vpn_image_id" => node["nova"]["config"]["vpn_image_id"],
      "cinder_catalog_info" => node["nova"]["services"]["volume"]["cinder_catalog_info"],
      "osapi_compute_listen" => api_bind["host"],
      "osapi_compute_listen_port" => api_bind["port"],
      "ec2_listen" => ec2_bind["host"],
      "ec2_host" => ec2_bind["host"],
      "ec2_listen_port" => ec2_bind["port"],
      "use_ceilometer" => node.recipe?("ceilometer::ceilometer-compute")
    )
  end
  new_resource.updated_by_last_action(t.updated_by_last_action?)
end
