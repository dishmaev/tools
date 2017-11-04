#!/bin/sh

#$1 $COMMON_CONST_SSH_USER_NAME, $2 password for user, $3 vm name, $4 vm OS version

if [ "$#" != "4" ]; then exit 1; fi
if [ -f ${3}_create.result ]; then rm ${3}_create.result; fi
exec 1>${3}_create.log
exec 2>${3}_create.err
echo "VM $3 OS version:" $4

###body

#set hostname
hostname "${3}"
echo "hostname \"${3}\"" >> /etc/rc.conf
#add user
pw useradd -m -d /home/$1 -n $1
pw groupadd sudo
pw groupmod sudo -m $1
#set user password
echo $2 | pw mod user $1 -h 0
#check new user home directory exist
if [ ! -d /home/${1} ]; then
  echo "Error: directory /home/${1} not found"
  exit 1
fi
#create .ssh subdirectory
mkdir -m u=rwx,g=,o= /home/${1}/.ssh
chown ${1}:${1} /home/${1}/.ssh
#check source ssh key file exist
if [ ! -s $HOME/.ssh/authorized_keys ]; then
  echo "Error: file $HOME/.ssh/authorized_keys not found or empty"
  exit 1
fi
#copy ssh key file to target directory
cp $HOME/.ssh/authorized_keys /home/${1}/.ssh/
chown $1 /home/${1}/.ssh/authorized_keys
chmod u=rw,g=,o= /home/${1}/.ssh/authorized_keys
#install standard packages
export ASSUME_ALWAYS_YES=yes
pkg install sudo
export ASSUME_ALWAYS_YES=
#check standard packages version
sudo --version
#check sudo config file exist
if [ ! -s /usr/local/etc/sudoers ]; then
  echo "Error: file /usr/local/etc/sudoers not found or empty"
  exit 1
fi
#add sudo group without password setting
chmod u+w /usr/local/etc/sudoers
echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /usr/local/etc/sudoers
chmod u-w /usr/local/etc/sudoers

###finish

echo 1 > ${3}_create.result
