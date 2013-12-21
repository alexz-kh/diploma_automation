#!/bin/bash

#for debug use bash -x ./kvm_spawner.sh

DIR=`dirname $0`

footer(){
    echo "=============== ================="
    echo "===============  $1 ================="
    echo "=============== ================="
}
checker(){
    if [ $? -ne 0 ]; then
    footer "Error!$1" ; exit 1 ; fi
}

generate_next_nodename_funx(){
    nodes_all_count=0
    read nodes_all <<< `virsh list --all |grep -v "broker" | grep "${SYSTEMS_PREFIX}" | awk ' {print $2}'`
    read nodes_all_count <<< `virsh list --all |grep -v "broker" | grep "${SYSTEMS_PREFIX}" | wc -l `

    echo -e "For deployment \"${SYSTEMS_PREFIX}\" you have VMs: $nodes_all.\n Count: $nodes_all_count"
    #gen next node name
    let "nodes_all_count++"
    echo "next=$nodes_all_count"
    VMNAME=${SYSTEMS_PREFIX}-node-$nodes_all_count
}


prepare_vm(){
mkdir -p "${BASE_DIR}/systems"

if [ "$1" == "broker" ] || [ "$1" == "node" ]; then
	echo "Prepare system for role=$1"
	echo "role=$1 VMNAME=$2"
	HDD="${BASE_DIR}/systems/$2.qcow2"
	sed -e "s#HDD_STUB#${HDD}#g" ${1}_template.xml > ${2}.xml
	sed -i "s#NAME_STUB#${2}#g" ${2}.xml
	#copy hdd image
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
			footer "Use OLD hdd image.Its bad idea,but okay :("
		    fi
	    else
    		cp ${COPY_FROM_IMG} ${HDD}
		checker "When try copy img!"
	    fi
	virsh define ${2}.xml
	checker "When try define systems!"
	source ../role/next_role.sh
	footer "Finish define kvm system with ROLE=${1} and fqdn=$TEMPHOSTNAME.$CLOUDNAME"
else
        footer "Wrong choose,Neo..."
	exit 1
fi
}


####Role chooser####
source ../role/next_role.sh

echo "Choose next VM-system role:"
echo -e "1)Broker \n2)Node"
read -p "[1/2]" -n 1 -r
echo    # just move to a new line
    if [[ $REPLY =~ ^[1]$ ]]
    then
	echo "Choosed 1=Broker"
	ROLE="broker"
	sed -i "s/role=.*/role=\"${ROLE}\"/g" ../role/next_role.sh
#	git add .
	git commit  ../role/next_role.sh -m "change role to ${REPLY}"
	git push
	source ../role/next_role.sh
# in this tool, broker can be only one!
	sed -i "s/TEMPHOSTNAME=.*/TEMPHOSTNAME=\"$SYSTEMS_PREFIX-broker\"/g" ../role/next_role.sh
	BROKERNAME="${SYSTEMS_PREFIX}-broker"
	prepare_vm $ROLE $BROKERNAME
	sleep 1
	echo "Running $BROKERNAME"
	sleep 1
	virsh start $BROKERNAME

    elif [[ $REPLY =~ ^[2]$ ]]
    then 
	echo "Choosed 2=Node"
	ROLE="node"
	sed -i "s/role=.*/role=\"${ROLE}\"/g" ../role/next_role.sh
#	git add .
#	git commit -a -m "change role to ${REPLY}"
	git commit ../role/next_role.sh -m "change role to ${REPLY}"
	git push
	source ../role/next_role.sh
	generate_next_nodename_funx
	sed -i "s/TEMPHOSTNAME=.*/TEMPHOSTNAME=\"${VMNAME}\"/g" ../role/next_role.sh
	echo "vmname=$VMNAME"
	prepare_vm $ROLE $VMNAME
	sleep 1
	echo "Running $VMNAME"
	sleep 1
	virsh start $VMNAME

    else
        footer "Wrong choose,Neo..."
	exit 1
    fi
#######


exit
