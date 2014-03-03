use_inline_resources if Gem::Version.new(Chef::VERSION) >= Gem::Version.new('11')

action :create do
  # Don't log during converge phase in LWP because it unconditionally marks the
  # LWR as "updated," which subsequently restarts subscribed services (even if
  # the template contents haven't changed).
  Chef::Log.info("Creating #{new_resource.name}")

  # Search for mysql endpoint info
  mysql_info = get_mysql_endpoint

  # Search for rabbit endpoint info
  rabbit_info = get_access_endpoint("rabbitmq-server", "rabbitmq", "queue")
  rabbit_settings = get_settings_by_role("rabbitmq-server", "rabbitmq")

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

  # Get the socket bind information for nova-api-metadata
  metadata_api_bind = get_bind_endpoint("nova", "api-metadata")

  # Get endpoint info for nova-api-ec2
  ec2_bind = get_bind_endpoint("nova", "ec2-public")

  # Search for xvpvnc endpoint info
  vnc_role = "nova-vncproxy"
  xvpvncproxy_endpoint = get_access_endpoint(vnc_role, "nova", "xvpvnc-proxy")
  novncproxy_endpoint = get_access_endpoint(vnc_role, "nova", "novnc-proxy")

  # Check novnc-proxy ssl config
  if node["nova"]["services"]["novnc-proxy"]["scheme"] == "https"
    novnc_proxy_cert = "#{node["nova"]["ssl"]["dir"]}/certs/#{node["nova"]["services"]["novnc-proxy"]["cert_file"]}"
    novnc_proxy_key  = "#{node["nova"]["ssl"]["dir"]}/private/#{node["nova"]["services"]["novnc-proxy"]["key_file"]}"
  else
    novnc_proxy_cert = "donotset"
    novnc_proxy_key  = "donotset"
  end

  # Get bind info for vnc
  xvpvncproxy_bind = get_bind_endpoint("nova", "xvpvnc-proxy")
  novncserver_bind = get_bind_endpoint("nova", "novnc-server")
  novncproxy_bind = get_bind_endpoint("nova", "novnc-proxy")

  memcached_endpoints = get_realserver_endpoints("memcached", "memcached", "cache")

  Chef::Log.info("#### #{memcached_endpoints}")

  if memcached_endpoints.empty?
    memcached_servers = nil
  else
    # sort array of hash objects by 'host' key and join into string
    memcached_servers =
      memcached_endpoints.sort {|a,b| a['host'] <=> b['host']}.collect do |ep|
      "#{ep["host"]}:#{ep["port"]}"
    end.join(",")
  end

  net_provider = node["nova"]["network"]["provider"]
  if net_provider == "neutron"
    # Get settings from recipe[nova-network::nova-controller]
    recipe = "nova-network::nova-controller"
    neutron_info = get_settings_by_recipe(recipe, "neutron")

    # Search for neutron enpoint info
    nova_net_role = "nova-network-controller"
    neutron_endpoint = get_access_endpoint(nova_net_role, "neutron", "api")

    # Search for nova api endpoint info
    nova_info = get_access_endpoint("nova-api-os-compute", "nova", "api")
    metadata_ip = nova_info["host"]
  end

  platform_options = node["nova"]["platform"]

  # Case nova or neutron
  # network_options assemble hash here
  network_options = {}
  case net_provider
  when "nova"
    network_options["network_manager"] = node[net_provider]["network"]["network_manager"]
    network_options["multi_host"] = node[net_provider]["network"]["multi_host"]
    network_options["public_interface"] = node[net_provider]["network"]["public_interface"]
    network_options["fixed_range"] = node[net_provider]["networks"]["public"]["ipv4_cidr"]
    network_options["dmz_cidr"] = node[net_provider]["network"]["dmz_cidr"]
    network_options["force_dhcp_release"] = node[net_provider]["network"]["force_dhcp_release"]
    network_options["send_arp_for_ha"] = node[net_provider]["network"]["send_arp_for_ha"]
    network_options["auto_assign_floating_ip"] = node[net_provider]["network"]["auto_assign_floating_ip"]
    network_options["dhcp_domain"] = node[net_provider]["network"]["dhcp_domain"]
    network_options["dhcpbridge_flagfile"] = "/etc/nova/nova.conf"
    network_options["dhcpbridge"] = "/usr/bin/nova-dhcpbridge"
    network_options["dhcp_lease_time"] = node[net_provider]["network"]["dhcp_lease_time"]
    network_options["fixed_ip_disassociate_timeout"] = node[net_provider]["network"]["fixed_ip_disassociate_timeout"]
    #network_options["use_single_default_gateway"] = node[net_provider]["config"]["use_single_default_gateway"]
    #network_options["virt_type"] = node[net_provider]["libvirt"]["virt_type"]
  when "neutron"
    network_options["neutron_url"] = neutron_endpoint["uri"]
    network_options["neutron_admin_tenant_name"] = neutron_info["service_tenant_name"]
    network_options["neutron_admin_username"] = neutron_info["service_user"]
    network_options["neutron_admin_password"] = neutron_info["service_pass"]
    network_options["neutron_admin_auth_url"] = ks_admin_endpoint["uri"]
    network_options["network_api_class"] = node[net_provider]["network_api_class"]
    network_options["neutron_auth_strategy"] = node[net_provider]["auth_strategy"]
    network_options["libvirt_vif_driver"] = node[net_provider]["libvirt_vif_driver"]
    network_options["libvirt_vif_type"] = node[net_provider]["libvirt_vif_type"]
    network_options["linuxnet_interface_driver"] = node[net_provider]["linuxnet_interface_driver"]
    network_options["firewall_driver"] = node[net_provider]["firewall_driver"]
    network_options["security_group_api"] = node[net_provider]["security_group_api"]
    network_options["service_neutron_metadata_proxy"] = node[net_provider]["service_neutron_metadata_proxy"]
    network_options["neutron_metadata_proxy_shared_secret"] = neutron_info["neutron_metadata_proxy_shared_secret"]
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

  cinder_setup_info = get_settings_by_role("cinder-setup", "cinder")
  iscsi_use_multipath = false
  if not cinder_setup_info.nil? and
    cinder_setup_info["storage"]["provider"] == "emc" and
    cinder_setup_info["storage"]["enable_multipath"] == true
    iscsi_use_multipath = true
  end

  notification_provider = node["nova"]["notification"]["driver"]
  case notification_provider
  when "no_op"
    notification_driver = "nova.openstack.common.notifier.no_op_notifier"
  when "rpc"
    notification_driver = "nova.openstack.common.notifier.rpc_notifier"
  when "log"
    notification_driver = "nova.openstack.common.notifier.log_notifier"
  else
    msg = "#{notification_provider}, is not currently supported by these cookbooks."
    Chef::Application.fatal! msg
  end

  t = template new_resource.name do
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
      "vncserver_listen" => node["nova"]["libvirt"]["vncserver_listen"] || novncserver_bind["host"],
      "vncserver_proxyclient_address" => novncserver_bind["host"],
      "novnc_proxy_cert" => novnc_proxy_cert,
      "novnc_proxy_key" => novnc_proxy_key,
      "novncproxy_base_url" => novncproxy_endpoint["uri"],
      "xvpvncproxy_bind_host" => xvpvncproxy_bind["host"],
      "xvpvncproxy_bind_port" => xvpvncproxy_bind["port"],
      "novncproxy_bind_host" => novncproxy_bind["host"],
      "novncproxy_bind_port" => novncproxy_bind["port"],
      "xvpvncproxy_base_url" => xvpvncproxy_endpoint["uri"],
      "rabbit_ipaddress" => rabbit_info["host"],
      "rabbit_port" => rabbit_info["port"],
      "rabbit_ha_queues" => rabbit_settings["cluster"] ? "True" : "False",
      "notification_driver" => notification_driver,
      "notification_topics" => node["nova"]["notification"]["topics"],
      "keystone_api_ipaddress" => ks_admin_endpoint["host"],
      "keystone_service_port" => ks_service_endpoint["port"],
      "keystone_service_protocol" => ks_service_endpoint["scheme"],
      "glance_serverlist" => "#{glance_endpoint["host"]}:#{glance_endpoint["port"]}",
      "iscsi_helper" => platform_options["iscsi_helper"],
      "scheduler_driver" => node["nova"]["scheduler"]["scheduler_driver"],
      "scheduler_default_filters" => node["nova"]["scheduler"]["default_filters"].join(","),
      "scheduler_weight_classes" => node["nova"]["scheduler"]["scheduler_weight_classes"],
      "scheduler_ram_weight_multiplier" => node["nova"]["scheduler"]["ram_weight_multiplier"],
      "scheduler_host_subset_size" => node["nova"]["scheduler"]["scheduler_host_subset_size"],
      "availability_zone" => node["nova"]["config"]["availability_zone"],
      "default_schedule_zone" => node["nova"]["config"]["default_schedule_zone"],
      "connection_type" => node["nova"]["compute"]["connection_type"],
      "virt_type" => node["nova"]["libvirt"]["virt_type"],
      "disk_cachemodes" => node["nova"]["libvirt"]["disk_cachemodes"],
      "remove_unused_base_images" => node["nova"]["libvirt"]["remove_unused_base_images"],
      "remove_unused_resized_minimum_age_seconds" => node["nova"]["libvirt"]["remove_unused_resized_minimum_age_seconds"],
      "remove_unused_original_minimum_age_seconds" => node["nova"]["libvirt"]["remove_unused_original_minimum_age_seconds"],
      "checksum_base_images" => node["nova"]["libvirt"]["checksum_base_images"],
      "libvirt_inject_key" => node["nova"]["libvirt"]["libvirt_inject_key"],
      "libvirt_inject_password" => node["nova"]["libvirt"]["libvirt_inject_password"],
      "libvirt_inject_partition" => node["nova"]["libvirt"]["libvirt_inject_partition"],
      "block_migration_flag" => node["nova"]["libvirt"]["block_migration_flag"],
      "libvirt_cpu_mode" => node["nova"]["libvirt"]["libvirt_cpu_mode"],
      "libvirt_cpu_model" => node["nova"]["libvirt"]["libvirt_cpu_model"],
      "force_raw_images" => node["nova"]["config"]["force_raw_images"],
      "allow_same_net_traffic" => node["nova"]["config"]["allow_same_net_traffic"],
      "quota_instances" => node["nova"]["config"]["quota_instances"],
      "quota_fixed_ips" => node["nova"]["config"]["quota_fixed_ips"],
      "dnsmasq_config_file" => node["nova"]["config"]["dnsmasq_config_file"],
      "osapi_max_limit" => node["nova"]["config"]["osapi_max_limit"],
      "cpu_allocation_ratio" => node["nova"]["config"]["cpu_allocation_ratio"],
      "ram_allocation_ratio" => node["nova"]["config"]["ram_allocation_ratio"],
      "disk_allocation_ratio" => node["nova"]["config"]["disk_allocation_ratio"],
      "snapshot_image_format" => node["nova"]["config"]["snapshot_image_format"],
      "start_guests_on_host_boot" => node["nova"]["config"]["start_guests_on_host_boot"],
      "resume_guests_state_on_host_boot" => node["nova"]["config"]["resume_guests_state_on_host_boot"],
      "quota_security_groups" => node["nova"]["config"]["quota_security_groups"],
      "quota_security_group_rules" => node["nova"]["config"]["quota_security_group_rules"],
      "use_single_default_gateway" => node["nova"]["config"]["use_single_default_gateway"],
      "network_options" => network_options,
      "scheduler_max_attempts" => node["nova"]["config"]["scheduler_max_attempts"],
      "vpn_image_id" => node["nova"]["config"]["vpn_image_id"],
      "force_config_drive" => node["nova"]["config"]["force_config_drive"],
      "config_drive_format" => node["nova"]["config"]["config_drive_format"],
      "cinder_catalog_info" => node["nova"]["services"]["volume"]["cinder_catalog_info"],
      "metadata_listen" => metadata_api_bind["host"],
      "metadata_listen_port" => metadata_api_bind["port"],
      "osapi_compute_listen" => api_bind["host"],
      "osapi_compute_listen_port" => api_bind["port"],
      "ec2_listen" => ec2_bind["host"],
      "ec2_host" => ec2_bind["host"],
      "ec2_listen_port" => ec2_bind["port"],
      "use_ceilometer" => node.recipe?("ceilometer::ceilometer-compute"),
      "iscsi_use_multipath" => iscsi_use_multipath,
      "memcached_servers" => memcached_servers,
      "image_cache_manager_interval" => node["nova"]["config"]["image_cache_manager_interval"],
      "max_age" => node["nova"]["config"]["max_age"],
      "reserved_host_disk_mb" => node["nova"]["config"]["reserved_host_disk_mb"],
      "sql_connection_debug" => node["nova"]["config"]["sql_connection_debug"],
      "sql_idle_timeout" => node["nova"]["config"]["sql_idle_timeout"],
      "sql_retry_interval" => node["nova"]["config"]["sql_retry_interval"],
      "sql_max_retries" => node["nova"]["config"]["sql_max_retries"],
      "sql_min_pool_size" => node["nova"]["config"]["sql_min_pool_size"],
      "sql_max_pool_size" => node["nova"]["config"]["sql_max_pool_size"] || nil,
      "sql_max_overflow" => node["nova"]["config"]["sql_max_overflow"] || nil
    )
  end
  new_resource.updated_by_last_action(t.updated_by_last_action?)
end
