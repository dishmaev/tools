#!/bin/sh

###header
. $(dirname "$0")/../../common/define_trigger.sh #include common defines, like $COMMON_...
showDescription "Trigger for $COMMON_CONST_PHOTON_VMTEMPLATE template VM"

##private consts


##private vars
PRM_IPADDRESS='' #ptn vm ip address
PRM_HOSTNAME='' #host name for vm
PRM_OSVERSION='' #os version for vm
RET_VAL='' #child return value
RET_LOG='' #child log
SSH_PWD='' #ssh password

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<ipAddressVM> [hostNameVM=$COMMON_CONST_PHOTON_VMTEMPLATE] [osVersionVM=$COMMON_CONST_PHOTON_VERSION]' "192.168.0.100 $COMMON_CONST_PHOTON_VMTEMPLATE $COMMON_CONST_PHOTON_VERSION" ""

###check commands

PRM_IPADDRESS=$1
PRM_HOSTNAME=${2:-$COMMON_CONST_PHOTON_VMTEMPLATE}
PRM_OSVERSION=${3:-$COMMON_CONST_PHOTON_VERSION}

checkCommandExist 'ipAddressVM' "$PRM_IPADDRESS" ''


###check body dependencies

checkDependencies 'ssh scp'

###check required files

checkRequiredFiles "$COMMON_CONST_SSH_PASS_FILE"

###start prompt

startPrompt

###body

echo "Current template VM $PRM_HOSTNAME OS version:" $PRM_OSVERSION

SSH_PWD=$(cat $COMMON_CONST_SSH_PASS_FILE)

echo $SSH_PWD | $SSH_COPY_ID root@$PRM_IPADDRESS
echo $SSH_PWD | $SCP_CLIENT $COMMON_CONST_SCRIPT_DIRNAME/ptn_script.sh root@$PRM_IPADDRESS:
RET_VAL=$($SSH_CLIENT root@$PRM_IPADDRESS "./ptn_script.sh $COMMON_CONST_SCRIPT_USER $PRM_HOSTNAME $SSH_PWD; \
if [ -f ptn_script.ret ]; then cat ptn_script.ret; rm ptn_script.ret; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$RET_VAL"
RET_LOG=$($SSH_CLIENT root@$PRM_IPADDRESS "if [ -f ptn_script.log ]; then cat ptn_script.log; fi") || exitChildError "$RET_LOG"
echo "$RET_LOG"
if ! isTrue "$RET_VAL"; then
  exitError "failed execute script on vmname:ip $PRM_HOSTNAME:$PRM_IPADDRESS"
fi

doneFinalStage
exitOK

$SSH_CLIENT root@$PRM_IPADDRESS "if [ ! -d \$HOME/.ssh ]; then mkdir -m u=rwx,g=,o= \$HOME/.ssh; fi; \
cat > \$HOME/.ssh/authorized_keys" < $HOME/.ssh/${COMMON_CONST_SSHKEYID}.pub
if ! isRetValOK; then exitError; fi
$SSH_CLIENT root@$PRM_IPADDRESS "echo 'iptables -A INPUT -p icmp -j ACCEPT' >> /etc/systemd/scripts/iptables"
if ! isRetValOK; then exitError; fi
$SSH_CLIENT root@$PRM_IPADDRESS "tdnf -y install sudo"
if ! isRetValOK; then exitError; fi
$SSH_CLIENT root@$PRM_IPADDRESS "useradd --create-home $COMMON_CONST_SCRIPT_USER; usermod -aG sudo $COMMON_CONST_SCRIPT_USER; \
if [ ! -d /home/$COMMON_CONST_SCRIPT_USER/.ssh ]; then mkdir -m u=rwx,g=,o= /home/$COMMON_CONST_SCRIPT_USER/.ssh; fi; \
chown $COMMON_CONST_SCRIPT_USER:users /home/$COMMON_CONST_SCRIPT_USER/.ssh; cp \$HOME/.ssh/authorized_keys /home/$COMMON_CONST_SCRIPT_USER/.ssh/; \
chown $COMMON_CONST_SCRIPT_USER:users /home/$COMMON_CONST_SCRIPT_USER/.ssh/authorized_keys; \
chmod u=rw,g=,o= /home/$COMMON_CONST_SCRIPT_USER/.ssh/authorized_keys"
if ! isRetValOK; then exitError; fi
$SSH_CLIENT root@$PRM_IPADDRESS "cat > pass1; cp pass1 pass2; cat pass1 >> pass2; cat pass2 | passwd toolsuser; \
rm pass1 pass2; chmod u+w /etc/sudoers; echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers; \
chmod u-w /etc/sudoers;" < $COMMON_CONST_SSH_PASS_FILE
if ! isRetValOK; then exitError; fi
$SSH_CLIENT root@$PRM_IPADDRESS "hostnamectl set-hostname $PRM_HOSTNAME"
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
