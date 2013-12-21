#!/bin/bash

#!/bin/bash

# os_init      init file for starting installing of Openshift_fiploma
#
# chkconfig:   - 90 10
# description: Starts and stops the MongDB daemon that handles all \
#              database requests.
#how-to add me:
#Put this file on VMs! and one-time run
#chkconfig --add /etc/init.d/os_init.sh 
#chkconfig --list os_init.sh
#chkconfig os_init.sh on

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

mkdir -p /root/bootstrap/
cd /root/bootstrap/

if [ -d "diploma_automation" ]; then
    cd diploma_automation
    git stash
    git checkout master 
    if [ $? -ne 0 ]; then
    echo "Error!!" ; exit 1 ; fi
    git pull origin master --force 
    if [ $? -ne 0 ]; then
    echo "Error!!" ; exit 1 ; fi
    else
    git clone git://github.com/alexz-kh/diploma_automation.git 
    if [ $? -ne 0 ]; then
    echo "Error!!" ; exit 1 ; fi
fi

/root/bootstrap/diploma_automation/init/install.sh &>>  /root/bootstrap/os_init_log_`date "+%Y-%m-%d-%H-%M"` &

fi
exit