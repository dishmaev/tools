#!/bin/sh

#$1 $ENV_SSH_USER_NAME, $2 password for user, $3 vm name, $4 vm OS version

if [ "$#" != "4" ]; then exit 1; fi
if [ -f ${3}_create.result ]; then rm ${3}_create.result; fi
exec 1>${3}_create.log
exec 2>${3}_create.err
echo "VM $3 OS version:" $4

###body

#set hostname
svccfg -s system/identity:node setprop config/nodename="$3"
svccfg -s system/identity:node setprop config/loopback="$3"
#svcadm refresh system/identity:node
#svcadm restart system/identity:node
#add user
useradd -m $1;
groupadd sudo;
usermod -G +sudo $1;
#set user password
echo '#!/usr/bin/expect --
set USER [lindex $argv 0]
set PASS [lindex $argv 1]
spawn passwd $USER
expect "assword:"
send "$PASS\r"
expect "assword:"
send "$PASS\r"
expect eof' > ors_create_chpwd.sh
chmod u+x ors_create_chpwd.sh
./ors_create_chpwd.sh $1 $2
#check new user home directory exist
if [ ! -d /export/home/${1} ]; then
  echo "Error: directory /export/home/${1} not found"
  exit 1
fi
#create .ssh subdirectory
mkdir -m u=rwx,g=,o= /export/home/${1}/.ssh
chown ${1}:staff /export/home/${1}/.ssh
#check source ssh key file exist
if [ ! -s $HOME/.ssh/authorized_keys ]; then
  echo "Error: file $HOME/.ssh/authorized_keys not found or empty"
  exit 1
fi
#copy ssh key file to target directory
cp $HOME/.ssh/authorized_keys /export/home/${1}/.ssh/
chown ${1}:staff /export/home/${1}/.ssh/authorized_keys
chmod u=rw,g=,o= /export/home/${1}/.ssh/authorized_keys
#check sudo config file exist
if [ ! -s /etc/sudoers ]; then
  echo "Error: file /etc/sudoers not found or empty"
  exit 1
fi
#add sudo group without password setting
chmod u+w /etc/sudoers
echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
chmod u-w /etc/sudoers

#install standard packages
#pkg install developer/versioning/git

#check standard packages version
sudo --version
#git --version

###finish

echo 1 > ${3}_create.result
