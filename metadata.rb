maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description       "Installs and configures Openstack"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.19"
recipe		  "api-ec2", ""
recipe		  "api-metadata", ""
recipe		  "api-os-compute", ""
recipe		  "api-os-volume", ""
recipe		  "compute", ""
recipe		  "default", ""
recipe		  "libvirt", ""
recipe		  "network", ""
recipe		  "nova-common", ""
recipe		  "nova-rsyslog", ""
recipe		  "nova-scheduler-patch", ""
recipe		  "nova-setup", ""
recipe		  "scheduler", ""
recipe		  "vncproxy", ""
recipe		  "volume", ""

%w{ ubuntu fedora redhat centos }.each do |os|
  supports os
end

%w{ apt cinder database dsh glance keystone monitoring mysql openssh rabbitmq selinux nova-network osops-utils sysctl yum }.each do |dep|
  depends dep
end
