#!/bin/sh

#define common consts

#default user, keys
readonly COMMON_CONST_SSHKEYID=id_idax_rsa #ssh keyID
readonly COMMON_CONST_GPGKEYID=507650DE33C7BA92EDD1569DF4F5A67BE44EEED4 #gpg keyID
readonly COMMON_CONST_USER=dmitry #default username for connect to hosts, run scripts, etc.
readonly COMMON_CONST_PREFIX=dishmaev #default prefix for tools directories
readonly COMMON_CONST_OVF_USERPASSWORD=ovftool:O%40nXmRZ #format user:password, where %40 is symbol '@', user must be host administrator

#base tool infrastructure
readonly COMMON_CONST_SCRIPT_FILENAME=$(basename "$0") #script file name
readonly COMMON_CONST_SCRIPT_DIRNAME=$(dirname "$0") #script directory name
readonly COMMON_CONST_TOOLTIP='-y mean non-interactively with yes answer and try install missing dependencies' #simple autoyes tooltip
readonly COMMON_CONST_TOOLSREPO=git@github.com:dishmaev/tools.git #for add tools submodule
readonly COMMON_CONST_DOWNLOAD_PATH="$HOME/Downloads" #user directory to save downloads
readonly COMMON_CONST_LOCAL_OVFTOOL_PATH='/usr/lib/vmware-ovftool' #ovf tools local directory

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

#hypervisor
readonly COMMON_CONST_HVHOST=esxi #DNS name main hypervisor host
readonly COMMON_CONST_HVMAC=00:1b:21:39:9b:d4 #MAC main hypervisor host
#readonly COMMON_CONST_FREEBSD_ISO_URL='https://download.freebsd.org/ftp/releases/ISO-IMAGES/11.1/FreeBSD-11.1-RELEASE-amd64-disc1.iso' #FreeBSD ISO url for download
readonly COMMON_CONST_PHOTON_VERSION='1.0' #photon version
readonly COMMON_CONST_DEBIAN_VERSION='9.1.0' #debian version
readonly COMMON_CONST_ORACLELINUX_VERSION='7.4' #oracle linux version
readonly COMMON_CONST_FREEBSD_VERSION='11.1' #freebsd version
readonly COMMON_CONST_PHOTON_OVA_URL="https://bintray.com/vmware/photon/download_file?file_path=photon-custom-hw11-$COMMON_CONST_PHOTON_VERSION-62c543d.ova"
#readonly COMMON_CONST_LINUX_APT_ISO_URL='https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-9.2.0-amd64-netinst.iso' #APT-based Linux ISO url for download
#readonly COMMON_CONST_LINUX_RPM_ISO_URL='http://ftp.icm.edu.pl/pub/Linux/dist/oracle-linux/OL7/u4/x86_64/OracleLinux-R7-U4-Server-x86_64-dvd.iso' #RPM-based Linux ISO url for download
readonly COMMON_CONST_DEBIAN_VMDK_URL='Debian_9.1.0_(64bit).vmdk'
readonly COMMON_CONST_FREEBSD_VMDKXZ_URL="https://download.freebsd.org/ftp/releases/VM-IMAGES/$COMMON_CONST_FREEBSD_VERSION-RELEASE/amd64/Latest/FreeBSD-$COMMON_CONST_FREEBSD_VERSION-RELEASE-amd64.vmdk.xz"
readonly COMMON_CONST_HV_POOL_HOSTS='esxi' #hypervisor hosts, list with space delimiter
readonly COMMON_CONST_VMTYPE_PHOTON='ptn' # VMware Photon
readonly COMMON_CONST_VMTYPE_DEBIAN='dbn' # Debian
readonly COMMON_CONST_VMTYPE_ORACLELINUX='orl' # Oracle Linux
readonly COMMON_CONST_VMTYPE_FREEBSD='fbd' # FreeBSD
readonly COMMON_CONST_VM_TYPES="$COMMON_CONST_VMTYPE_PHOTON $COMMON_CONST_VMTYPE_DEBIAN $COMMON_CONST_VMTYPE_ORACLELINUX $COMMON_CONST_VMTYPE_FREEBSD" #support OS types for deploy on remote esxi host
readonly COMMON_CONST_LINUX_APT_POOL_NAMES='debian8_64Guest' #APT-based Linux pool name, list with space delimiter
readonly COMMON_CONST_LINUX_RPM_POOL_NAMES='oracleLinux64Guest' #RPM-based Linux pool name, list with space delimiter
readonly COMMON_CONST_FREEBSD_POOL_NAMES='freebsd64Guest' #FreeBSD pool name, list with space delimiter
readonly COMMON_CONST_HV_DATASTORE_BASE='datastore1' #default datastore of base content: images, patches, tools
readonly COMMON_CONST_HV_DATASTORE_VM='datastore2' #default datastore of virtual machines on esxi host
readonly COMMON_CONST_HV_TOOLS_PATH="/vmfs/volumes/$COMMON_CONST_HV_DATASTORE_BASE/$COMMON_CONST_PREFIX-tools" #tools directory
readonly COMMON_CONST_HV_IMAGES_PATH="$COMMON_CONST_HV_TOOLS_PATH/images" #vm images (iso, ova, etc) directory on esxi host
readonly COMMON_CONST_HV_PATCHES_PATH="$COMMON_CONST_HV_TOOLS_PATH/patches" #esxi patches directory on esxi host
readonly COMMON_CONST_HV_SCRIPTS_PATH="$COMMON_CONST_HV_TOOLS_PATH/scripts" #scripts directory on esxi host
readonly COMMON_CONST_HV_DATA_PATH="$COMMON_CONST_HV_TOOLS_PATH/data" #notupgradable data directory on esxi host
readonly COMMON_CONST_HV_OVFTOOL_PATH="$COMMON_CONST_HV_TOOLS_PATH/vmware-ovftool" #ovf tools directory on esxi host
