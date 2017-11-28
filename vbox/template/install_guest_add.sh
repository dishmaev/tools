#!/bin/sh

###header

##private consts
readonly CONST_FALSE=0 #false
readonly CONST_TRUE=1 #true
readonly CONST_LINUX_APT='apt'
readonly CONST_LINUX_RPM='rpm'

##private vars
VAR_LINUX_BASED=''

###function

isEmpty()
{
  [ -z "$1" ]
}

isFileExistAndRead() {
  ! isEmpty "$1" && [ -r "$1" ]
}

checkLinuxAptOrRpm(){
  if isFileExistAndRead "/etc/debian_version"; then
    echo "$CONST_LINUX_APT"
  elif isFileExistAndRead "/etc/redhat-release"; then
    echo "$CONST_LINUX_RPM"
  else
    echo "unknown Linux based package system"
    exit 1
  fi
}

isTrue(){
  [ "$1" = "$CONST_TRUE" ]
}

isLinuxOS(){
  [ "$(uname)" = "Linux" ]
}

isAPTLinux()
{
  [ "$1" = "$CONST_LINUX_APT" ]
}

isRPMLinux()
{
  [ "$1" = "$CONST_LINUX_RPM" ]
}

isFreeBSDOS(){
  [ "$(uname)" = "FreeBSD" ]
}

checkRetValOK(){
  if [ "$?" != "0" ]; then exit 1; fi
}

exitError(){
  if [ ! -z "$1" ]; then
    echo "Error:" $1
  fi
  echo ''
  echo 'Exit with error!'
  exit 1;
}
###body

if ! isLinuxOS; then exitError 'not supported OS'; fi
VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitError "$VAR_LINUX_BASED"

if [ ! -e /dev/cdrom ]; then exitError 'CD-ROM not found'; fi
if [ -d /media/cdrom ]; then exitError 'directory /media/cdrom already exist'; fi

sudo mkdir /media/cdrom
checkRetValOK
sudo mount /dev/cdrom /media/cdrom -o loop
checkRetValOK

if isAPTLinux "$VAR_LINUX_BASED"; then
  sudo apt -y install build-essential dkms
elif isRPMLinux "$VAR_LINUX_BASED"; then
  sudo yum -y install gcc kernel-devel
  checkRetValOK
fi

cd /media/cdrom

sudo sh VBoxLinuxAdditions.run
checkRetValOK

cd $HOME

sudo umount /media/cdrom
sudo rmdir /media/cdrom

exit 0
