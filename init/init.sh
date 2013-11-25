#!/bin/bash



#todo add if!
yum install -y git

git clone git://github.com/alexz-kh/diploma_automation.git

cd diploma_automation
git reset
git stash
git pull --force

./role/next_role.sh



exit 



cat _EOF >>> ~/.ssh/config 
Host github.com
    User git
    Hostname github.com
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null

