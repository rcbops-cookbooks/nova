Support
=======

Issues have been disabled for this repository.  
Any issues with this cookbook should be raised here:

[https://github.com/rcbops/chef-cookbooks/issues](https://github.com/rcbops/chef-cookbooks/issues)

Please title the issue as follows:

[nova]: \<short description of problem\>

In the issue description, please include a longer description of the issue, along with any relevant log/command/error output.  
If logfiles are extremely long, please place the relevant portion into the issue description, and link to a gist containing the entire logfile

Please see the [contribution guidelines](CONTRIBUTING.md) for more information about contributing to this cookbook.

Description
===========

Installs the Openstack compute service (codename: nova) from packages.

http://nova.openstack.org

Requirements
============

Chef 0.10.0 or higher required (for Chef environment use).

Platforms
--------

* CentOS >= 6.3
* Ubuntu >= 12.04

Cookbooks
---------

The following cookbooks are dependencies:

* cinder
* database
* dsh
* keystone
* mysql
* nova-network
* openssl
* osops-utils
* sysctl

Resources/Providers
===================

Conf
----

Handles creation of nova.conf file

Recipes
=======

api-ec2
----
- Includes recipe `nova-common`  
- Installs AWS EC2 compatible API and configures the service and endpoints in keystone  

api-metadata
----
- Includes recipe `nova-common`  
- Installs the nova metadata package  

api-os-compute
----
- Includes recipe `nova-common`  
- Installs OS API and configures the service and endpoints in keystone  

api-os-volume
----
- Includes recipe `nova-common`  
- Installs the OpenStack volume service API  

compute
----
- Includes recipes `nova-common`, `api-metadata`
- Installs nova-compute service  

essex-final-volume
----
- Includes recipes `nova-common` and `api-os-volume`
- Installs nova volume service and configures the service and endpoints in keystone  
- To use you must created a LVM Volume Group named nova-volumes

folsom-volume
---
- Includes recipes `cinder::cinder-setup`, `cinder::cinder-api`, `cinder::cinder-scheduler`

libvirt
----
- Installs libvirt, used by nova compute for management of the virtual machine environment  

nova-cert
----
- Includes recipe `nova-common`
- Installs nova-cert service

nova-common
----
- Includes recipe `osops-utils::autoetchosts`
- Builds the basic nova.conf config file with details of the rabbitmq, mysql, glance and keystone servers  
- Builds a openrc file for root with appropriate environment variables to interact with the nova client CLI  

nova-scheduler-patch
----
- Includes recipe `osops-utils`
- Patches nova-scheduler based on installed package version

nova-setup
----
- Includes recipes `nova-common`, `mysql::client`, `mysql::ruby`
- Sets up the nova database on the mysql server, including the initial schema

scheduler
----
- Includes recipe `nova-common`  
- Installs nova scheduler service  

vncproxy
----
- Includes recipe `nova-common`  
- Installs and configures the vncproxy service for console access to VMs  


Attributes
==========

* `nova["debug"]` - Boolean to enable nova debug output
* `nova["patch_files_on_disk"]` - Boolean for patching files on disk
* `nova["db"]["name"]` - Name of nova database
* `nova["db"]["username"]` - Username for nova database access
* `nova["db"]["password"]` - Password for nova database access
NOTE: db password is no longer set statically in the attributes file, but securely/randomly in the nova-common recipe

* `nova["service_tenant_name"]` - Tenant name used by nova when interacting with keystone
* `nova["service_user"]` - User name used by nova when interacting with keystone
* `nova["service_pass"]` - User password used by nova when interacting with keystone
NOTE: service password is no longer set statically in the attributes file, but securely/randomly in the *api recipes
* `nova["service_role"]` - User role used by nova when interacting with keystone

* `nova["volumes"]["enabled"]` - Turn the nova-volumes service on or off

* `nova["services"]["api"]["scheme"]` - Scheme for OpenStack API service (http/https)
* `nova["services"]["api"]["network"]` - `osops_networks` network name which service operates on
* `nova["services"]["api"]["port"]` - Port to bind service to
* `nova["services"]["api"]["path"]` - URI to use
* `nova["services"]["api"]["cert_override"]` - For SSL - specify location of custom Cert file
* `nova["services"]["api"]["key_override"]` - For SSL - specify location of custom Key file

* `nova["services"]["ec2-admin"]["scheme"]` - Scheme for EC2-compatible admin service (http/https)
* `nova["services"]["ec2-admin"]["network"]` - `osops_networks` network name which service operates on
* `nova["services"]["ec2-admin"]["port"]` - Port to bind service to
* `nova["services"]["ec2-admin"]["path"]` - URI to use

* `nova["services"]["ec2-public"]["scheme"]` - Scheme for EC2-compatible public service (http/https)
* `nova["services"]["ec2-public"]["network"]` - `osops_networks` network name which service operates on
* `nova["services"]["ec2-public"]["port"]` - Port to bind service to
* `nova["services"]["ec2-public"]["path"]` - URI to use
* `nova["services"]["ec2-public"]["cert_override"]` - For SSL - specify location of custom Cert file
* `nova["services"]["ec2-public"]["key_override"]` - For SSL - specify location of custom Key file

* `nova["services"]["xvpvnc-proxy"]["scheme"]` - Scheme for xvpvncproxy service service (http/https)
* `nova["services"]["xvpvnc-proxy"]["network"]` - `osops_networks` network name which service operates on
* `nova["services"]["xvpvnc-proxy"]["port"]` - Port to bind service to
* `nova["services"]["xvpvnc-proxy"]["path"]` - URI to use

* `nova["services"]["novnc-proxy"]["scheme"]` - Scheme for novncproxy service (http/https)
* `nova["services"]["novnc-proxy"]["network"]` - `osops_networks` network name which service operates on
* `nova["services"]["novnc-proxy"]["port"]` - Port to bind service to
* `nova["services"]["novnc-proxy"]["path"]` - URI to use

* `nova["services"]["novnc-server"]["scheme"]` - Scheme for novncserver service (http/https)
* `nova["services"]["novnc-server"]["network"]` - `osops_networks` network name which service operates on
* `nova["services"]["novnc-server"]["port"]` - Port to bind service to
* `nova["services"]["novnc-server"]["path"]` - URI to use

* `nova["services"]["volume"]["scheme"]` - Scheme for volume service (http/https)
* `nova["services"]["volume"]["network"]` - `osops_networks` network name which service operates on
* `nova["services"]["volume"]["port"]` - Port to bind service to
* `nova["services"]["volume"]["path"]` - URI to use
* `nova["services"]["volume"]["cinder_catalog_info"]` - URL used for cinder

* `nova["scheduler"]["scheduler_driver"]` - The scheduler driver to use
NOTE: The filter scheduler currently does not work with ec2.
* `nova["scheduler"]["scheduler_weight_classes"]` - A list of weight class names (separated by commas) to use for weighing hosts, defaults to nova.scheduler.weights.ram.RAMWeigher
* `nova["scheduler"]["ram_weight_multiplier"]` - Multiplier used for weighing RAM (a negative number will stack instances, positive will spread), defaults to 1.0
* `nova["scheduler"]["default_filters"]` - An Array of [filters](http://docs.openstack.org/trunk/openstack-compute/admin/content/scheduler-filters.html) to use when scheduling instances. Maps to `scheduler_default_filters` in nova.conf.
* `nova["libvirt"]["virt_type"]` - What hypervisor software layer to use with libvirt (e.g., kvm, qemu)
* `nova["libvirt"]["vncserver_listen"]` - IP address on the hypervisor that libvirt listens for VNC requests on
* `nova["libvirt"]["vncserver_proxyclient_address"]` - IP address on the hypervisor that libvirt exposes for VNC requests on (should be the same as vncserver_listen)
* `nova["libvirt"]["auth_tcp"]` - Type of authentication your libvirt layer requires
* `nova["libvirt"]["remove_unused_base_images"]` - Remove unused base images?
* `nova["libvirt"]["remove_unused_resized_minimum_age_seconds"]` - Defaults to 3600 seconds
* `nova["libvirt"]["remove_unused_original_minimum_age_seconds"]` - Defaults to 3600 seconds
* `nova["libvirt"]["checksum_base_images"]` - Record and validate image checksums?
* `nova["libvirt"]["libvirt_inject_key"]` - Inject ssh public key at boot?
* `nova["libvirt"]["libvirt_inject_password"]` - Inject root password at boot?
* `nova["libvirt"]["libvirt_inject_partition"]` - The partition to inject to: -2 = disable, -1 = inspect (libguestfs only), 0 = not partitioned, >0 = partition number
* `nova["libvirt"]["libvirt_cpu_mode"]` - Options include "host-model", "host-passthrough", "custom", and "none"; cookbook defaults to nil and does not insert into nova.conf unless adjusted
* `nova["libvirt"]["libvirt_cpu_model"]` - This attribute is only applicable when `virt_type` is "kvm" or "qemu" and `libvirt_cpu_mode` is "custom"; cookbook defaults to nil and does not insert into nova.conf unless changed and applicable
* `nova["libvirt"]["disk_cachemodes"]` - KVM disk caching modes.  Defaults to "file=none".  To set writeback mode use "file=writeback".  To set multiple modes use "file=writeback,block=none"
* `nova["config"]["use_single_default_gateway"]` - Use single default gateway?
* `nova["config"]["availability_zone"]` - Nova availability zone.  Usually set at the node level to place a compute node in another az
* `nova["config"]["default_schedule_zone"]` - The availability zone to schedule instances in when no az is specified in the request
* `nova["config"]["force_raw_images"]` - Convert all images used as backing files for instances to raw (we default to false)
* `nova["config"]["allow_same_net_traffic"]` - Disable security groups for internal networks (we default to true)
* `nova["config"]["osapi_max_limit"]` - The maximum number of items returned in a single response from a collection resource (default is 1000)
* `nova["config"]["cpu_allocation_ratio"]` - Virtual CPU to Physical CPU allocation ratio (default 16.0)
* `nova["config"]["ram_allocation_ratio"]` - Virtual RAM to Physical RAM allocation ratio (default 1.5)
* `nova["config"]["snapshot_image_format"]` - Snapshot image format (valid options are : raw, qcow2, vmdk, vdi [we default to qcow2]).
* `nova["config"]["start_guests_on_host_boot"]` - Whether to restart guests when the host reboots
* `nova["config"]["scheduler_max_attempts"]` - Max number of attempts to schedule an instance before setting to error status
* `nova["config"]["resume_guests_state_on_host_boot"]` - Whether to start guests that were running before the host rebooted

* `nova["config"]["hardware_gateway"]` - Specify an external gateway IP for instances
* `nova["config"]["dns_servers"]` - array of alternate DNS servers that dnsmasq should use when giving DHCP info to instances

* `nova["config"]["log_verbosity"]` - Logging verbosity.  Valid options are DEBUG, INFO, WARNING, ERROR, CRITICAL.  Default is INFO

* `nova["config"]["quota_security_groups"]` - Number of security groups per project, defaults to 50
* `nova["config"]["quota_security_group_rules"]` - Number of security rules per security group, defaults to 20
* `nova["config"]["force_config_drive"]` - Force attachment of config drive, defaults to false
* `nova["config"]["reserved_host_disk_mb"]` - Amount of disk in MB to reserve for the host, defaults to 0

* `nova["ratelimit"]["settings"]` - Tune OpenStack Compute API rate limits.  For Example:
"override_attribute": {
  "nova": {
     "ratelimit": {
        "settings": {
          "changes-since-limit": {
            "limit": "500000",
            "verb": "GET",
            "uri": "*changes-since*",
            "interval": "MINUTE",
            "regex": ".*changes-since.*"
          },
          "create-servers-limit": {
            "limit": "500000",
            "verb": "POST",
            "uri": "*/servers",
            "interval": "DAY",
            "regex": "^/servers"
          },
          "generic-post-limit": {
            "limit": "500000",
            "verb": "POST",
            "uri": "*",
            "interval": "MINUTE",
            "regex": ".*"
          },
          "generic-delete-limit": {
            "limit": "500000",
            "verb": "DELETE",
            "uri": "*",
            "interval": "MINUTE",
            "regex": ".*"
          },
          "generic-put-limit": {
            "limit": "500000",
            "verb": "PUT",
            "uri": "*",
            "interval": "MINUTE",
            "regex": ".*"
          }
        }
      }
    }
* `nova["ratelimit"]["api"]["enabled"]` - Enable API ratelimiting?
* `nova["ratelimit"]["volume"]["enabled"]` - Enable volume service ratelimiting?
* `nova["platform"]` - Hash of platform specific package/service names and options


Templates
=====
* `api-paste.ini.erb` - Paste config for nova API middleware
* `libvirt-bin.erb` - Initscript for starting libvirtd
* `libvirtd-ssh-config` - Config file for libvirt SSH auth
* `libvirtd.conf.erb` - Libvirt config file
* `nova.conf.erb` - Basic nova.conf file
* `nova-compute.conf.erb` - Config for nova-compute service (folsom only)
* `nova-logging.conf.erb` - Logging config for nova services
* `openrc.erb` - Contains environment variable settings to enable easy use of the nova client
* `patches/` - misc. patches for nova


License and Author
==================
Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)  
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)  
Author:: Ron Pedde (<ron.pedde@rackspace.com>)  
Author:: Joseph Breu (<joseph.breu@rackspace.com>)  
Author:: William Kelly (<william.kelly@rackspace.com>)  
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)  
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)  
Author:: Matt Thompson (<matt.thompson@rackspace.co.uk>)  
Author:: Andy McCrae (<andrew.mccrae@rackspace.co.uk>)  

Copyright 2012-2013, Rackspace US, Inc.  

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
