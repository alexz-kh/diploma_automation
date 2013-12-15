#!/bin/bash

#for debug use bash -x ./kvm_spawner.sh

#TEMPHOSTNAME=$1
DIR=`dirname $0`


footer(){
    echo "=============== ================="
    echo "===============  $1 ================="
    echo "=============== ================="
}
checker(){
    if [ $? -ne 0 ]; then
    footer "Error!$1"
	exit 1
    fi
}

prepare_vm(){

if [[ $1 =~ ^[broker] ]]
    then
	echo "Prepare system for Broker:"
	HDD="${BASE_DIR}/systems/${SYSTEMS_PREFIX}_${role}.qcow2"
	sed -e "s#HDD_STUB#${HDD}#g" broker_template.xml > ${SYSTEMS_PREFIX}_${role}.xml
	sed -e "s#NAME_STUB#${HDD}#g" broker_template.xml > ${SYSTEMS_PREFIX}_${role}.xml

	"exit "
elif [[ $1 =~ ^[node] ]]
    then 
	echo "Prepare system for node:"
	sed -e "s#HDD_STUB#${HDD}#g" node_template.xml > ${SYSTEMS_PREFIX}_${role}.xml
	sed -e "s#NAME_STUB#${HDD}#g" node_template.xml > ${SYSTEMS_PREFIX}_${role}.xml
	exit

else
        footer "Wrong choose,Neo..."
	exit 1
fi

}




SYSTEMS_PREFIX="dep1"
COPY_FROM_IMG="/home/alexz/work/imgs/checked/cloud/centos_clear_wo_lvm_40G_2.6.32-431.el6.x86_64.qcow2"
#COPY_FROM_IMG="/home/alexz/work/imgs/checked/cloud/stub.qcow2"
BASE_DIR="/home/alexz/work/diplom/test_spawner1"

mkdir -p "${BASE_DIR}/systems"


####Role chooser####
echo "Choose next system role:"
echo -e "1)Broker \n2)Node"
read -p "[1/2]" -n 1 -r
echo    # just move to a new line
    if [[ $REPLY =~ ^[1]$ ]]
    then
	echo "Choosed 1=Broker"
	REPLY="broker"
	sed -i "s/role=.*/role=\"${REPLY}\"/g" ../role/next_role.sh
#	git add .
#	git commit -a -m "change role to ${REPLY}"
#	git push
	source ../role/next_role.sh
	prepare_vm $REPLY

    elif [[ $REPLY =~ ^[2]$ ]]
    then 
	echo "Choosed 2=Node"
	REPLY="node"
    else
        footer "Wrong choose,Neo..."
	exit 1
    fi
#######
sed -i "s/role=.*/role=\"${REPLY}\"/g" ../role/next_role.sh
git add .
git commit -a -m "change role to ${REPLY}"
git push
source ../role/next_role.sh
HDD="${BASE_DIR}/systems/${SYSTEMS_PREFIX}_${role}.qcow2"


exit 1
###########Prepare and define systems#########
footer "Start kvm system with ROLE=${role}"
HDD="${BASE_DIR}/systems/${SYSTEMS_PREFIX}_${role}.qcow2"


if [ -f ${HDD} ]
then
    echo "Error!HDD file ($HDD) already exist!Rewrite or skip?"
    read -p "[R/S]" -n 1 -r
    echo    # just move to a new line
    if [[ $REPLY =~ ^[Rr]$ ]]
    then
        # do dangerous stuff
        cp -f ${COPY_FROM_IMG} ${HDD}
    else 
        footer "Aborted..."
	exit 1
    fi
else
    cp ${COPY_FROM_IMG} ${HDD}
    checker "When try copy img!"
fi

##
exit 




###



virsh define ${SYSTEMS_PREFIX}_${role}.xml
checker "When try define systems!"
footer "Finish define kvm system with ROLE=${role}"
##########







exit
#TEMPHOSTNAME="brokertest1"
#OURBIND="37.57.27.211"
#CLOUDNAME="kpi.diplom.net"
#NAMED_TSIG_PRIV_KEY="XI1h53oLBi1uGXEbV1NU301BQp/w5A=="
#BROKER_FQDN="brokertest1.kpi.diplom.net"

###Start registrathions on DNS

IP_ADDRESS=`ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`

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
yes|cp -rf diploma_automation/init/modules_fixed_release2/* /etc/puppet/modules/

#####################3
#Start generating manifests:

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
  named_ipaddress=> "${OURBIND}",
  broker_fqdn=> "${BROKER_FQDN}",
  named_tsig_priv_key=> "${NAMED_TSIG_PRIV_KEY}",

}
EOF

puppet apply --verbose manifest_broker.pp


exit

####FIXER:
###yum install npm -y



