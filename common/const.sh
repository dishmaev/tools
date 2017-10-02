#!/bin/sh

#define common consts
COMMON_CONST_GPGKEYID=507650DE33C7BA92EDD1569DF4F5A67BE44EEED4 #GPG KEY ID
COMMON_CONST_USER=dmitry #Common username for connect to hosts, run scripts, etc.
COMMON_CONST_HVHOST=esxi #DNS name main hypervisor host
COMMON_CONST_HVMAC=00:1b:21:39:9b:d4 #MAC main hypervisor host
COMMON_CONST_SCRIPT_FILENAME=$(basename "$0") #script file name
COMMON_CONST_SCRIPT_DIRNAME=$(dirname "$0") #script directory name
COMMON_CONST_TOOLTIP='-y mean non-interactively with yes answer and install missing dependencies' #simple autoyes tooltip
COMMON_CONST_FALSE=0 #false
COMMON_CONST_TRUE=1 #true
COMMON_CONST_TOOLSREPO=git@github.com:dishmaev/tools.git #for add like submodule
