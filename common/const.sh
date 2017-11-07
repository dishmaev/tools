#!/bin/sh

#define common consts

readonly COMMON_CONST_GPG_KEYID='507650DE33C7BA92EDD1569DF4F5A67BE44EEED4' #gpg keyID

#boolean
readonly COMMON_CONST_FALSE=0 #false
readonly COMMON_CONST_TRUE=1 #true
readonly COMMON_CONST_BOOL_VALUES="$COMMON_CONST_FALSE $COMMON_CONST_TRUE" #boolean value for check command value

#exit values
readonly COMMON_CONST_EXIT_ERROR=1
readonly COMMON_CONST_EXIT_SUCCESS=0
readonly COMMON_CONST_ERROR_MESS_UNKNOWN='some problem occured while execute last command, details above in output'

#base tool infrastructure
readonly COMMON_CONST_TOOL_TIP='-y batch mode with yes answer' #simple autoyes tooltip
readonly COMMON_CONST_LOCAL_OVFTOOL_PATH='/usr/lib/vmware-ovftool' #ovf tools local directory
readonly COMMON_CONST_VMTOOLS_FILE_NAME='VMware-Tools-10.1.10-other-6082533.tar.gz' #vmware tools archive file name
readonly COMMON_CONST_LINUX_APT='apt'
readonly COMMON_CONST_LINUX_RPM='rpm'
readonly COMMON_CONST_DEFAULT_VERSION='default' # default version name
readonly COMMON_CONST_DEFAULT_VM_ROLE='main' # default version name
readonly COMMON_CONST_DEFAULT_VM_NAME='autogen' # default vm name
readonly COMMON_CONST_DATA_TXT_SEPARATOR='::' #default separator for data files
readonly COMMON_CONST_SHOW_DEBUG="$COMMON_CONST_TRUE" #show trace when error

#incorp infrastructure
readonly COMMON_CONST_INCORP_MAILSERVER_HOST='mail'
readonly COMMON_CONST_INCORP_CISERVER_HOST='ci'
readonly COMMON_CONST_INCORP_RUNNERSERVER_PREFIX_HOST="${COMMON_CONST_INCORP_CISERVER_HOST}runner"

#vm templates
readonly COMMON_CONST_PHOTON_VM_TEMPLATE='ptn' # VMware Photon
readonly COMMON_CONST_DEBIANMINI_VM_TEMPLATE='dbn' # Debian without gui from iso image
readonly COMMON_CONST_DEBIANOSB_VM_TEMPLATE='dbnosb' # Debian from www.osboxes.org
readonly COMMON_CONST_ORACLELINUXMINI_VM_TEMPLATE='orl' #Oracle linux without gui from iso image
readonly COMMON_CONST_ORACLELINUXBOX_VM_TEMPLATE='orlbox' #Oracle linux from box package for Virtual Box
readonly COMMON_CONST_ORACLESOLARISMINI_VM_TEMPLATE='ors' #Oracle Solaris without gui from iso image
readonly COMMON_CONST_ORACLESOLARISBOX_VM_TEMPLATE='orsbox' #Oracle Solaris from ova package for Virtual Box
readonly COMMON_CONST_FREEBSD_VM_TEMPLATE='fbd' # FreeBSD

readonly COMMON_CONST_VM_TEMPLATES_POOL="\
$COMMON_CONST_PHOTON_VM_TEMPLATE \
$COMMON_CONST_DEBIANMINI_VM_TEMPLATE \
$COMMON_CONST_DEBIANOSB_VM_TEMPLATE \
$COMMON_CONST_ORACLELINUXMINI_VM_TEMPLATE \
$COMMON_CONST_ORACLELINUXBOX_VM_TEMPLATE \
$COMMON_CONST_ORACLESOLARISMINI_VM_TEMPLATE \
$COMMON_CONST_ORACLESOLARISBOX_VM_TEMPLATE \
$COMMON_CONST_FREEBSD_VM_TEMPLATE" # available vm templates pool

#vm types
readonly COMMON_CONST_VMWARE_VM_TYPE='ex' #Vmware
readonly COMMON_CONST_DOCKER_VM_TYPE='dc' #Docker
readonly COMMON_CONST_VAGRANT_VM_TYPE='vg' #Vagrant

readonly COMMON_CONST_VMTYPES_POOL="\
$COMMON_CONST_VMWARE_VM_TYPE \
$COMMON_CONST_DOCKER_VM_TYPE \
$COMMON_CONST_VAGRANT_VM_TYPE"

#suites
readonly COMMON_CONST_RELEASE_SUITE='rel' #release
readonly COMMON_CONST_TEST_SUITE='tst' #test
readonly COMMON_CONST_DEVELOP_SUITE='dev' #develop
readonly COMMON_CONST_RUNNER_SUITE='run' #runner, for build of project

readonly COMMON_CONST_SUITES_POOL="\
$COMMON_CONST_DEVELOP_SUITE \
$COMMON_CONST_TEST_SUITE \
$COMMON_CONST_RELEASE_SUITE \
$COMMON_CONST_RUNNER_SUITE"

#ci
#readonly COMMON_CONST_GITLABCE_APT_SH_URL='https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh'
#readonly COMMON_CONST_GITLABCE_RPM_SH_URL='https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh'

#vmware esxi
readonly COMMON_CONST_ESXI_HOST=esxi #DNS name main esxi host
readonly COMMON_CONST_ESXI_MAC=00:1b:21:39:9b:d4 #MAC main esxi host
readonly COMMON_CONST_ESXI_MACS_POOL="$COMMON_CONST_ESXI_MAC" #mac esxi hosts, list with space delimiter
readonly COMMON_CONST_ESXI_HOSTS_POOL="$COMMON_CONST_ESXI_HOST" #esxi hosts, list with space delimiter
readonly COMMON_CONST_ESXI_BASE_DATASTORE='datastore1' #default datastore of base content: images, patches, tools
readonly COMMON_CONST_ESXI_VM_DATASTORE='datastore2' #default datastore of virtual machines on esxi host
readonly COMMON_CONST_ESXI_TOOLS_PATH="/vmfs/volumes/$COMMON_CONST_ESXI_BASE_DATASTORE/tools" #tools directory
readonly COMMON_CONST_ESXI_IMAGES_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/image" #vm images (iso, ova, etc) directory on esxi host
readonly COMMON_CONST_ESXI_PATCHES_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/patch" #esxi patches directory on esxi host
readonly COMMON_CONST_ESXI_TEMPLATES_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/template" #templates directory on esxi host
readonly COMMON_CONST_ESXI_DATA_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/data" #notupgradable data directory on esxi host
readonly COMMON_CONST_ESXI_OVFTOOL_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/vmware-ovftool" #ovf tools directory on esxi host
readonly COMMON_CONST_ESXI_VMTOOLS_PATH="$COMMON_CONST_ESXI_TOOLS_PATH/vmtool" #vmware tools directory on esxi host
readonly COMMON_CONST_ESXI_TRY_NUM=3 #try num for long operation
readonly COMMON_CONST_ESXI_TRY_LONG=15 #one try long
readonly COMMON_CONST_ESXI_SLEEP_LONG=10 #sleep long
readonly COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME='template' #template vm snapshot name

#readonly COMMON_CONST_ESXI_LINUX_APT_VMTYPES_POOL='debian9_64Guest' #APT-based Linux vm types pool, list with space delimiter
#readonly COMMON_CONST_ESXI_LINUX_RPM_VMTYPES_POOL='oracleLinux64Guest other3xLinux64Guest' #RPM-based Linux vm types pool, list with space delimiter
#readonly COMMON_CONST_ESXI_FREEBSD_VMTYPES_POOL='freebsd64Guest' #FreeBSD vm types pool, list with space delimiter

#virtualbox
