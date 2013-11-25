#!/bin/bash


role="broker"

TEMPHOSTNAME="brokertest"

BROKER_FQDN="brokertest1.kpi.diplom.net"
CLOUDNAME="kpi.diplom.net"
OURBIND="37.57.27.211"
NAMED_TSIG_PRIV_KEY="XI1h53oLBi1uGXEbV1NU301BQp/w5A=="

sh -x ../init/install.sh
