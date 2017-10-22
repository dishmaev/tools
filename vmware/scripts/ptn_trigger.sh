#!/bin/sh

###header
. $(dirname "$0")/../../common/define_trigger.sh #include common defines, like $COMMON_...
showDescription "Trigger for $COMMON_CONST_VMTYPE_PHOTON type template VM"

##private consts


##private vars
PRM_IPADDRESS='' #ptn vm ip address
PRM_HOSTNAME='' #host name for vm

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<ipAddressVM> [hostNameVM=$COMMON_CONST_VMTYPE_PHOTON]' "192.168.0.100 $COMMON_CONST_VMTYPE_PHOTON" ""

###check commands

PRM_IPADDRESS=$1
PRM_HOSTNAME=${2:-$COMMON_CONST_VMTYPE_PHOTON}

checkCommandExist 'ipAddressVM' "$PRM_IPADDRESS" ''


###check body dependencies

checkDependencies 'ssh scp'

###check required files

checkRequiredFiles "$COMMON_CONST_SSH_PASS_FILE"

###start prompt

startPrompt

###body

$SSH_CLIENT root@$PRM_IPADDRESS "if [ ! -d \$HOME/.ssh ]; then mkdir -m u=rwx,g=,o= \$HOME/.ssh; fi; cat > \$HOME/.ssh/authorized_keys" < $HOME/.ssh/$COMMON_CONST_SSHKEYID.pub
if ! isRetValOK; then exitError; fi
$SSH_CLIENT root@$PRM_IPADDRESS "echo 'iptables -A INPUT -p icmp -j ACCEPT' >> /etc/systemd/scripts/iptables"
if ! isRetValOK; then exitError; fi
$SSH_CLIENT root@$PRM_IPADDRESS "tdnf -y install sudo"
if ! isRetValOK; then exitError; fi
$SSH_CLIENT root@$PRM_IPADDRESS "useradd --create-home $COMMON_CONST_USER; usermod -aG sudo $COMMON_CONST_USER; \
if [ ! -d /home/$COMMON_CONST_USER/.ssh ]; then mkdir -m u=rwx,g=,o= /home/$COMMON_CONST_USER/.ssh; fi; \
chown $COMMON_CONST_USER:users /home/$COMMON_CONST_USER/.ssh; cp \$HOME/.ssh/authorized_keys /home/$COMMON_CONST_USER/.ssh/; \
chown $COMMON_CONST_USER:users /home/$COMMON_CONST_USER/.ssh/authorized_keys; \
chmod u=rw,g=,o= /home/$COMMON_CONST_USER/.ssh/authorized_keys"
if ! isRetValOK; then exitError; fi
$SSH_CLIENT root@$PRM_IPADDRESS "cat > pass1; cp pass1 pass2; cat pass1 >> pass2; cat pass2 | passwd toolsuser; \
rm pass1 pass2; chmod u+w /etc/sudoers; echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers; \
chmod u-w /etc/sudoers;" < $COMMON_CONST_SSH_PASS_FILE
if ! isRetValOK; then exitError; fi
$SSH_CLIENT root@$PRM_IPADDRESS "hostnamectl set-hostname $PRM_HOSTNAME"
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
