########################################################################
# Toggles - These can be overridden at the environment level
default["enable_monit"] = false  # OS provides packages                     # cluster_attribute
default["developer_mode"] = false  # we want secure passwords by default    # cluster_attribute
########################################################################

# set to true to enable debugging output in the logs
default["nova"]["debug"] = false

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

default["nova"]["services"]["xvpvnc-proxy"]["scheme"] = "http"                    # node_attribute
default["nova"]["services"]["xvpvnc-proxy"]["network"] = "nova"                   # node_attribute
default["nova"]["services"]["xvpvnc-proxy"]["port"] = 6081                        # node_attribute
default["nova"]["services"]["xvpvnc-proxy"]["path"] = "/console"                  # node_attribute

default["nova"]["services"]["novnc-proxy"]["scheme"] = "http"                     # node_attribute
default["nova"]["services"]["novnc-proxy"]["network"] = "nova"                    # node_attribute
default["nova"]["services"]["novnc-proxy"]["port"] = 6080                         # node_attribute
default["nova"]["services"]["novnc-proxy"]["path"] = "/vnc_auto.html"             # node_attribute

default["nova"]["services"]["novnc-server"]["scheme"] = "http"              # node_attribute
default["nova"]["services"]["novnc-server"]["network"] = "nova"             # node_attribute
default["nova"]["services"]["novnc-server"]["port"] = 6080                  # node_attribute
default["nova"]["services"]["novnc-server"]["path"] = "/vnc_auto.html"      # node_attribute

default["nova"]["services"]["volume"]["scheme"] = "http"                    # node_attribute
default["nova"]["services"]["volume"]["network"] = "public"                 # node_attribute
default["nova"]["services"]["volume"]["port"] = 8776                        # node_attribute
default["nova"]["services"]["volume"]["path"] = "/v1/%(tenant_id)s"         # node_attribute
default["nova"]["services"]["volume"]["cinder_catalog_info"] = "volume:cinder:publicURL" #nod_ attribute

# can this be wedged into the "api" endpoint?                               # node_attribute
default["nova"]["compute"]["region"] = "RegionOne"                          # node_attribute
default["nova"]["compute"]["connection_type"] = "libvirt"                          # node_attribute

default["nova"]["scheduler"]["scheduler_driver"] = "nova.scheduler.filter_scheduler.FilterScheduler"           # cluster_attribute
default["nova"]["scheduler"]["least_cost_functions"] = "nova.scheduler.least_cost.compute_fill_first_cost_fn"   # cluster_attribute
default["nova"]["libvirt"]["virt_type"] = "kvm"                                     # node_attribute (inherited from cluster?)
default["nova"]["libvirt"]["vncserver_listen"] = node["ipaddress"]                  # node_attribute
default["nova"]["libvirt"]["vncserver_proxyclient_address"] = node["ipaddress"]     # node_attribute
default["nova"]["libvirt"]["auth_tcp"] = "none"                                     # node_attribute (inherited from cluster?)
default["nova"]["libvirt"]["remove_unused_base_images"] = true                      # node_attribute (inherited from cluster?)
default["nova"]["libvirt"]["remove_unused_resized_minimum_age_seconds"] = 3600      # node_attribute (inherited from cluster?)
default["nova"]["libvirt"]["remove_unused_original_minimum_age_seconds"] = 3600     # node_attribute (inherited from cluster?)
default["nova"]["libvirt"]["checksum_base_images"] = false                          # node_attribute (inherited from cluster?)
default["nova"]["libvirt"]["libvirt_inject_key"] = false                            # cluster_attribute
default["nova"]["config"]["use_single_default_gateway"] = false                     # cluster_attribute
default["nova"]["config"]["availability_zone"] = "nova"                             # node_attribute
default["nova"]["config"]["default_schedule_zone"] = "nova"                         # cluster_attribute
default["nova"]["config"]["force_raw_images"] = false                               # cluster_attribute
default["nova"]["config"]["allow_same_net_traffic"] = true                          # cluster_attribute
default["nova"]["config"]["osapi_max_limit"] = 1000                                 # cluster_attribute
default["nova"]["config"]["cpu_allocation_ratio"] = 16.0                            # node_attribute (inherited from cluster?)
default["nova"]["config"]["ram_allocation_ratio"] = 1.5                             # node_attribute (inherited from cluster?)
default["nova"]["config"]["snapshot_image_format"] = "qcow2"                        # cluster_attribute
default["nova"]["config"]["start_guests_on_host_boot"] = false                       # node_attribute (inherited from cluster?)
default["nova"]["config"]["scheduler_max_attempts"] = 3                       # node_attribute (inherited from cluster?)
default["nova"]["config"]["ec2_workers"] = [8, node["cpu"]["total"].to_i].min       # node_attribute
default["nova"]["config"]["osapi_compute_workers"] = [8, node["cpu"]["total"].to_i].min # node_attribute
default["nova"]["config"]["metadata_workers"] = [8, node["cpu"]["total"].to_i].min      # node_attribute
default["nova"]["config"]["osapi_volume_workers"] = [8, node["cpu"]["total"].to_i].min  # node_attribute
default["nova"]["config"]["hardware_gateway"] = nil
default["nova"]["config"]["dns_servers"] = []
default["nova"]["config"]["dnsmasq_config_file"] = "/etc/nova/dnsmasq-nova.conf"
default["nova"]["config"]["quota_fixed_ips"] = "40"
default["nova"]["config"]["quota_instances"] = "20"
# requires https://review.openstack.org/#/c/8423/
default["nova"]["config"]["resume_guests_state_on_host_boot"] = false               # node_attribute (inherited from cluster?)

# LOGGING VERBOSITY
# in order of verbosity (most to least)
# DEBUG, INFO, WARNING, ERROR, CRITICAL
default["nova"]["config"]["log_verbosity"] = "INFO"                                 # node attributes

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
    "api_ec2_process_name" => "openstack-nova-api",
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
    "nova_scheduler_packages" => ["openstack-nova-scheduler"],
    "nova_scheduler_service" => "openstack-nova-scheduler",
    "nova_conductor_packages" => ["openstack-nova-conductor"],
    "nova_conductor_service" => "openstack-nova-conductor",
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
    "common_packages" => ["openstack-nova-common", "python-cinderclient"],
    "iscsi_helper" => "tgtadm",
    "iscsi_service" => "tgtd",
    "package_overrides" => "",
    "nova_scheduler_default_filters" => [ "AvailabilityZoneFilter",                                   # cluster_attribute
                                          "RamFilter",
                                          "ComputeFilter",
                                          "CoreFilter",
                                          "SameHostFilter",
                                          "DifferentHostFilter",
                                          "RetryFilter"]
  }
when "ubuntu"
  default["nova"]["platform"] = {                                                   # node_attribute
    "api_ec2_packages" => ["nova-api-ec2"],
    "api_ec2_service" => "nova-api-ec2",
    "api_ec2_process_name" => "nova-api-ec2",
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
    "nova_scheduler_packages" => ["nova-scheduler"],
    "nova_scheduler_service" => "nova-scheduler",
    "nova_conductor_packages" => ["nova-conductor"],
    "nova_conductor_service" => "nova-conductor",
    # Websockify is needed due to https://bugs.launchpad.net/ubuntu/+source/nova/+bug/1076442
    "nova_vncproxy_packages" => ["novnc", "websockify", "nova-novncproxy"],
    "nova_vncproxy_service" => "nova-novncproxy",
    "nova_vncproxy_consoleauth_packages" => ["nova-consoleauth"],
    "nova_vncproxy_consoleauth_service" => "nova-consoleauth",
    "nova_vncproxy_consoleauth_process_name" => "nova-consoleauth",
    # README(shep): python-libvirt does not get automatically upgraded
    "libvirt_packages" => ["libvirt-bin", "python-libvirt", "pm-utils"],
    "libvirt_service" => "libvirt-bin",
    "nova_cert_packages" => ["nova-cert"],
    "nova_cert_service" => "nova-cert",
    "mysql_service" => "mysql",
    "common_packages" => ["nova-common", "python-nova", "python-novaclient"],
    "iscsi_helper" => "tgtadm",
    "iscsi_service" => "tgt",
    "package_overrides" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'",
    "nova_scheduler_default_filters" => [ "AvailabilityZoneFilter",                                   # cluster_attribute
                                          "RamFilter",
                                          "ComputeFilter",
                                          "CoreFilter",
                                          "SameHostFilter",
                                          "DifferentHostFilter",
                                          "RetryFilter"]
  }
end
