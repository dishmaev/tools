#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Make set of empty packages repositories for some OS: Linux (apt,rpm),
                    FreeBSD (TO-DO), Windows (TO-DO)'

##private consts
readonly CONST_STAGE_COUNT=4 #stage count
readonly CONST_RPMCFG_FILENAME=.rpmmacros #config file for createrepo
readonly CONST_GPGKEY_FILENAME=linux_signing_key.pub #pub key file name
readonly CONST_REPOS_DIRNAME=repos #repos directory name

##private vars
PRM_SOURCE_DIRNAME='' #source directory name
TARGET_DIRNAME='' #target directory name

###check autoyes

checkAutoYes "$1" || shift

###help

if [ $# -eq 0 ] || [ $# -gt 2 ]
then
  echoHelp $# 1 '<source directory>' '.' 'Required gpg secret keyID'
fi

###check commands

PRM_SOURCE_DIRNAME=$1

checkDirectoryForExist "$PRM_SOURCE_DIRNAME" 'source '

TARGET_DIRNAME=$PRM_SOURCE_DIRNAME/$CONST_REPOS_DIRNAME
checkDirectoryForNotExist "$TARGET_DIRNAME" 'target '

###check body dependencies

checkDependencies 'mktemp reprepro createrepo'

#check availability gpg sec key
checkGpgSecKeyExist $COMMON_CONST_GPG_KEYID

###check required files

checkRequiredFiles "$COMMON_CONST_SCRIPT_DIRNAME/distributions"

###start prompt

startPrompt

###body
#new stage
beginStage $CONST_STAGE_COUNT 'Create base directories'
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
#new stage
beginStage $CONST_STAGE_COUNT 'Create keys, config files, symlinks'

gpg -q --export --armor --output $TARGET_DIRNAME/linux/$CONST_GPGKEY_FILENAME $COMMON_CONST_GPG_KEYID
cat $COMMON_CONST_SCRIPT_DIRNAME/distributions | sed -e "s#@COMMON_CONST_GPG_KEYID@#$COMMON_CONST_GPG_KEYID#" > $TARGET_DIRNAME/linux/apt/conf/distributions

if [ ! -f ~/$CONST_RPMCFG_FILENAME ]
then
  echo '%_signature gpg' > ~/$CONST_RPMCFG_FILENAME
  echo '%_gpg_name' $COMMON_CONST_GPG_KEYID >> ~/$CONST_RPMCFG_FILENAME
else
  VAR_SG=$(grep '%_signature gpg' ~/$CONST_RPMCFG_FILENAME) || exitChildError "$VAR_SG"
  if [ "$VAR_SG" = "" ]
  then
    echo '%_signature gpg' >> ~/$CONST_RPMCFG_FILENAME
  fi
  VAR_GN=$(grep '%_gpg_name' ~/$CONST_RPMCFG_FILENAME) || exitChildError "$VAR_GN"
  if [ "$VAR_GN" = "" ]
  then
    echo '%_gpg_name' $COMMON_CONST_GPG_KEYID >> ~/$CONST_RPMCFG_FILENAME
  fi
fi
doneStage
#new stage
beginStage $CONST_STAGE_COUNT 'Run reprepro for initialize APT-based system packages repository structure'
reprepro -b $TARGET_DIRNAME/linux/apt check
reprepro -b $TARGET_DIRNAME/linux/apt export
reprepro -b $TARGET_DIRNAME/linux/apt createsymlinks
doneStage
#new stage
beginStage $CONST_STAGE_COUNT 'Run createrepo for initialize RPM-based system packages repository structure'
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

echo ''
echo 'Now publish keys for repository access:'
echo '1)For Linux is' $TARGET_DIRNAME'/linux/'$CONST_GPGKEY_FILENAME
echo '2)For FreeBSD is' $TARGET_DIRNAME'/freebsd/TO-DO'
echo '3)For Windows is' $TARGET_DIRNAME'/windows/TO-DO'

exitOK
