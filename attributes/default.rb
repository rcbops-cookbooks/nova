########################################################################
# Toggles - These can be overridden at the environment level
default["enable_monit"] = false  # OS provides packages                     # cluster_attribute
default["developer_mode"] = false  # we want secure passwords by default    # cluster_attribute
########################################################################

default["nova"]["db"]["name"] = "nova"                                      # node_attribute
default["nova"]["db"]["username"] = "nova"                                  # node_attribute

default["nova"]["service_tenant_name"] = "service"                          # node_attribute
default["nova"]["service_user"] = "nova"                                    # node_attribute
default["nova"]["service_role"] = "admin"                                   # node_attribute

default["nova"]["volumes"]["enabled"] = false                               # cluster attribute

default["nova"]["services"]["api"]["scheme"] = "http"                       # node_attribute
default["nova"]["services"]["api"]["network"] = "public"                    # node_attribute
default["nova"]["services"]["api"]["port"] = 8774                           # node_attribute
default["nova"]["services"]["api"]["path"] = "/v2/%(tenant_id)s"            # node_attribute

default["nova"]["services"]["ec2-admin"]["scheme"] = "http"                 # node_attribute
default["nova"]["services"]["ec2-admin"]["network"] = "public"              # node_attribute
default["nova"]["services"]["ec2-admin"]["port"] = 8773                     # node_attribute
default["nova"]["services"]["ec2-admin"]["path"] = "/services/Admin"        # node_attribute

default["nova"]["services"]["ec2-public"]["scheme"] = "http"                # node_attribute
default["nova"]["services"]["ec2-public"]["network"] = "public"             # node_attribute
default["nova"]["services"]["ec2-public"]["port"] = 8773                    # node_attribute
default["nova"]["services"]["ec2-public"]["path"] = "/services/Cloud"       # node_attribute

default["nova"]["services"]["xvpvnc"]["scheme"] = "http"                    # node_attribute
default["nova"]["services"]["xvpvnc"]["network"] = "nova"                   # node_attribute
default["nova"]["services"]["xvpvnc"]["port"] = 6081                        # node_attribute
default["nova"]["services"]["xvpvnc"]["path"] = "/console"                  # node_attribute

default["nova"]["services"]["novnc"]["scheme"] = "http"                     # node_attribute
default["nova"]["services"]["novnc"]["network"] = "nova"                    # node_attribute
default["nova"]["services"]["novnc"]["port"] = 6080                         # node_attribute
default["nova"]["services"]["novnc"]["path"] = "/vnc_auto.html"             # node_attribute

default["nova"]["services"]["novnc-server"]["scheme"] = "http"              # node_attribute
default["nova"]["services"]["novnc-server"]["network"] = "nova"             # node_attribute
default["nova"]["services"]["novnc-server"]["port"] = 6080                  # node_attribute
default["nova"]["services"]["novnc-server"]["path"] = "/vnc_auto.html"      # node_attribute

default["nova"]["services"]["volume"]["scheme"] = "http"                    # node_attribute
default["nova"]["services"]["volume"]["network"] = "public"                 # node_attribute
default["nova"]["services"]["volume"]["port"] = 8776                        # node_attribute
default["nova"]["services"]["volume"]["path"] = "/v1/%(tenant_id)s"         # node_attribute

# Logging stuff
default["nova"]["syslog"]["use"] = true                                     # node_attribute
default["nova"]["syslog"]["facility"] = "LOG_LOCAL1"                        # node_attribute
default["nova"]["syslog"]["config_facility"] = "local1"                     # node_attribute

# can this be wedged into the "api" endpoint?                               # node_attribute
default["nova"]["compute"]["region"] = "RegionOne"                          # node_attribute

# TODO(shep): This should probably be ['nova']['network']['fixed']
default["nova"]["networks"] = [                                             # cluster_attribute
        {
                "label" => "public",
                "ipv4_cidr" => "192.168.100.0/24",
                "num_networks" => "1",
                "network_size" => "255",
                "bridge" => "br100",
                "bridge_dev" => "eth2",
                "dns1" => "8.8.8.8",
                "dns2" => "8.8.4.4"
        },
        {
                "label" => "private",
                "ipv4_cidr" => "192.168.200.0/24",
                "num_networks" => "1",
                "network_size" => "255",
                "bridge" => "br200",
                "bridge_dev" => "eth3",
                "dns1" => "8.8.8.8",
                "dns2" => "8.8.4.4"
        }
]

default["nova"]["network"]["fixed_range"] = default["nova"]["networks"][0]["ipv4_cidr"]        # cluster_attribute
default["nova"]["network"]["dmz_cidr"] = "10.128.0.0/24"                                       # cluster_attribute
default["nova"]["network"]["network_manager"] = "nova.network.manager.FlatDHCPManager"         # cluster_attribute
default["nova"]["network"]["public_interface"] = "eth0"                                        # node_attribute
default["nova"]["network"]["dhcp_domain"] = "novalocal"                                        # cluster_attribute
default["nova"]["network"]["force_dhcp_release"] = true					       # cluster_attribute
default["nova"]["network"]["send_arp_for_ha"] = true					       # cluster_attribute
default["nova"]["network"]["auto_assign_floating_ip"] = false				       # cluster_attribute

default["nova"]["scheduler"]["scheduler_driver"] = "nova.scheduler.filter_scheduler.FilterScheduler"           # cluster_attribute
default["nova"]["scheduler"]["default_filters"] = ["AvailabilityZoneFilter",                                   # cluster_attribute
                                                   "RamFilter",
                                                   "ComputeFilter",
                                                   "CoreFilter",
                                                   "SameHostFilter",
                                                   "DifferentHostFilter"]
default["nova"]["libvirt"]["virt_type"] = "kvm"                                     # node_attribute (inherited from cluster?)
default["nova"]["libvirt"]["vncserver_listen"] = node["ipaddress"]                  # node_attribute
default["nova"]["libvirt"]["vncserver_proxyclient_address"] = node["ipaddress"]     # node_attribute
default["nova"]["libvirt"]["auth_tcp"] = "none"                                     # node_attribute (inherited from cluster?)
default["nova"]["libvirt"]["remove_unused_base_images"] = true                      # node_attribute (inherited from cluster?)
default["nova"]["libvirt"]["remove_unused_resized_minimum_age_seconds"] = 3600      # node_attribute (inherited from cluster?)
default["nova"]["libvirt"]["remove_unused_original_minimum_age_seconds"] = 3600     # node_attribute (inherited from cluster?)
default["nova"]["libvirt"]["checksum_base_images"] = false                          # node_attribute (inherited from cluster?)
default["nova"]["config"]["availability_zone"] = "nova"                             # node_attribute
default["nova"]["config"]["default_schedule_zone"] = "nova"                         # cluster_attribute
default["nova"]["config"]["force_raw_images"] = false                               # cluster_attribute
default["nova"]["config"]["allow_same_net_traffic"] = true                          # cluster_attribute
default["nova"]["config"]["osapi_max_limit"] = 1000                                 # cluster_attribute
default["nova"]["config"]["cpu_allocation_ratio"] = 16.0                            # node_attribute (inherited from cluster?)
default["nova"]["config"]["ram_allocation_ratio"] = 1.5                             # node_attribute (inherited from cluster?)
default["nova"]["config"]["snapshot_image_format"] = "qcow2"                        # cluster_attribute
default["nova"]["config"]["start_guests_on_host_boot"] = true                       # node_attribute (inherited from cluster?)
# requires https://review.openstack.org/#/c/8423/
default["nova"]["config"]["resume_guests_state_on_host_boot"] = false               # node_attribute (inherited from cluster?)

# quota settings
default["nova"]["config"]["quota_security_groups"] = 50                             # cluster_attribute
default["nova"]["config"]["quota_security_group_rules"] = 20                        # cluster_attribute

default["nova"]["ratelimit"]["settings"] = {                                        # cluster_attribute
    "generic-post-limit" => { "verb" => "POST", "uri" => "*", "regex" => ".*", "limit" => "10", "interval" => "MINUTE" },
    "create-servers-limit" => { "verb" => "POST", "uri" => "*/servers", "regex" => "^/servers", "limit" => "50", "interval" => "DAY" },
    "generic-put-limit" => { "verb" => "PUT", "uri" => "*", "regex" => ".*", "limit" => "10", "interval" => "MINUTE" },
    "changes-since-limit" => { "verb" => "GET", "uri" => "*changes-since*", "regex" => ".*changes-since.*", "limit" => "3", "interval" => "MINUTE" },
    "generic-delete-limit" => { "verb" => "DELETE", "uri" => "*", "regex" => ".*", "limit" => "100", "interval" => "MINUTE" }
}
default["nova"]["ratelimit"]["api"]["enabled"] = true                               # cluster_attribute
default["nova"]["ratelimit"]["volume"]["enabled"] = true                            # cluster_attribute

case platform
when "fedora", "redhat", "centos"
  default["nova"]["platform"] = {                                                   # node_attribute
    "api_ec2_packages" => ["openstack-nova-api"],
    "api_ec2_service" => "openstack-nova-api",
    "api_os_compute_packages" => ["openstack-nova-api"],
    "api_os_compute_service" => "openstack-nova-api",
    "api_os_compute_process_name" => "nova-api",
    "api_os_volume_packages" => ["openstack-nova-api"],
    "api_os_volume_service" => "openstack-nova-api",
    "nova_volume_packages" => ["openstack-nova-volume"],
    "nova_volume_service" => "openstack-nova-volume",
    "nova_api_metadata_packages" => ["openstack-nova-api"],
    "nova_api_metadata_process_name" => "nova-api",
    "nova_api_metadata_service" => "openstack-nova-api",
    "nova_compute_packages" => ["openstack-nova-compute", "dnsmasq-utils"],
    "nova_compute_service" => "openstack-nova-compute",
    "nova_network_packages" => ["iptables", "openstack-nova-network"],
    "nova_network_service" => "openstack-nova-network",
    "nova_scheduler_packages" => ["openstack-nova-scheduler"],
    "nova_scheduler_service" => "openstack-nova-scheduler",
    "nova_vncproxy_packages" => ["openstack-nova-novncproxy"], # me thinks this is right?
    "nova_vncproxy_service" => "openstack-nova-novncproxy",
    "nova_vncproxy_consoleauth_packages" => ["openstack-nova-console"],
    "nova_vncproxy_consoleauth_service" => "openstack-nova-consoleauth",
    "nova_vncproxy_consoleauth_process_name" => "nova-consoleauth",
    "libvirt_packages" => ["libvirt"],
    "libvirt_service" => "libvirtd",
    "nova_cert_packages" => ["openstack-nova-cert"],
    "nova_cert_service" => "openstack-nova-cert",
    "mysql_service" => "mysqld",
    "common_packages" => ["openstack-nova-common"],
    "iscsi_helper" => "tgtadm",
    "iscsi_service" => "tgtd",
    "package_overrides" => ""
  }
when "ubuntu"
  default["nova"]["platform"] = {                                                   # node_attribute
    "api_ec2_packages" => ["nova-api-ec2"],
    "api_ec2_service" => "nova-api-ec2",
    "api_os_compute_packages" => ["nova-api-os-compute"],
    "api_os_compute_process_name" => "nova-api-os-compute",
    "api_os_compute_service" => "nova-api-os-compute",
    "api_os_volume_packages" => ["nova-api-os-volume"],
    "api_os_volume_service" => "nova-api-os-volume",
    "nova_api_metadata_packages" => ["nova-api-metadata"],
    "nova_api_metadata_service" => "nova-api-metadata",
    "nova_api_metadata_process_name" => "nova-api-metadata",
    "nova_volume_packages" => ["nova-volume", "tgt"],
    "nova_volume_service" => "nova-volume",
    "nova_compute_packages" => ["nova-compute"],
    "nova_compute_service" => "nova-compute",
    "nova_network_packages" => ["iptables", "nova-network"],
    "nova_network_service" => "nova-network",
    "nova_scheduler_packages" => ["nova-scheduler"],
    "nova_scheduler_service" => "nova-scheduler",
    "nova_vncproxy_packages" => ["novnc"],
    "nova_vncproxy_service" => "novnc",
    "nova_vncproxy_consoleauth_packages" => ["nova-consoleauth"],
    "nova_vncproxy_consoleauth_service" => "nova-consoleauth",
    "nova_vncproxy_consoleauth_process_name" => "nova-consoleauth",
    "libvirt_packages" => ["libvirt-bin"],
    "libvirt_service" => "libvirt-bin",
    "nova_cert_packages" => ["nova-cert"],
    "nova_cert_service" => "nova-cert",
    "mysql_service" => "mysql",
    "common_packages" => ["nova-common"],
    "iscsi_helper" => "tgtadm",
    "iscsi_service" => "tgt",
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end
