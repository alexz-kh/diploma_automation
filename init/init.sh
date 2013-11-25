#!/bin/bash

#Put this file on VMs!

if which git >/dev/null; then
    echo "Git exist,all ok,go next!"
else
    echo "Git does not exist!installing..."
    yum install -y git

fi


if [ -d "diploma_automation" ]; then
    cd diploma_automation
    git stash
    git checkout master
    git pull origin master --force
    ./role/next_role.sh
    else 
    git clone git://github.com/alexz-kh/diploma_automation.git
    ./diploma_automation/init/install.sh

fi


exit 






cat _EOF >>> ~/.ssh/config 
Host github.com
    User git
    Hostname github.com
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null

