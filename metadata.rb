maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description       "Installs and configures Openstack"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.21"
recipe		        "api-ec2", ""
recipe		        "api-metadata", ""
recipe		        "api-os-compute", ""
recipe		        "api-os-volume", ""
recipe		        "compute", ""
recipe		        "default", ""
recipe            "essex-final-volume", ""
recipe            "folsom-volume", ""
recipe		        "libvirt", ""
recipe            "nova-cert", ""
recipe		        "nova-common", ""
recipe		        "nova-rsyslog", ""
recipe		        "nova-scheduler-patch", ""
recipe		        "nova-setup", ""
recipe		        "scheduler", ""
recipe		        "vncproxy", ""
recipe		        "volume", ""

%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ cinder database dsh monitoring mysql nova-network openssl osops-utils sysctl }.each do |dep|
  depends dep
end

depends "keystone", ">= 1.0.17"
