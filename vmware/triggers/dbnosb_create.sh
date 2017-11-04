#!/bin/sh

#$1 $COMMON_CONST_SSH_USER_NAME, $2 password for user, $3 vm name, $4 vm OS version

if [ "$#" != "4" ]; then exit 1; fi
if [ -f ${3}_create.result ]; then rm ${3}_create.result; fi
exec 1>${3}_create.log
exec 2>${3}_create.err
echo "VM $3 OS version:" $4

###body

#set hostname
hostnamectl set-hostname $3
#add user
useradd --create-home $1;
usermod -aG sudo $1;
#set user password
echo $2 > pass1
cp pass1 pass2
cat pass1 >> pass2
cat pass2 | passwd $1
rm pass1 pass2
#check new user home directory exist
if [ ! -d /home/${1} ]; then
  echo "Error: directory /home/${1} not found"
  exit 1
fi
#create .ssh subdirectory
mkdir -m u=rwx,g=,o= /home/${1}/.ssh
chown ${1}:users /home/${1}/.ssh
#check source ssh key file exist
if [ ! -s $HOME/.ssh/authorized_keys ]; then
  echo "Error: file $HOME/.ssh/authorized_keys not found or empty"
  exit 1
fi
#copy ssh key file to target directory
cp $HOME/.ssh/authorized_keys /home/${1}/.ssh/
chown ${1}:${1} /home/${1}/.ssh/authorized_keys
chmod u=rw,g=,o= /home/${1}/.ssh/authorized_keys
#install standard packages
apt -y install sudo
#check standard packages version
sudo --version
#check sudo config file exist
if [ ! -s /etc/sudoers ]; then
  echo "Error: file /etc/sudoers not found or empty"
  exit 1
fi
#add sudo group without password setting
chmod u+w /etc/sudoers
echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
chmod u-w /etc/sudoers

###finish

echo 1 > ${3}_create.result
