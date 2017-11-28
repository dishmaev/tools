#!/bin/sh

###header

readonly VAR_PARAMETERS='$1 $ENV_SSH_USER_NAME, $2 password for user, $3 vm name, $4 vm OS version'

if [ "$#" != "4" ]; then echo "Call syntax: $(basename "$0") $VAR_PARAMETERS"; exit 1; fi
if [ -r ${3}_create.ok ]; then rm ${3}_create.ok; fi
exec 1>${3}_create.log
exec 2>${3}_create.err
echo "VM $3 OS version:" $4

###function

checkRetValOK(){
  if [ "$?" != "0" ]; then exit 1; fi
}

###body

#set hostname
hostnamectl set-hostname $3
#add user
useradd -s /bin/bash --create-home $1;
groupadd sudo;
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
#check sudo config file exist
if [ ! -s /etc/sudoers ]; then
  echo "Error: file /etc/sudoers not found or empty"
  exit 1
fi
#add sudo group without password setting
chmod u+w /etc/sudoers
echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
chmod u-w /etc/sudoers
#install packages
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
yum -y install yum-utils
#add personal repository
rpm --import https://dishmaev.github.io/repos/linux/linux_signing_key.pub
yum-config-manager --add-repo https://dishmaev.github.io/public-yum-dishmaev.repo

##test

#check packages version
sudo --version
yum-config-manager --version
yum --nogpgcheck repolist

###finish

echo 1 > ${3}_create.ok
exit 0