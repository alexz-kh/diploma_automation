#!/bin/bash


#TEMPHOSTNAME=$1
TEMPHOSTNAME=brokertest1

OURBIND=37.57.27.211
CLOUDNAME=kpi.diplom.net

IP_ADDRESS=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
#IP_ADDRESS=192.168.1.69

yum install -y bind-utils

cat <<EOF > /etc/sysconfig/network
NETWORKING=yes
HOSTNAME=${TEMPHOSTNAME}.${CLOUDNAME}
EOF

hostname ${TEMPHOSTNAME}.${CLOUDNAME}
domainname ${CLOUDNAME}

cat <<  _EOF > nsupdate.key
    key kpi.diplom.net {
      algorithm HMAC-MD5;
        secret "XI1h53oLBi1uGXEbV1NU301BQp/w5A==";
    };
_EOF

cat <<  _EOF > nsupdate.cmd
    server ${OURBIND} 53
    update delete ${TEMPHOSTNAME}.${CLOUDNAME} A
    update add ${TEMPHOSTNAME}.${CLOUDNAME} 180 A ${IP_ADDRESS}
    send
_EOF

chattr -i /etc/resolv.conf
cat <<EOF > /etc/resolv.conf
nameserver ${OURBIND}
EOF
chattr +i /etc/resolv.conf

nsupdate -k nsupdate.key -d nsupdate.cmd


#################################################
yum install -y --nogpgcheck http://dl.fedoraproject.org/pub/epel/6/x86_64//epel-release-6-8.noarch.rpm
yum install -y --nogpgcheck http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-7.noarch.rpm

cat <<EOF > /etc/yum.repos.d/epel.repo
[epel]
name=Extra Packages for Enterprise Linux 6 - \$basearch
#baseurl=http://download.fedoraproject.org/pub/epel/6/\$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
exclude=*mcollective*
EOF

cat <<EOF > /etc/yum.repos.d/puppetlabs.repo
[puppetlabs-products]
name=Puppet Labs Products El 6 - \$basearch
baseurl=http://yum.puppetlabs.com/el/6/products/\$basearch
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
enabled=1
gpgcheck=1
exclude=*mcollective*

[puppetlabs-deps]
name=Puppet Labs Dependencies El 6 - \$basearch
baseurl=http://yum.puppetlabs.com/el/6/dependencies/\$basearch
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-puppetlabs
enabled=1
gpgcheck=1
exclude=*mcollective*
EOF

yum install -y puppet facter tar
mkdir -p /etc/puppet/modules
#puppet module install openshift/openshift_origin --force


cat <<EOF > manifest_broker.pp

class { 'openshift_origin' :
  node_fqdn                  => "${TEMPHOSTNAME}.${CLOUDNAME}",
  cloud_domain               => '${CLOUDNAME}',
  dns_servers                => ['8.8.8.8'],
  os_unmanaged_users         => [],
  enable_network_services    => true,
  configure_firewall         => true,
  configure_ntp              => true,
  configure_activemq         => true,
  configure_mongodb          => true,
  configure_named            => false,
  configure_avahi            => false,
  configure_broker           => true,
  configure_node             => false,
  development_mode           => true,
  broker_auth_plugin         => 'mongo',
  broker_dns_plugin          => 'nsupdate',
  broker_dns_gsstsig         => true,
  named_ipaddress=> "37.57.27.211",
  broker_fqdn=> "brokeraiotest1.kpi.diplom.net",
  named_tsig_priv_key=> "XI1h53oLBi1uGXEbV1NU301BQp/w5A==",

}
EOF

#puppet apply --verbose manifest_aio.pp
wget 
exit 

####FIXER:
###yum install npm -y



