#!/bin/sh

#define common consts

#default user, keys
readonly COMMON_CONST_SSHKEYID=id_idax_rsa #ssh keyID, also key file name
readonly COMMON_CONST_GPGKEYID=507650DE33C7BA92EDD1569DF4F5A67BE44EEED4 #gpg keyID
readonly COMMON_CONST_SCRIPT_USER=toolsuser #default username for connect to hosts, run scripts, etc.
readonly COMMON_CONST_GIT_USER='dishmaev' #default git user
readonly COMMON_CONST_GIT_EMAIL='idax@rambler.ru' #default git email

#base tool infrastructure
readonly COMMON_CONST_SCRIPT_FILENAME=$(basename "$0") #script file name
readonly COMMON_CONST_SCRIPT_DIRNAME=$(dirname "$0") #script directory name
readonly COMMON_CONST_TOOLTIP='-y mean non-interactively with yes answer and try install missing dependencies' #simple autoyes tooltip
readonly COMMON_CONST_TOOLSREPO="git@github.com:$COMMON_CONST_GIT_USER/tools.git" #for add tools submodule
readonly COMMON_CONST_DOWNLOAD_PATH="$HOME/Downloads/$COMMON_CONST_GIT_USER-tools" #local directory to save downloads
readonly COMMON_CONST_LOCAL_OVFTOOL_PATH='/usr/lib/vmware-ovftool' #ovf tools local directory
readonly COMMON_CONST_OVFTOOL_PASS_FILE=$COMMON_CONST_SCRIPT_DIRNAME/../common/ovftoolpwd #default password, used by ovftool, password with escaped special characters using %, for instance %40 = @, %5c = \
readonly COMMON_CONST_SSH_PASS_FILE=$COMMON_CONST_SCRIPT_DIRNAME/../common/sshpwd #default password
readonly SSH_CLIENT='ssh -o StrictHostKeyChecking=no'
readonly SCP_CLIENT='scp -o StrictHostKeyChecking=no'
readonly SSH_COPY_ID="ssh-copy-id -o StrictHostKeyChecking=no -i $HOME/.ssh/${COMMON_CONST_SSHKEYID}.pub"
readonly COMMON_CONST_LINUX_APT='apt'
readonly COMMON_CONST_LINUX_RPM='rpm'

#boolean
readonly COMMON_CONST_FALSE=0 #false
readonly COMMON_CONST_TRUE=1 #true
readonly COMMON_CONST_BOOL_VALUES='0 1' #boolean value for check command value

#exit values
readonly COMMON_CONST_EXIT_ERROR=1
readonly COMMON_CONST_EXIT_SUCCESS=0
readonly COMMON_CONST_ERROR_MES_UNKNOWN='some problem occured while execute last command, details above in output'

#ci
#readonly COMMON_CONST_GITLABCE_APT_SH_URL='https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh'
#readonly COMMON_CONST_GITLABCE_RPM_SH_URL='https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh'

#vmware esxi
readonly COMMON_CONST_ESXI_HOST=esxi #DNS name main esxi host
readonly COMMON_CONST_ESXI_MAC=00:1b:21:39:9b:d4 #MAC main esxi host
readonly COMMON_CONST_ESXI_POOL_HOSTS='esxi' #esxi hosts, list with space delimiter
readonly COMMON_CONST_ESXI_DATASTORE_BASE='datastore1' #default datastore of base content: images, patches, tools
readonly COMMON_CONST_ESXI_DATASTORE_VM='datastore2' #default datastore of virtual machines on esxi host
readonly COMMON_CONST_ESXI_TOOLS_PATH="/vmfs/volumes/$COMMON_CONST_ESXI_DATASTORE_BASE/$COMMON_CONST_GIT_USER-tools" #tools directory
readonly COMMON_CONST_ESXI_IMAGES_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/images" #vm images (iso, ova, etc) directory on esxi host
readonly COMMON_CONST_ESXI_PATCHES_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/patches" #esxi patches directory on esxi host
readonly COMMON_CONST_ESXI_TEMPLATES_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/templates" #templates directory on esxi host
readonly COMMON_CONST_ESXI_DATA_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/data" #notupgradable data directory on esxi host
readonly COMMON_CONST_ESXI_OVFTOOL_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/vmware-ovftool" #ovf tools directory on esxi host
readonly COMMON_CONST_ESXI_TRY_NUM=3 #try num for long operation
readonly COMMON_CONST_ESXI_TRY_LONG=10 #one try long
readonly COMMON_CONST_ESXI_SLEEP_LONG=10 #sleep long
readonly COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME='template' #template vm snapshot name
readonly COMMON_CONST_ESXI_SNAPSHOT_PROJECT_NAME='project' #project vm snapshot name

#templates
readonly COMMON_CONST_PHOTON_VMTEMPLATE='ptn' # VMware Photon
readonly COMMON_CONST_PHOTON_VERSION='1.0' #current Photon version
readonly COMMON_CONST_PHOTON_VMTYPE="${COMMON_CONST_PHOTON_VMTEMPLATE}:${COMMON_CONST_PHOTON_VERSION}" # VMware Photon

readonly COMMON_CONST_DEBIANMINI_VMTEMPLATE='dbn' # Debian without gui
readonly COMMON_CONST_DEBIANMINI_VERSION='9.2.1' #current Debian version
readonly COMMON_CONST_DEBIANMINI_VMTYPE="${COMMON_CONST_DEBIANMINI_VMTEMPLATE}:${COMMON_CONST_DEBIANMINI_VERSION}" # Debian without gui

readonly COMMON_CONST_DEBIANGUI_VMTEMPLATE='dbngui' # Debian
readonly COMMON_CONST_DEBIANGUI_VERSION='9.1.0' #current Debian version
readonly COMMON_CONST_DEBIANGUI_VMTYPE="${COMMON_CONST_DEBIANGUI_VMTEMPLATE}:${COMMON_CONST_DEBIANGUI_VERSION}" # Debian
readonly COMMON_CONST_DEBIANGUI_VMDKXZ_URL="$COMMON_CONST_DEBIANGUI_VMTEMPLATE-$COMMON_CONST_DEBIANGUI_VERSION.vmdk.xz" #http://www.osboxes.org/debian/, unpack from 7z and pack to xz

readonly COMMON_CONST_ORACLELINUX_VMTEMPLATE='orl' #Oracle linux
readonly COMMON_CONST_ORACLELINUX_VERSION="7.4" #current Oracle linux version
readonly COMMON_CONST_ORACLELINUX_VMTYPE="${COMMON_CONST_ORACLELINUX_VMTEMPLATE}:$COMMON_CONST_ORACLELINUX_VERSION" # Oracle Linux
#readonly COMMON_CONST_LINUX_RPM_ISO_URL='http://ftp.icm.edu.pl/pub/Linux/dist/oracle-linux/OL7/u4/x86_64/OracleLinux-R7-U4-Server-x86_64-dvd.iso' #RPM-based Linux ISO url for download

readonly COMMON_CONST_FREEBSD_VMTEMPLATE='fbd' # FreeBSD
readonly COMMON_CONST_FREEBSD_VERSION='11.1' #current FreeBSD version
readonly COMMON_CONST_FREEBSD_VMTYPE="${COMMON_CONST_FREEBSD_VMTEMPLATE}:${COMMON_CONST_FREEBSD_VERSION}" # FreeBSD
readonly COMMON_CONST_FREEBSD_POOL_NAMES='freebsd64Guest' #FreeBSD pool name, list with space delimiter

readonly COMMON_CONST_LINUX_APT_POOL_NAMES='debian9_64Guest' #APT-based Linux pool name, list with space delimiter
readonly COMMON_CONST_LINUX_RPM_POOL_NAMES='oracleLinux64Guest other3xLinux64Guest' #RPM-based Linux pool name, list with space delimiter

readonly COMMON_CONST_VM_TYPES="$COMMON_CONST_PHOTON_VMTYPE $COMMON_CONST_DEBIANMINI_VMTYPE $COMMON_CONST_DEBIANGUI_VMTYPE $COMMON_CONST_ORACLELINUX_VMTYPE $COMMON_CONST_FREEBSD_VMTYPE" #support OS types for deploy on remote esxi host

#virtualbox
