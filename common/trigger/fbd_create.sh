#!/bin/sh

###header

readonly VAR_PARAMETERS='$1 $ENV_SSH_USER_NAME, $2 password for user, $3 vm name, $4 vm OS version'

if [ -r ${3}_create.ok ]; then rm ${3}_create.ok; fi
exec 1>${3}_create.log
exec 2>${3}_create.err
exec 3>${3}_create.tst
if [ "$#" != "4" ]; then echo "Call syntax: $(basename "$0") $VAR_PARAMETERS"; exit 1; fi

###function

checkRetValOK(){
  if [ "$?" != "0" ]; then exit 1; fi
}

###body

echo "VM $3 OS version:" $4
#set hostname
hostname "${3}"
checkRetValOK
echo "hostname \"${3}\"" >> /etc/rc.conf
checkRetValOK
#add user
pw useradd -m -d /home/$1 -n $1
checkRetValOK
pw groupadd sudo
checkRetValOK
pw groupmod sudo -m $1
checkRetValOK
#set user password
echo $2 | pw mod user $1 -h 0
checkRetValOK
#check new user home directory exist
if [ ! -d /home/${1} ]; then
  echo "Error: directory /home/${1} not found"
  exit 1
fi
#create .ssh subdirectory
mkdir -m u=rwx,g=,o= /home/${1}/.ssh
checkRetValOK
chown ${1}:${1} /home/${1}/.ssh
checkRetValOK
#check source ssh key file exist
if [ ! -s $HOME/.ssh/authorized_keys ]; then
  echo "Error: file $HOME/.ssh/authorized_keys not found or empty"
  exit 1
fi
#copy ssh key file to target directory
cp $HOME/.ssh/authorized_keys /home/${1}/.ssh/
checkRetValOK
chown $1 /home/${1}/.ssh/authorized_keys
checkRetValOK
chmod u=rw,g=,o= /home/${1}/.ssh/authorized_keys
checkRetValOK
#install standard packages
export ASSUME_ALWAYS_YES=yes
checkRetValOK
pkg install sudo
checkRetValOK
export ASSUME_ALWAYS_YES=
checkRetValOK
#check sudo config file exist
if [ ! -s /usr/local/etc/sudoers ]; then
  echo "Error: file /usr/local/etc/sudoers not found or empty"
  exit 1
fi
#add sudo group without password setting
chmod u+w /usr/local/etc/sudoers
checkRetValOK
echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /usr/local/etc/sudoers
checkRetValOK
chmod u-w /usr/local/etc/sudoers
checkRetValOK

##test

#check packages version
sudo --version >&3
checkRetValOK

###finish

echo 1 > ${3}_create.ok
exit 0
