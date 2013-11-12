name              "nova"
maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description       "Installs and configures Openstack"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           IO.read(File.join(File.dirname(__FILE__), 'VERSION'))

%w{ centos ubuntu }.each do |os|
  supports os
end

%w{ cinder database dsh mysql nova-network openssl osops-utils sysctl apache2 ceph }.each do |dep|
  depends dep
end

depends "keystone", ">= 1.0.20"
