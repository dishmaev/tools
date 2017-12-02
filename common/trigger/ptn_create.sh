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

echo 'iptables -A INPUT -p icmp -j ACCEPT' >> /etc/systemd/scripts/iptables

#set hostname
hostnamectl set-hostname $3
checkRetValOK
#add user
useradd -s /bin/bash --create-home $1
checkRetValOK
usermod -aG sudo $1
checkRetValOK
#set user password
echo $2 > pass1
checkRetValOK
cp pass1 pass2
checkRetValOK
cat pass1 >> pass2
checkRetValOK
cat pass2 | passwd $1
checkRetValOK
rm pass1 pass2
checkRetValOK
#check new user home directory exist
if [ ! -d /home/${1} ]; then
  echo "Error: directory /home/${1} not found"
  exit 1
fi
#create .ssh subdirectory
mkdir -m u=rwx,g=,o= /home/${1}/.ssh
checkRetValOK
chown ${1}:users /home/${1}/.ssh
checkRetValOK
#check source ssh key file exist
if [ ! -s $HOME/.ssh/authorized_keys ]; then
  echo "Error: file $HOME/.ssh/authorized_keys not found or empty"
  exit 1
fi
#copy ssh key file to target directory
cp $HOME/.ssh/authorized_keys /home/${1}/.ssh/
checkRetValOK
chown ${1}:users /home/${1}/.ssh/authorized_keys
checkRetValOK
chmod u=rw,g=,o= /home/${1}/.ssh/authorized_keys
checkRetValOK
#install standard packages
tdnf -y install sudo
checkRetValOK
#check sudo config file exist
if [ ! -s /etc/sudoers ]; then
  echo "Error: file /etc/sudoers not found or empty"
  exit 1
fi
#add sudo group without password setting
echo '%sudo ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/sudo
checkRetValOK
chmod u=r,g=r,o= /etc/sudoers.d/sudo
checkRetValOK
#install packages
tdnf -y install wget
checkRetValOK
#add personal release repository
echo -e "[dish_release_rpms]\n\
name=Dmitry Ishmaev repository (x86_64) Rel\n\
baseurl=https://dishmaev.github.io/repos/linux/rpm/release/RPMS/x86_64\n\
gpgkey=https://dishmaev.github.io/repos/linux/linux_signing_key.pub\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
enabled=1\n\
skip_if_unavailable=True" | tee /etc/yum.repos.d/public-yum-dishmaev-release.repo
checkRetValOK
#add personal testing repository
echo -e "[dish_test_rpms]\n\
name=Dmitry Ishmaev repository (x86_64) Tst\n\
baseurl=https://dishmaev.github.io/repos/linux/rpm/test/RPMS/x86_64\n\
gpgkey=https://dishmaev.github.io/repos/linux/linux_signing_key.pub\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
enabled=0\n\
skip_if_unavailable=True" | tee /etc/yum.repos.d/public-yum-dishmaev-test.repo
checkRetValOK
#add personal develop repository
echo -e "[dish_develop_rpms]\n\
name=Dmitry Ishmaev repository (x86_64) Dev\n\
baseurl=https://dishmaev.github.io/repos/linux/rpm/develop/RPMS/x86_64\n\
gpgkey=https://dishmaev.github.io/repos/linux/linux_signing_key.pub\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
enabled=0\n\
skip_if_unavailable=True" | tee /etc/yum.repos.d/public-yum-dishmaev-develop.repo
checkRetValOK

##test

#check packages version
sudo --version >&3
checkRetValOK
tdnf repolist >&3
checkRetValOK

###finish

echo 1 > ${3}_create.ok
exit 0
