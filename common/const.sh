#!/bin/sh

#define common consts

#default user, keys
readonly COMMON_CONST_SSHKEYID=id_idax_rsa #ssh keyID
readonly COMMON_CONST_GPGKEYID=507650DE33C7BA92EDD1569DF4F5A67BE44EEED4 #gpg keyID
readonly COMMON_CONST_USER=dmitry #default username for connect to hosts, run scripts, etc.

#base tool infrastructure
readonly COMMON_CONST_SCRIPT_FILENAME=$(basename "$0") #script file name
readonly COMMON_CONST_SCRIPT_DIRNAME=$(dirname "$0") #script directory name
readonly COMMON_CONST_TOOLTIP='-y mean non-interactively with yes answer and try install missing dependencies' #simple autoyes tooltip
readonly COMMON_CONST_TOOLSREPO=git@github.com:dishmaev/tools.git #for add tools submodule

#boolean
readonly COMMON_CONST_FALSE=0 #false
readonly COMMON_CONST_TRUE=1 #true
readonly COMMON_CONST_BOOL_VALUE='0 1' #boolean value for check command value
#ci
readonly COMMON_CONST_GITLABCE_APT_SH_URL='https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh'
readonly COMMON_CONST_GITLABCE_RPM_SH_URL='https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh'

#hypervisor
readonly COMMON_CONST_HVHOST=esxi #DNS name main hypervisor host
readonly COMMON_CONST_HVMAC=00:1b:21:39:9b:d4 #MAC main hypervisor host
readonly COMMON_CONST_LINUX_APT_ISO_URL='http://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-9.1.0-amd64-netinst.iso' #APT-based Linux ISO url for download
readonly COMMON_CONST_LINUX_RPM_ISO_URL='http://ftp.icm.edu.pl/pub/Linux/dist/oracle-linux/OL7/u4/x86_64/OracleLinux-R7-U4-Server-x86_64-dvd.iso' #RPM-based Linux ISO url for download
readonly COMMON_CONST_FREEBSD_ISO_URL='https://download.freebsd.org/ftp/releases/ISO-IMAGES/11.1/FreeBSD-11.1-RELEASE-amd64-disc1.iso' #FreeBSD ISO url for download
readonly COMMON_CONST_HV_POOL_HOSTS='esxi' #hypervisor hosts, list with space delimiter
readonly COMMON_CONST_LINUX_APT_POOL_NAMES='debian8_64Guest oracleLinux64Guest' #APT-based Linux pool name, list with space delimiter
readonly COMMON_CONST_LINUX_RPM_POOL_NAMES='oracleLinux64Guest' #RPM-based Linux pool name, list with space delimiter
readonly COMMON_CONST_FREEBSD_POOL_NAMES='freebsd64Guest' #FreeBSD pool name, list with space delimiter

#exit values
readonly COMMON_CONST_EXIT_ERROR=1
readonly COMMON_CONST_EXIT_SUCCESS=0
readonly COMMON_CONST_ERROR_MES_UNKNOWN='some problem occured while execute last command, details above in output'
