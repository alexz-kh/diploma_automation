#!/bin/bash

DIR=`dirname $0`
cd $DIR

#Put this file on VMs! and one-time run
#$ echo "/root/bootstrap/os_init.sh" >>  /etc/rc.local

if [ -f "/root/bootstrap/finish" ] ; then exit

else 

if which git >/dev/null; then
    echo "Git exist,all ok,go next!"
else
    echo "Git does not exist!installing..."
    yum install -y git
    if [ $? -ne 0 ]; then
        echo "Error!!" ; exit 1 ; fi

fi

if [ -d "diploma_automation" ]; then
    cd diploma_automation
    git stash
    git checkout master
    git pull origin master --force
    cd ../
    else
    git clone git://github.com/alexz-kh/diploma_automation.git
    if [ $? -ne 0 ]; then
	echo "Error!!" ; exit 1 ; fi

fi

./diploma_automation/init/install.sh 2>>&1  /root/bootstrap/os_init_log_`date "+%Y-%m-%d-%H-%M"`

fi
exit
