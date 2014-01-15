#!/bin/bash

role="broker"
#kvm spawner config:
SYSTEMS_PREFIX="prefix1"
#COPY_FROM_IMG="/home/alexz/work/imgs/checked/cloud/stub.qcow2"
#COPY_FROM_IMG="/home/alexz/work/imgs/checked/cloud/centos_clear_wo_lvm_40G_2.6.32-431.el6.x86_64.qcow2"
COPY_FROM_IMG="/home/alexz/work/diplom/deployment-automation/base.qcow2"
#COPY_FROM_IMG="/home/alexz/work/diplom/deployment-automation/base_fast.qcow2"
#this dir containg copyed images:
BASE_DIR="/home/alexz/work/diplom/test_spawner1"

#OpenShift system config for next spawn:
CLOUDNAME="kpi.diplom.net"
#Do not edit TEMPHOSTNAME!
TEMPHOSTNAME="prefix1-broker"
BROKER_FQDN="$SYSTEMS_PREFIX-broker.$CLOUDNAME"
OURBIND="37.57.27.211"
#OURBIND="8.8.8.8"
NAMED_TSIG_PRIV_KEY="XI1h53oLBi1uGXEbV1NU301BQp/w5A=="

