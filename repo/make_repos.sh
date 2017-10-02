#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Make set of empty packages repositories for some OS: Linux (apt,rpm),
                    FreeBSD (TO-DO), Windows (TO-DO)'

##using files: ./distributions, $CONST_GPGKEY_FILENAME
##dependencies: gpg with sec key COMMON_CONST_GPGKEYID for sign, reprepro, createrepo

##private consts
CONST_STAGE_COUNT=4 #stage count
CONST_RPMCFG_FILENAME=.rpmmacros #config file for createrepo
CONST_GPGKEY_FILENAME=linux_signing_key.pub #pub key file name
CONST_REPOS_DIRNAME=repos #repos directory name

##private vars
PRM_SOURCE_DIRNAME='' #source directory name
TARGET_DIRNAME='' #target directory name

###check autoyes

checkAutoYes "$1" || shift

###help

if [ $# -eq 0 ] || [ $# -gt 2 ]
then
  echoHelp $# 1 '<source directory>' '.'
fi

###check parms

PRM_SOURCE_DIRNAME=$1
if [ -z "$PRM_SOURCE_DIRNAME" ] || [ ! -d $PRM_SOURCE_DIRNAME ]
then
  exitError "Source directory $1 missing or not exist!"
fi

TARGET_DIRNAME=$PRM_SOURCE_DIRNAME/$CONST_REPOS_DIRNAME
if [ -d $TARGET_DIRNAME ]
then
  exitError "Target directory $CONST_REPOS_DIRNAME already exist!"
fi

#check availability gpg sec key
if [ "$(gpg -K | grep $COMMON_CONST_GPGKEYID)" = "" ]
then
  exitError "GPG secret key $COMMON_CONST_GPGKEYID 'not found!"
fi

#check availability reprepro
if ! isCommandExist 'reprepro'
then
  exitError 'Reprepro not found!'
fi

#check availability createrepo
if ! isCommandExist 'createrepo'
then
  exitError 'Createrepo not found!'
fi

#check availability distributions
if [ ! -f $COMMON_CONST_SCRIPT_DIRNAME/distributions ]
then
  exitError 'Config file distributions not found!'
fi

#check availability $CONST_GPGKEY_FILENAME
if [ ! -f $COMMON_CONST_SCRIPT_DIRNAME/$CONST_GPGKEY_FILENAME ]
then
  exitError "File $CONST_GPGKEY_FILENAME not found!"
fi

###start prompt

startPrompt

###body

beginStage 1 $CONST_STAGE_COUNT 'Create base directories'
mkdir $TARGET_DIRNAME
mkdir $TARGET_DIRNAME/freebsd
mkdir $TARGET_DIRNAME/windows
mkdir $TARGET_DIRNAME/linux

mkdir $TARGET_DIRNAME/linux/apt
mkdir $TARGET_DIRNAME/linux/apt/conf

mkdir $TARGET_DIRNAME/linux/rpm
mkdir $TARGET_DIRNAME/linux/rpm/release
mkdir $TARGET_DIRNAME/linux/rpm/release/RPMS
mkdir $TARGET_DIRNAME/linux/rpm/release/RPMS/i386
mkdir $TARGET_DIRNAME/linux/rpm/release/RPMS/x86_64
mkdir $TARGET_DIRNAME/linux/rpm/release/RPMS/noarch
mkdir $TARGET_DIRNAME/linux/rpm/test
mkdir $TARGET_DIRNAME/linux/rpm/test/RPMS
mkdir $TARGET_DIRNAME/linux/rpm/test/RPMS/i386
mkdir $TARGET_DIRNAME/linux/rpm/test/RPMS/x86_64
mkdir $TARGET_DIRNAME/linux/rpm/test/RPMS/noarch
mkdir $TARGET_DIRNAME/linux/rpm/develop
mkdir $TARGET_DIRNAME/linux/rpm/develop/RPMS
mkdir $TARGET_DIRNAME/linux/rpm/develop/RPMS/i386
mkdir $TARGET_DIRNAME/linux/rpm/develop/RPMS/x86_64
mkdir $TARGET_DIRNAME/linux/rpm/develop/RPMS/noarch
doneStage

beginStage 2 $CONST_STAGE_COUNT 'Create config files, symlinks'

cp $COMMON_CONST_SCRIPT_DIRNAME/$CONST_GPGKEY_FILENAME $TARGET_DIRNAME/linux/
cat $COMMON_CONST_SCRIPT_DIRNAME/distributions | sed -e "s#@COMMON_CONST_GPGKEYID@#$COMMON_CONST_GPGKEYID#" > $TARGET_DIRNAME/linux/apt/conf/distributions

if [ ! -f ~/$CONST_RPMCFG_FILENAME ]
then
  echo '%_signature gpg' > ~/$CONST_RPMCFG_FILENAME
  echo '%_gpg_name' $COMMON_CONST_GPGKEYID >> ~/$CONST_RPMCFG_FILENAME
else
  SG=$(grep '%_signature gpg' ~/$CONST_RPMCFG_FILENAME)
  if [ "$SG" = "" ]
  then
    echo '%_signature gpg' >> ~/$CONST_RPMCFG_FILENAME
  fi
  GN=$(grep '%_gpg_name' ~/$CONST_RPMCFG_FILENAME)
  if [ "$GN" = "" ]
  then
    echo '%_gpg_name' $COMMON_CONST_GPGKEYID >> ~/$CONST_RPMCFG_FILENAME
  fi
fi
doneStage

beginStage 3 $CONST_STAGE_COUNT 'Run reprepro for initialize APT-based system packages repository structure'
reprepro -b $TARGET_DIRNAME/linux/apt check
reprepro -b $TARGET_DIRNAME/linux/apt export
reprepro -b $TARGET_DIRNAME/linux/apt createsymlinks
doneStage

beginStage 4 $CONST_STAGE_COUNT 'Run createrepo for initialize RPM-based system packages repository structure'
createrepo -q $TARGET_DIRNAME/linux/rpm/release/RPMS/i386
gpg --detach-sign --armor $TARGET_DIRNAME/linux/rpm/release/RPMS/i386/repodata/repomd.xml
createrepo -q $TARGET_DIRNAME/linux/rpm/release/RPMS/x86_64
gpg --detach-sign --armor $TARGET_DIRNAME/linux/rpm/release/RPMS/x86_64/repodata/repomd.xml
createrepo -q $TARGET_DIRNAME/linux/rpm/release/RPMS/noarch
gpg --detach-sign --armor $TARGET_DIRNAME/linux/rpm/release/RPMS/noarch/repodata/repomd.xml
createrepo -q $TARGET_DIRNAME/linux/rpm/test/RPMS/i386
gpg --detach-sign --armor $TARGET_DIRNAME/linux/rpm/test/RPMS/i386/repodata/repomd.xml
createrepo -q $TARGET_DIRNAME/linux/rpm/test/RPMS/x86_64
gpg --detach-sign --armor $TARGET_DIRNAME/linux/rpm/test/RPMS/x86_64/repodata/repomd.xml
createrepo -q $TARGET_DIRNAME/linux/rpm/test/RPMS/noarch
gpg --detach-sign --armor $TARGET_DIRNAME/linux/rpm/test/RPMS/noarch/repodata/repomd.xml
createrepo -q $TARGET_DIRNAME/linux/rpm/develop/RPMS/i386
gpg --detach-sign --armor $TARGET_DIRNAME/linux/rpm/develop/RPMS/i386/repodata/repomd.xml
createrepo -q $TARGET_DIRNAME/linux/rpm/develop/RPMS/x86_64
gpg --detach-sign --armor $TARGET_DIRNAME/linux/rpm/develop/RPMS/x86_64/repodata/repomd.xml
createrepo -q $TARGET_DIRNAME/linux/rpm/develop/RPMS/noarch
gpg --detach-sign --armor $TARGET_DIRNAME/linux/rpm/develop/RPMS/noarch/repodata/repomd.xml
doneFinalStage

echo 'Now publish keys for repository access:'
echo '1)For Linux is' $TARGET_DIRNAME'/linux/'$CONST_GPGKEY_FILENAME
echo '2)For FreeBSD is' $TARGET_DIRNAME'/freebsd/TO-DO'
echo '3)For Windows is' $TARGET_DIRNAME'/windows/TO-DO'

exitOK
