#!/bin/sh

#define common consts

#default project, user, keys
readonly COMMON_CONST_ROOT_DIR=/home/dmitry/Projects/tools #set correct path before using this tools

readonly COMMON_CONST_PROJECTNAME='MYPROJ' #project name
readonly COMMON_CONST_SSH_KEYID=id_idax_rsa #ssh keyID, also key file name in ~/.ssh/
readonly COMMON_CONST_SCRIPT_USER=toolsuser #default username for connect to hosts, run scripts, etc.
readonly COMMON_CONST_SSH_USERPASS=$COMMON_CONST_ROOT_DIR/common/sshpwd.txt #file with default password for $COMMON_CONST_SCRIPT_USER
readonly COMMON_CONST_GPG_KEYID=507650DE33C7BA92EDD1569DF4F5A67BE44EEED4 #gpg keyID
readonly COMMON_CONST_GIT_USERNAME='dishmaev' #default git user
readonly COMMON_CONST_GIT_USEREMAIL='idax@rambler.ru' #default git email

#base tool infrastructure
readonly COMMON_CONST_SCRIPT_FILENAME=$(basename "$0") #script file name
readonly COMMON_CONST_SCRIPT_DIRNAME=$(dirname "$0") #script directory name
readonly COMMON_CONST_TOOLTIP='-y mean non-interactively with yes answer and try install missing dependencies' #simple autoyes tooltip
readonly COMMON_CONST_TOOLSREPO="git@github.com:$COMMON_CONST_GIT_USERNAME/tools.git" #for add tools submodule
readonly COMMON_CONST_DOWNLOAD_PATH="$COMMON_CONST_ROOT_DIR/downloads" #local directory to save downloads
readonly COMMON_CONST_LOCAL_OVFTOOL_PATH='/usr/lib/vmware-ovftool' #ovf tools local directory
readonly COMMON_CONST_OVFTOOL_PASS_FILE=$COMMON_CONST_ROOT_DIR/common/ovftoolpwd.txt #default password, used by ovftool, password with escaped special characters using %, for instance %40 = @, %5c = \
readonly COMMON_CONST_VMTOOLS_FILE='VMware-Tools-10.1.10-other-6082533.tar.gz' #vmware tools archive file name
readonly COMMON_CONST_LOCAL_VMTOOLS_PATH="$COMMON_CONST_DOWNLOAD_PATH/$COMMON_CONST_VMTOOLS_FILE" #vmware tools local directory
readonly COMMON_CONST_LINUX_APT='apt'
readonly COMMON_CONST_LINUX_RPM='rpm'
readonly COMMON_CONST_DEFAULT_VERSION='default' # default version name
readonly COMMON_CONST_DEFAULT_VMNAME='autogen' # default vm name
readonly COMMON_CONST_DATA_TXT_SEPARATOR='::' #default separator for data files

#aliases
readonly SSH_CLIENT="ssh -o StrictHostKeyChecking=no -o User=$COMMON_CONST_SCRIPT_USER"
readonly SCP_CLIENT="scp -o StrictHostKeyChecking=no -o User=$COMMON_CONST_SCRIPT_USER"
readonly SSH_COPY_ID="ssh-copy-id -o StrictHostKeyChecking=no -i $HOME/.ssh/${COMMON_CONST_SSH_KEYID}.pub"

#boolean
readonly COMMON_CONST_FALSE=0 #false
readonly COMMON_CONST_TRUE=1 #true
readonly COMMON_CONST_BOOL_VALUES="$COMMON_CONST_FALSE $COMMON_CONST_TRUE" #boolean value for check command value

#exit values
readonly COMMON_CONST_EXIT_ERROR=1
readonly COMMON_CONST_EXIT_SUCCESS=0
readonly COMMON_CONST_ERROR_MESS_UNKNOWN='some problem occured while execute last command, details above in output'

#incorp infrastructure
readonly COMMON_CONST_INCORP_MAILSERVER_HOST='mail'
readonly COMMON_CONST_INCORP_CISERVER_HOST='ci'
readonly COMMON_CONST_INCORP_RUNNERSERVER_PREFIX_HOST="${COMMON_CONST_INCORP_CISERVER_HOST}runner"

#vm templates
readonly COMMON_CONST_PHOTON_VMTEMPLATE='ptn' # VMware Photon
readonly COMMON_CONST_DEBIANMINI_VMTEMPLATE='dbn' # Debian without gui from iso image
readonly COMMON_CONST_DEBIANOSB_VMTEMPLATE='dbnosb' # Debian from www.osboxes.org
readonly COMMON_CONST_ORACLELINUXMINI_VMTEMPLATE='orl' #Oracle linux without gui from iso image
readonly COMMON_CONST_ORACLELINUXBOX_VMTEMPLATE='orlbox' #Oracle linux from box package for Virtual Box
readonly COMMON_CONST_ORACLESOLARISMINI_VMTEMPLATE='ors' #Oracle Solaris without gui from iso image
readonly COMMON_CONST_ORACLESOLARISBOX_VMTEMPLATE='orsbox' #Oracle Solaris from ova package for Virtual Box
readonly COMMON_CONST_FREEBSD_VMTEMPLATE='fbd' # FreeBSD

readonly COMMON_CONST_VMTEMPLATES_POOL="\
$COMMON_CONST_PHOTON_VMTEMPLATE \
$COMMON_CONST_DEBIANMINI_VMTEMPLATE \
$COMMON_CONST_DEBIANOSB_VMTEMPLATE \
$COMMON_CONST_ORACLELINUXMINI_VMTEMPLATE \
$COMMON_CONST_ORACLELINUXBOX_VMTEMPLATE \
$COMMON_CONST_ORACLESOLARISMINI_VMTEMPLATE \
$COMMON_CONST_ORACLESOLARISBOX_VMTEMPLATE \
$COMMON_CONST_FREEBSD_VMTEMPLATE" # available vm templates pool

#vm types
readonly COMMON_CONST_VMWARE_VMTYPE='ex' #Vmware
readonly COMMON_CONST_DOCKER_VMTYPE='dc' #Docker
readonly COMMON_CONST_VAGRANT_VMTYPE='vg' #Vagrant

readonly COMMON_CONST_VMTYPES_POOL="\
$COMMON_CONST_VMWARE_VMTYPE \
$COMMON_CONST_DOCKER_VMTYPE \
$COMMON_CONST_VAGRANT_VMTYPE"

#suites
readonly COMMON_CONST_RELEASE_SUITE='rel' #release
readonly COMMON_CONST_TEST_SUITE='tst' #test
readonly COMMON_CONST_DEVELOP_SUITE='dev' #develop

readonly COMMON_CONST_SUITES_POOL="\
$COMMON_CONST_DEVELOP_SUITE \
$COMMON_CONST_TEST_SUITE \
$COMMON_CONST_RELEASE_SUITE"

#ci
#readonly COMMON_CONST_GITLABCE_APT_SH_URL='https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh'
#readonly COMMON_CONST_GITLABCE_RPM_SH_URL='https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh'

#vmware esxi
readonly COMMON_CONST_ESXI_HOST=esxi #DNS name main esxi host
readonly COMMON_CONST_ESXI_MAC=00:1b:21:39:9b:d4 #MAC main esxi host
readonly COMMON_CONST_ESXI_MACS_POOL="$COMMON_CONST_ESXI_MAC" #mac esxi hosts, list with space delimiter
readonly COMMON_CONST_ESXI_HOSTS_POOL="$COMMON_CONST_ESXI_HOST" #esxi hosts, list with space delimiter
readonly COMMON_CONST_ESXI_DATASTORE_BASE='datastore1' #default datastore of base content: images, patches, tools
readonly COMMON_CONST_ESXI_DATASTORE_VM='datastore2' #default datastore of virtual machines on esxi host
readonly COMMON_CONST_ESXI_TOOLS_PATH="/vmfs/volumes/$COMMON_CONST_ESXI_DATASTORE_BASE/$COMMON_CONST_GIT_USERNAME-tools" #tools directory
readonly COMMON_CONST_ESXI_IMAGES_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/images" #vm images (iso, ova, etc) directory on esxi host
readonly COMMON_CONST_ESXI_PATCHES_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/patches" #esxi patches directory on esxi host
readonly COMMON_CONST_ESXI_TEMPLATES_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/templates" #templates directory on esxi host
readonly COMMON_CONST_ESXI_DATA_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/data" #notupgradable data directory on esxi host
readonly COMMON_CONST_ESXI_OVFTOOL_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/vmware-ovftool" #ovf tools directory on esxi host
readonly COMMON_CONST_ESXI_VMTOOLS_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/vmtools" #vmware tools directory on esxi host
readonly COMMON_CONST_ESXI_TRY_NUM=3 #try num for long operation
readonly COMMON_CONST_ESXI_TRY_LONG=15 #one try long
readonly COMMON_CONST_ESXI_SLEEP_LONG=10 #sleep long
readonly COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME='template' #template vm snapshot name

#readonly COMMON_CONST_ESXI_LINUX_APT_VMTYPES_POOL='debian9_64Guest' #APT-based Linux vm types pool, list with space delimiter
#readonly COMMON_CONST_ESXI_LINUX_RPM_VMTYPES_POOL='oracleLinux64Guest other3xLinux64Guest' #RPM-based Linux vm types pool, list with space delimiter
#readonly COMMON_CONST_ESXI_FREEBSD_VMTYPES_POOL='freebsd64Guest' #FreeBSD vm types pool, list with space delimiter

#virtualbox
