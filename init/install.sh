#!/bin/bash

DIR=`dirname $0`
cd $DIR

footer(){
    echo "=============== ================="
    echo "===============  $1 ================="
    echo "=============== ================="
}
checker(){
    if [ $? -ne 0 ]; then
    footer "Error!$1" ; exit 1 ; fi
}

source ../role/next_role.sh
checker "start failed.."

###Start registrathions on DNS

IP_ADDRESS=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`

cat <<EOF > /etc/sysconfig/network
NETWORKING=yes
HOSTNAME=${TEMPHOSTNAME}.${CLOUDNAME}
EOF

hostname ${TEMPHOSTNAME}.${CLOUDNAME}
domainname ${CLOUDNAME}

cat <<  _EOF > nsupdate.key
    key kpi.diplom.net {
      algorithm HMAC-MD5;
        secret "$NAMED_TSIG_PRIV_KEY";
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

yum install -y bind-utils
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
yes|cp -rf modules_fixed_release2/* /etc/puppet/modules/

#####################
#Start generating manifests:

if [ $role == "broker" ]; then
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
      configure_node             => true,
      development_mode           => true,
      broker_auth_plugin         => 'mongo',
      broker_dns_plugin          => 'nsupdate',
      broker_dns_gsstsig         => true,
      named_ipaddress=> "${OURBIND}",
      broker_fqdn=> "${BROKER_FQDN}",
      named_tsig_priv_key=> "${NAMED_TSIG_PRIV_KEY}",
    }
EOF

checker "when try generate manifest!"
yum install npm -y
puppet apply manifest_broker.pp -vd --logdest /root/bootstrap/log_`date "+%Y-%m-%d-%H-%M"`
  if [ $? -ne 0 ]; then
    footer "Error!$1" ; echo "ERROR!see log!"> /root/bootstrap/finish ; exit 1 ; fi	
sed -i -e '20 s/^/export activemq_conf=\"\/etc\/activemq\"\n/;' /etc/init.d/activemq
sed -i -e '21 s/^/export activemq_data=\"\/var\/cache\/activemq\/data\"\n/;' /etc/init.d/activemq

elif [ $role == "node" ]; then
cat <<EOF > manifest_node.pp
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
      configure_broker           => false,
      configure_node             => true,
      development_mode           => true,
      broker_auth_plugin         => 'mongo',
      broker_dns_plugin          => 'nsupdate',
      broker_dns_gsstsig         => true,
      named_ipaddress=> "${OURBIND}",
      broker_fqdn=> "${BROKER_FQDN}",
      named_tsig_priv_key=> "${NAMED_TSIG_PRIV_KEY}",
    }
EOF
	checker "when try generate manifest!"
	puppet apply manifest_node.pp -vd --logdest /root/bootstrap/log_`date "+%Y-%m-%d-%H-%M"`
	  if [ $? -ne 0 ]; then
	    footer "Error!$1" ; echo "ERROR!see log!"> /root/bootstrap/finish ; exit 1 ; fi	
	yum install npm -y
else 
    checker "when try generate manifest!"
fi
#Now,time for fixes...
#yum install npm -y -for nodes only
#for broker
#sed -i -e '20 s/^/export activemq_conf=\"\/etc\/activemq\"\n/;' /etc/init.d/activemq  
#sed -i -e '21 s/^/export activemq_data=\"\/var\/cache\/activemq\/data\"\n/;' /etc/init.d/activemq
sed -i "s/php-5.4/php-5.3/g" /etc/openshift/quickstarts.json

echo -e "BIND_SERVER=\"37.57.27.211\"" >  /etc/openshift/plugins.d/openshift-origin-dns-nsupdate.conf
echo -e "BIND_PORT=53" >>  /etc/openshift/plugins.d/openshift-origin-dns-nsupdate.conf
echo -e "BIND_ZONE=\"kpi.diplom.net\"" >>  /etc/openshift/plugins.d/openshift-origin-dns-nsupdate.conf
echo -e "\n BIND_KEYNAME=\"kpi.diplom.net\"" >> /etc/openshift/plugins.d/openshift-origin-dns-nsupdate.conf
echo -e "\n BIND_KEYVALUE=\"XI1h53oLBi1uGXEbV1NU301BQp/w5A==\"" >> /etc/openshift/plugins.d/openshift-origin-dns-nsupdate.conf
touch /root/bootstrap/finish
reboot
exit

####FIXER:



