#!/bin/sh

#define common consts

#default user, keys
COMMON_CONST_SSHKEYID=id_idax_rsa #SSH keyID
COMMON_CONST_GPGKEYID=507650DE33C7BA92EDD1569DF4F5A67BE44EEED4 #GPG keyID
COMMON_CONST_USER=dmitry #default username for connect to hosts, run scripts, etc.

#base tool infrastructure
COMMON_CONST_SCRIPT_FILENAME=$(basename "$0") #script file name
COMMON_CONST_SCRIPT_DIRNAME=$(dirname "$0") #script directory name
COMMON_CONST_TOOLTIP='-y mean non-interactively with yes answer and try install missing dependencies' #simple autoyes tooltip
COMMON_CONST_TOOLSREPO=git@github.com:dishmaev/tools.git #for add tools submodule

#boolean
COMMON_CONST_FALSE=0 #false
COMMON_CONST_TRUE=1 #true

#hypervisor
COMMON_CONST_HVHOST=esxi #DNS name main hypervisor host
COMMON_CONST_HVMAC=00:1b:21:39:9b:d4 #MAC main hypervisor host
COMMON_CONST_LINUXAPT_ISOURL='http://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-9.1.0-amd64-netinst.iso' #APT-based Linux ISO url for download
COMMON_CONST_LINUXRPM_ISOURL='http://ftp.icm.edu.pl/pub/Linux/dist/oracle-linux/OL7/u4/x86_64/OracleLinux-R7-U4-Server-x86_64-dvd.iso' #RPM-based Linux ISO url for download
COMMON_CONST_FREEBSD_ISOURL='https://download.freebsd.org/ftp/releases/ISO-IMAGES/11.1/FreeBSD-11.1-RELEASE-amd64-disc1.iso' #FreeBSD ISO url for download
COMMON_CONST_LINUXAPT_POOL='' #APT-based Linux vms pool
COMMON_CONST_LINUXRPM_POOL='' #RPM-based Linux vms pool
COMMON_CONST_FREEBSD_POOL='' #FreeBSD vms pool
