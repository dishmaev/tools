#!/bin/sh

##using files: consts.sh

##private vars
AUTO_YES=$COMMON_CONST_FALSE #non-interactively mode enum {n,y}
NEED_HELP=$COMMON_CONST_FALSE #show help and exit
STAGE_NUM=0 #stage counter

#$1 VMID, $2 snapshotName, $3 snapshotId, $4 host
getChildSnapshotsPool(){
  checkParmsCount $# 4 'getChildSnapshotsPool'
  local VAR_RESULT=''
  local VAR_CUR_STR=''
  local VAR_CUR_SSNAME=''
  local VAR_CUR_SSID=''
  local VAR_CUR_SSID2=''
  local VAR_CUR_LEVEL=''
  local VAR_CUR_LEVEL2=''
  local VAR_CUR_STR2=''
  local VAR_SS_LIST=''
  local VAR_SS_LIST2=''
  local VAR_FOUND=$COMMON_CONST_FALSE
  VAR_SS_LIST=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$4 "vim-cmd vmsvc/snapshot.get $1 | \
  egrep -- '--Snapshot Name|--Snapshot Id' | awk '{ORS=NR%2?FS:RS; print \$4\":\"(length(\$1)-8)/2}' | \
  awk '{print \$1\":\"\$2}' | awk -F: '{print \$1\":\"\$3\":\"\$2}'") || exitChildError "$VAR_RESULT"
  for VAR_CUR_STR in $VAR_SS_LIST; do
    VAR_CUR_SSNAME=$(echo $VAR_CUR_STR | awk -F: '{print $1}')
    VAR_CUR_SSID=$(echo $VAR_CUR_STR | awk -F: '{print $2}')
    if [ "$2:$3" = "$VAR_CUR_SSNAME:$VAR_CUR_SSID" ]; then
      VAR_CUR_LEVEL=$(echo $VAR_CUR_STR | awk -F: '{print $3}')
      VAR_SS_LIST2=$(echo "$VAR_SS_LIST" | sed -n '/'$VAR_CUR_SSNAME:$VAR_CUR_SSID:$VAR_CUR_LEVEL'/,$p' | sed 1d)
      VAR_CUR_LEVEL=$((VAR_CUR_LEVEL+1))
      for VAR_CUR_STR2 in $VAR_SS_LIST2; do
        VAR_CUR_LEVEL2=$(echo $VAR_CUR_STR2 | awk -F: '{print $3}')
        if [ $VAR_CUR_LEVEL2 -eq $VAR_CUR_LEVEL ]; then
          VAR_CUR_SSID2=$(echo $VAR_CUR_STR2 | awk -F: '{print $2}')
          VAR_RESULT="$VAR_RESULT $VAR_CUR_SSID2"
        elif [ $VAR_CUR_LEVEL2 -lt $VAR_CUR_LEVEL ]; then
          break
        elif [ $VAR_CUR_LEVEL2 -gt $VAR_CUR_LEVEL ]; then
          continue
        fi
      done
      VAR_FOUND=$COMMON_CONST_TRUE
      break
    fi
  done
  if ! isTrue $VAR_FOUND; then
    exitError "snapshot $2 Id $3 not found for VMID $1 on $4 host"
  fi
  echo "$VAR_RESULT"
}
#$1 VMID, $2 snapshotName, $3 host
getVMSnapshotIDByName(){
  checkParmsCount $# 3 'getVMSnapshotIDByName'
  local VAR_RESULT=''
  local VAR_CUR_STR=''
  local VAR_CUR_SSNAME=''
  local VAR_FOUND=$COMMON_CONST_FALSE
  VAR_RESULT=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$3 "vim-cmd vmsvc/snapshot.get $1 | \
  egrep -- '--Snapshot Name|--Snapshot Id' | awk '{ORS=NR%2?FS:RS; print \$4\":\"(length(\$1)-8)/2}' | \
  awk '{print \$1\":\"\$2}' | awk -F: '{print \$1\":\"\$3\":\"\$2}'") || exitChildError "$VAR_RESULT"
  if ! isEmpty "$VAR_RESULT"; then
    for VAR_CUR_STR in $VAR_RESULT; do
      VAR_CUR_SSNAME=$(echo $VAR_CUR_STR | awk -F: '{print $1}')
      if [ "$2" = "$VAR_CUR_SSNAME" ]; then
        VAR_RESULT=$(echo $VAR_CUR_STR | awk -F: '{print $2}')
        VAR_FOUND=$COMMON_CONST_TRUE
        break
      fi
    done
    if ! isTrue "$VAR_FOUND"; then
      VAR_RESULT=''
    fi
  fi
  echo "$VAR_RESULT"
}
#$1 VMID, $2 host
getVMSnapshotCount(){
  checkParmsCount $# 2 'getVMSnapshotCount'
  local VAR_RESULT=''
  VAR_RESULT=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$2 "vim-cmd vmsvc/snapshot.get $1 | egrep -- '--\|-CHILD|^\|-ROOT' | wc -l") || exitChildError "$VAR_RESULT"
  VAR_RESULT=${VAR_RESULT:-"0"}
  echo "$VAR_RESULT"
}
#$1 vm type, $2 vm version
getVMUrl() {
  checkParmsCount $# 2 'getVMUrl'
  local CONST_FILE_PATH="./../vmware/templates/${1}_ver_url.txt"
  local VAR_RESULT=''
  if ! isFileExistAndRead "$CONST_FILE_PATH"; then
    exitError "file $CONST_FILE_PATH not found"
  fi
  VAR_RESULT=$(cat $CONST_FILE_PATH | grep "$2::" | awk -F:: '{print $2}')
  if isEmpty "$VAR_RESULT"; then
    exitError "missing url for vm type $1 version $2 in file $CONST_FILE_PATH"
  fi
  echo "$VAR_RESULT"
}
#$1 vm type
getAvailableVMVersions(){
  checkParmsCount $# 1 'getAvailableVMVersions'
  local CONST_FILE_PATH="./../vmware/templates/${1}_ver_url.txt"
  local VAR_RESULT=''
  local VAR_FOUND=$COMMON_CONST_FALSE
  if ! isFileExistAndRead "$CONST_FILE_PATH"; then
    exitError "file $CONST_FILE_PATH not found"
  fi
  for VAR_CUR_VMTEMPLATE in $COMMON_CONST_VMTEMPLATES_POOL; do
    if [ "$1" = "$VAR_CUR_VMTEMPLATE" ]; then
      VAR_RESULT=$(sed 1d $CONST_FILE_PATH | awk -F:: '{print $1}'| awk '{ORS=FS} 1')
      VAR_FOUND=$COMMON_CONST_TRUE
      break
    fi
  done
  if ! isTrue $VAR_FOUND; then
    exitError "VM template $1 not found"
  fi
  if isEmpty "$VAR_RESULT"; then
    exitError "cannot found any version for vm type $1 in file $CONST_FILE_PATH"
  fi
  echo "$VAR_RESULT"
}
#$1 vm type
getDefaultVMVersion(){
  checkParmsCount $# 1 'getDefaultVMVersion'
  local CONST_FILE_PATH="./../vmware/templates/${1}_ver_url.txt"
  local VAR_RESULT=''
  local VAR_CUR_VMTEMPLATE=''
  local VAR_FOUND=$COMMON_CONST_FALSE
  if ! isFileExistAndRead "$CONST_FILE_PATH"; then
    exitError "file $CONST_FILE_PATH not found"
  fi
  for VAR_CUR_VMTEMPLATE in $COMMON_CONST_VMTEMPLATES_POOL; do
    if [ "$1" = "$VAR_CUR_VMTEMPLATE" ]; then
      VAR_RESULT=$(sed -n 2p $CONST_FILE_PATH | awk -F: '{print $1}')
      VAR_FOUND=$COMMON_CONST_TRUE
      break
    fi
  done
  if ! isTrue $VAR_FOUND; then
    exitError "VM template $1 not found"
  fi
  if isEmpty "$VAR_RESULT"; then
    exitError "missing default version for vm type $1 in file $CONST_FILE_PATH"
  fi
  echo "$VAR_RESULT"
}
#$1 VMID, $2 esxi host
powerOnVM()
{
  checkParmsCount $# 2 'powerOnVM'
  local VAR_RESULT=''
  local VAR_COUNT=$COMMON_CONST_ESXI_TRY_LONG
  local VAR_TRY=$COMMON_CONST_ESXI_TRY_NUM
  $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$2 "if [ \"\$(vim-cmd vmsvc/power.getstate $1 | sed -e '1d')\" != 'Powered on' ]; then vim-cmd vmsvc/power.on $1; fi"
  if ! isRetValOK; then exitError; fi
  while true; do
    sleep $COMMON_CONST_ESXI_SLEEP_LONG
    #check status
    VAR_RESULT=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$2 "if [ \"\$(vim-cmd vmsvc/power.getstate $1 | sed -e '1d')\" = 'Powered on' ]; then echo $COMMON_CONST_TRUE; fi") || exitChildError "$VAR_RESULT"
    if isTrue "$VAR_RESULT"; then break; fi
    VAR_COUNT=$((VAR_COUNT-1))
    if [ $VAR_COUNT -eq 0 ]; then
      VAR_TRY=$((VAR_TRY-1))
      if [ $VAR_TRY -eq 0 ]; then  #still not powered on, force kill vm
        exitError "failed power on the VMID $1 on $2 host. Check VM Tools install and running"
      else
        echo "Still cannot power on the VMID $1 on $2 host, left $VAR_TRY attempts"
      fi;
      VAR_COUNT=$COMMON_CONST_ESXI_TRY_LONG
    fi
  done
  return $COMMON_CONST_EXIT_SUCCESS
}
#$1 VMID, $2 esxi host
powerOffVM()
{
  checkParmsCount $# 2 'powerOffVM'
  local VAR_RESULT=''
  local VAR_COUNT=$COMMON_CONST_ESXI_TRY_LONG
  local VAR_TRY=$COMMON_CONST_ESXI_TRY_NUM
  $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$2 "if [ \"\$(vim-cmd vmsvc/power.getstate $1 | sed -e '1d')\" != 'Powered off' ]; then vim-cmd vmsvc/power.off $1; fi"
  if ! isRetValOK; then exitError; fi
  while true; do
    sleep $COMMON_CONST_ESXI_SLEEP_LONG
    #check running
    VAR_RESULT=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "vmdumper -l | grep -i 'displayName=\"$PRM_VMNAME\"' | awk '{print \$1}' | awk -F'/|=' '{print \$(NF)}'") || exitChildError "$VAR_RESULT"
    if isEmpty "$VAR_RESULT"; then break; fi
    VAR_COUNT=$((VAR_COUNT-1))
    if [ $VAR_COUNT -eq 0 ]; then
      VAR_TRY=$((VAR_TRY-1))
      if [ $VAR_TRY -eq 0 ]; then  #still running, force kill vm
        echo "Failed standard power off the VMID $1 on $2 host, use force power off."
        $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "esxcli vm process kill --type force --world-id $VAR_RESULT"
        if ! isRetValOK; then exitError; fi
        sleep $COMMON_CONST_ESXI_SLEEP_LONG
        VAR_RESULT=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "vmdumper -l | grep -i 'displayName=\"$PRM_VMNAME\"' | awk '{print \$1}' | awk -F'/|=' '{print \$(NF)}'") || exitChildError "$VAR_RESULT"
        if ! isEmpty "$VAR_RESULT"; then
          exitError "failed force power off the VMID $1 on $2 host"
        fi
      else
        echo "Still cannot standard power off the VMID $1 on $2 host, left $VAR_TRY attempts"
      fi;
      VAR_COUNT=$COMMON_CONST_ESXI_TRY_LONG
    fi
  done
  return $COMMON_CONST_EXIT_SUCCESS
}
#$1 vm name, $2 esxi host
getIpAddressByVMName()
{
  checkParmsCount $# 2 'getIpAddressByVMName'
  local VAR_RESULT=''
  local VAR_COUNT=$COMMON_CONST_ESXI_TRY_LONG
  local VAR_TRY=$COMMON_CONST_ESXI_TRY_NUM
  local VAR_VMID=''
  VAR_VMID=$(getVMIDByVMName "$1" "$2") || exitChildError "$VAR_VMID"
  while true
  do
    VAR_RESULT=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$2 "vim-cmd vmsvc/get.guest $VAR_VMID | grep 'ipAddress = \"' | \
        sed -n 1p | cut -d '\"' -f2") || exitChildError "$VAR_RESULT"
    if ! isEmpty "$VAR_RESULT"; then break; fi
    VAR_COUNT=$((VAR_COUNT-1))
    if [ $VAR_COUNT -eq 0 ]; then
      VAR_TRY=$((VAR_TRY-1))
      if [ $VAR_TRY -eq 0 ]; then
        exitError "failed get ip address of the VM $1 on $2 host. Check VM Tools install and running"
      #else
        #echo "Still cannot get ip address of the VMID $1 on $2 host, left $VAR_TRY attempts"
      fi;
      VAR_COUNT=$COMMON_CONST_ESXI_TRY_LONG
    fi
    sleep $COMMON_CONST_ESXI_SLEEP_LONG
  done
  echo "$VAR_RESULT"
}
#$1 pool, list with space delimiter. Return value format 'vmid:host'
getVmsPool(){
  checkParmsCount $# 1 'getVmsPool'
  local VAR_CUR_ESXI=''
  local VAR_CUR_OS=''
  local VAR_RESULT=''
  for VAR_CUR_ESXI in $COMMON_CONST_ESXI_HOSTS_POOL
  do
    for VAR_CUR_OS in $1
    do
      local VAR_RESULT
      VAR_RESULT=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$CUR_ESXI "vim-cmd vmsvc/getallvms | sed -e '1d' | \
        awk '{print \$1\":\"\$5}' | grep ':'$VAR_CUR_OS | awk -F: '{print \$1\":$VAR_CUR_ESXI\"}'") || exitChildError "$VAR_RESULT"
      echo "$VAR_RESULT"
    done
  done
}
#$1 vm name, $2 esxi host
getVMIDByVMName() {
  checkParmsCount $# 2 'getVMIDByVMName'
  local VAR_RESULT
  VAR_RESULT=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$2 "vim-cmd vmsvc/getallvms | sed -e '1d' -e 's/ \[.*$//' \
| awk '\$1 ~ /^[0-9]+$/ {print \$1\":\"\$2\":\"}' | grep ':'$1':' | awk -F: '{print \$1}'") || exitChildError "$VAR_RESULT"
  echo "$VAR_RESULT"
}
#$1 VMID, $2 esxi host
getVMNameByVMID() {
  checkParmsCount $# 2 'getVMNamebyVMID'
  local VAR_RESULT
  VAR_RESULT=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$2 "vim-cmd vmsvc/getallvms | sed -e '1d' -e 's/ \[.*$//' \
| awk '\$1 ~ /^[0-9]+$/ {print \$1\":\"substr(\$0,8,80)}' | grep $1':' | awk -F: '{print \$2}'") || exitChildError "$VAR_RESULT"
  echo "$VAR_RESULT"
}
#$1 title, $2 value, [$3] allow values
checkCommandExist() {
  checkParmsCount $# 3 'checkCommandExist'
  if isEmpty "$2"
  then
    exitError "command $1 missing"
  elif ! isEmpty "$3"
  then
    checkCommandValue "$1" "$2" "$3"
  fi
}
#$1 vm name , $2 esxi host, $3 vm OS version, $4 pause message
checkTriggerTemplateVM(){
  checkParmsCount $# 4 'checkTriggerTemplateVM'
  local VAR_VMID=''
  local VAR_VMIP=''
  local VAR_INPUT=''
  local VAR_RESULT=''
  local VAR_LOG=''
  if ! isAutoYesMode; then
    read -r -p "Pause 1 of 3: Check necessary virtual hardware on template VM $1 on $2 host. When you are done, press Enter for resume procedure " VAR_INPUT
  fi
  if isFileExistAndRead "$COMMON_CONST_SCRIPT_DIRNAME/templates/${1}_script.sh";then
    VAR_VMID=$(getVMIDByVMName "$1" "$2") || exitChildError "$VAR_VMID"
    powerOnVM "$VAR_VMID" "$2"
    if ! isAutoYesMode; then
      if ! isEmpty "$4"; then
        echo "$4"
      fi
      read -r -p "Pause 2 of 3: Manually make changes on template VM $1 on $2 host. When you are done, press Enter for resume procedure " VAR_INPUT
    fi
    VAR_VMIP=$(getIpAddressByVMName "$1" "$2") || exitChildError "$VAR_VMIP"
    echo "VM ${1} ip address: $VAR_VMIP"
    $SSH_COPY_ID root@$VAR_VMIP
    if ! isRetValOK; then exitError; fi
    $SCP_CLIENT $COMMON_CONST_SCRIPT_DIRNAME/templates/${1}_script.sh root@$VAR_VMIP:
    if ! isRetValOK; then exitError; fi
    SSH_PWD=$(cat $COMMON_CONST_SSH_PASS_FILE) || exitChildError "$VAR_VMIP"
    VAR_RESULT=$($SSH_CLIENT root@$VAR_VMIP "chmod u+x ${1}_script.sh;./${1}_script.sh $COMMON_CONST_SCRIPT_USER $SSH_PWD $1 $3; \
if [ -f ${1}_script.result ]; then cat ${1}_script.result; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_RESULT"
    VAR_LOG=$($SSH_CLIENT root@$VAR_VMIP "if [ -f ${1}_script.log ]; then cat ${1}_script.log; fi") || exitChildError "$VAR_LOG"
    echo "$VAR_LOG"
    VAR_LOG=$($SSH_CLIENT root@$VAR_VMIP "if [ -f ${1}_script.err ]; then cat ${1}_script.err; fi") || exitChildError "$VAR_LOG"
    echo "$VAR_LOG"
    if ! isTrue "$VAR_RESULT"; then
      exitError "failed execute ${1}_script.sh on template VM ${1} ip $VAR_VMIP on $2 host"
    fi
    if ! isAutoYesMode; then
      read -r -p "Pause 3 of 3: Manually reboot and last check template VM ${1} ip $VAR_VMIP on $2 host. When you are done, press Enter for resume procedure " VAR_INPUT
    else
      sleep $COMMON_CONST_ESXI_SLEEP_LONG
    fi
    powerOffVM "$VAR_VMID" "$2"
  fi
}
#$1 title, $2 value, $3 allowed values
checkCommandValue() {
  checkParmsCount $# 3 'checkCommandValue'
  local VAR_FOUND=$COMMON_CONST_FALSE
  for CUR_COMM in $3
  do
    if [ "$CUR_COMM" = "$2" ]
    then
      VAR_FOUND=$COMMON_CONST_TRUE
    fi
  done
  if ! isTrue $VAR_FOUND
  then
    exitError "command $1 value $2 invalid. Allowed values: $3"
  fi
}
#$1 directory name, $2 error message prefix
checkDirectoryForExist() {
  checkParmsCount $# 2 'checkDirectoryForExist'
  if ! isDirectoryExist "$1"
  then
    exitError "$2directory $1 missing or not exist"
  fi
}

checkDirectoryForNotExist() {
  checkParmsCount $# 2 'checkDirectoryForNotExist'
  if ! isEmpty "$1" && [ -d "$1" ]
  then
    exitError "$2directory $1 already exist"
  fi
}

checkGpgSecKeyExist() {
  checkParmsCount $# 1 'checkGpgSecKeyExist'
  checkDependencies 'gpg grep'
  if isEmpty "$1" || isEmpty "$(gpg -K | grep $1)"
  then
    exitError "gpg secret key $1 not found"
  fi
}

checkDependencies(){
  checkParmsCount $# 1 'checkDependencies'
  for CUR_DEP in $1
  do
    if ! isCommandExist $CUR_DEP
    then
      if isAutoYesMode
      then
        if isLinuxOS
        then
          local VAR_LINUX_BASED
          VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
          if isAPTLinux "$VAR_LINUX_BASED"
          then
            sudo apt -y install $CUR_DEP
          elif isRPMLinux "$VAR_LINUX_BASED"
          then
            sudo yum -y install $CUR_DEP
          fi
        elif isFreeBSDOS
        then
          setenv ASSUME_ALWAYS_YES yes
          pkg install $CUR_DEP
          setenv ASSUME_ALWAYS_YES
        fi
        #repeat check for availability dependence
        if ! isCommandExist $CUR_DEP
        then
          exitError "dependence $CUR_DEP not found"
        fi
      else
        exitError "dependence $CUR_DEP not found"
      fi
    fi
  done
}

checkRequiredFiles() {
  checkParmsCount $# 1 'checkRequiredFiles'
  for CUR_FILE in $1
  do
    if ! isFileExistAndRead $CUR_FILE
    then
      exitError "file $CUR_FILE not found"
    fi
  done
}

checkLinuxAptOrRpm(){
  checkParmsCount $# 0 'checkLinuxAptOrRpm'
  if [ -f /etc/debian_version ]; then
      echo 'apt'
  elif [ -f /etc/redhat-release ]; then
    echo 'rpm'
  else
    exitError "unknown Linux based package system"
  fi
}

showDescription(){
  checkParmsCount $# 1 'showDescription'
  echo $1
}
#$1 total stage, $2 stage description
beginStage(){
  checkParmsCount $# 2 'beginStage'
  STAGE_NUM=$((STAGE_NUM+1))
  if [ $STAGE_NUM -gt $1 ]
  then
    exitError 'too many stages'
  fi
  echo -n "Stage $STAGE_NUM of $1: $2..."
}

doneStage(){
  checkParmsCount $# 0 'doneStage'
  echo ' Done'
}

doneFinalStage(){
  checkParmsCount $# 0 'doneFinalStage'
  if [ $STAGE_NUM -gt 0 ]
  then
    doneStage
  fi
  echo 'Success!'
}
#[$1] message
exitOK(){
  if ! isEmpty "$1"
  then
    echo $1
  fi
  exit $COMMON_CONST_EXIT_SUCCESS
}
#[$1] message, [$2] child error
exitError(){
  if isEmpty "$2"
  then
    echo -n "Error: ${1:-$COMMON_CONST_ERROR_MES_UNKNOWN}"
    echo ". See '$COMMON_CONST_SCRIPT_FILENAME --help'"
  else
    echo "$1"
  fi
  exit $COMMON_CONST_EXIT_ERROR
}
#$1 message
exitChildError(){
  checkParmsCount $# 1 'exitChildError'
  if isEmpty "$1"
  then
    exitError
  else
    exitError "$1" "$COMMON_CONST_EXIT_ERROR"
  fi
}
#$1 command count, $2 must be count, $3 usage message, $4 sample message, $5 add tooltip message
echoHelp(){
  checkParmsCount $# 5 'echoHelp'
  if [ $1 -gt $2 ]
  then
    exitError 'too many command'
  fi
  if isTrue $NEED_HELP
  then
    echo "Usage: $COMMON_CONST_SCRIPT_FILENAME [-y] $3"
    echo "Sample: $COMMON_CONST_SCRIPT_FILENAME $4"
    if ! isEmpty "$5"
    then
      PRM_TOOLTIP="$COMMON_CONST_TOOLTIP. $5"
    else
      PRM_TOOLTIP=$COMMON_CONST_TOOLTIP
    fi
    echo "Tooltip: $PRM_TOOLTIP"
    exitOK
  fi
}

startPrompt(){
  checkParmsCount $# 0 'startPrompt'
  if ! isAutoYesMode
  then
    local VAR_INPUT=''
    local VAR_YES=$COMMON_CONST_FALSE
    local VAR_DO_FLAG=$COMMON_CONST_TRUE
    while [ "$VAR_DO_FLAG" = "$COMMON_CONST_TRUE" ]
    do
      read -r -p 'Do you want to continue? [y/N] ' VAR_INPUT
      if isEmpty "$VAR_INPUT"
      then
        VAR_DO_FLAG=$COMMON_CONST_FALSE
      else
        case $VAR_INPUT in
          [yY])
            VAR_YES=$COMMON_CONST_TRUE
            VAR_DO_FLAG=$COMMON_CONST_FALSE
            ;;
          [nN])
            VAR_DO_FLAG=$COMMON_CONST_FALSE
            ;;
          *)
            echo 'Invalid input'
            ;;
        esac
      fi
    done
    if ! isTrue $VAR_YES
    then
      exitOK 'Good bye!'
    fi
  fi
  echo 'Start'
}

checkAutoYes() {
  checkParmsCount $# 1 'checkAutoYes'
  if [ "$1" = "-y" ]
  then
    AUTO_YES=$COMMON_CONST_TRUE
    return $AUTO_YES
  elif [ "$1" = "--help" ]
  then
    NEED_HELP=$COMMON_CONST_TRUE
  fi
}
#$1 url string
getFileNameFromUrlString()
{
  checkParmsCount $# 1 'getFileNameFromUrlString'
  echo $1 | awk -F'/|=' '{print $(NF)}'
}
#$1 file name with ext
getFileNameWithoutExt()
{
  checkParmsCount $# 1 'getFileNameWithoutExt'
  echo $1 | awk -F. '{print $1}'
}
#$1 parm count, $2 must be count, $3 function name
checkParmsCount(){
  if [ $# -gt 3 ]
  then
    exitError "too many parameters for call function checkParmsCount"
  elif [ $# -lt 3 ]
  then
    exitError "too few parameters for call function checkParmsCount"
  fi
  if [ $1 -gt $2 ]
  then
    exitError "too many parameters for call function $3"
  elif [ $1 -lt $2 ]
  then
    exitError "too few parameters for call function $3"
  fi
}
#$1 esxi host
put_ovftool_to_esxi(){
  checkParmsCount $# 1 'put_ovftool_to_esxi'
  scp -r $COMMON_CONST_LOCAL_OVFTOOL_PATH $COMMON_CONST_SCRIPT_USER@$1:$COMMON_CONST_ESXI_TOOLS_PATH
  if ! isRetValOK; then exitError; fi
  $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$1 "sed -i 's@^#!/bin/bash@#!/bin/sh@' $COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool"
  if ! isRetValOK; then exitError; fi
}
#$1 esxi host
put_template_tools_to_esxi(){
  checkParmsCount $# 1 'put_template_tools_to_esxi'
  scp -r $COMMON_CONST_SCRIPT_DIRNAME/templates $COMMON_CONST_SCRIPT_USER@$1:$COMMON_CONST_ESXI_TEMPLATES_PATH
  if ! isRetValOK; then exitError; fi
}
#$1 local version, $2 remote version, format MAJOR.MINOR.PATCH
isNewLocalVersion() {
  checkParmsCount $# 2 'isNewLocalVersion'
  local VAR_LOCAL_MAJOR=''
  local VAR_LOCAL_MINOR=''
  local VAR_LOCAL_PATCH=''
  local VAR_LOCAL_TEST=''
  local VAR_REMOTE_MAJOR=''
  local VAR_REMOTE_MINOR=''
  local VAR_REMOTE_PATCH=''
  local VAR_REMOTE_TEST=''
  VAR_LOCAL_MAJOR=$(echo $1 | awk -F. '{print $1}')
  VAR_LOCAL_MINOR=$(echo $1 | awk -F. '{print $2}')
  VAR_LOCAL_PATCH=$(echo $1 | awk -F. '{print $3}')
  VAR_LOCAL_TEST=$(echo $1 | awk -F. '{print $4}')
  VAR_REMOTE_MAJOR=$(echo $2 | awk -F. '{print $1}')
  VAR_REMOTE_MINOR=$(echo $2 | awk -F. '{print $2}')
  VAR_REMOTE_PATCH=$(echo $2 | awk -F. '{print $3}')
  VAR_REMOTE_TEST=$(echo $2 | awk -F. '{print $4}')
  if isEmpty "$VAR_LOCAL_MAJOR" || isEmpty "$VAR_REMOTE_MAJOR"
  then
    exitError 'isNewLocalVersion not found major version for compare'
  fi
  if ! isEmpty "$VAR_LOCAL_TEST" || ! isEmpty "$VAR_REMOTE_TEST"
  then
    exitError 'isNewLocalVersion wrong version format, need MAJOR.MINOR.PATCH'
  fi
  VAR_LOCAL_MINOR=${VAR_LOCAL_MINOR:-'0'}
  VAR_LOCAL_PATCH=${VAR_LOCAL_PATCH:-'0'}
  VAR_REMOTE_MINOR=${VAR_REMOTE_MINOR:-'0'}
  VAR_REMOTE_PATCH=${VAR_REMOTE_PATCH:-'0'}
  if [ $VAR_LOCAL_MAJOR -lt $VAR_REMOTE_MAJOR ]; then return $COMMON_CONST_EXIT_ERROR;fi
  if [ $VAR_LOCAL_MAJOR -gt $VAR_REMOTE_MAJOR ]; then return $COMMON_CONST_EXIT_SUCCESS;fi
  if [ $VAR_LOCAL_MINOR -lt $VAR_REMOTE_MINOR ]; then return $COMMON_CONST_EXIT_ERROR;fi
  if [ $VAR_LOCAL_MINOR -gt $VAR_REMOTE_MINOR ]; then return $COMMON_CONST_EXIT_SUCCESS;fi
  if [ $VAR_LOCAL_PATCH -lt $VAR_REMOTE_PATCH ]; then return $COMMON_CONST_EXIT_ERROR;fi
  if [ $VAR_LOCAL_PATCH -gt $VAR_REMOTE_PATCH ]; then return $COMMON_CONST_EXIT_SUCCESS;fi
  return $COMMON_CONST_EXIT_ERROR
}

isDirectoryExist() {
  checkParmsCount $# 1 'isDirectoryExist'
  ! isEmpty "$1" && [ -d "$1" ]
}

isFileExistAndRead() {
  checkParmsCount $# 1 'ifFileExistAndRead'
  ! isEmpty "$1" && [ -f "$1" ]
}

isTrue(){
  checkParmsCount $# 1 'isTrue'
  [ "$1" = "$COMMON_CONST_TRUE" ]
}

isEmpty()
{
  checkParmsCount $# 1 'isEmpty'
  [ -z "$1" ]
}

isAutoYesMode(){
  checkParmsCount $# 0 'isAutoYesMode'
  isTrue "$AUTO_YES"
}

isCommandExist(){
  checkParmsCount $# 1 'isCommandExist'
  [ -x "$(command -v $1)" ]
}

isLinuxOS(){
  checkParmsCount $# 0 'isLinuxOS'
  [ "$(uname)" = "Linux" ]
}

isAPTLinux()
{
  checkParmsCount $# 1 'isAPTLinux'
  [ "$1" = "$COMMON_CONST_LINUX_APT" ]
}

isRPMLinux()
{
  checkParmsCount $# 1 'isRPMLinux'
  [ "$1" = "$COMMON_CONST_LINUX_RPM" ]
}

isFreeBSDOS(){
  checkParmsCount $# 0 'isLinuxOS'
  [ "$(uname)" = "FreeBSD" ]
}

isFileSystemMounted(){
  checkParmsCount $# 1 'isDirectoryMounted'
  mount | awk '{print $1}' | grep -w $1 >/dev/null
  [ "$?" = "0" ]
}

isRetValOK(){
  checkParmsCount $# 0 'isRetValOK'
  [ "$?" = "$COMMON_CONST_EXIT_SUCCESS" ]
}
#$1 vm name, $2 host
isVMExist(){
  checkParmsCount $# 2 'isVMExist'
  local VAR_RESULT=''
  VAR_RESULT=$(getVMIDByVMName "$1" "$2") || exitChildError "$VAR_RESULT"
  ! isEmpty "$VAR_RESULT"
}
#$1 VMID, $2 snapshotName, $3 host
isSnapshotVMExist(){
  checkParmsCount $# 3 'isSnapshotVMExist'
  local VAR_RESULT=''
  local VAR_VMID=''
  VAR_RESULT=$(getVMSnapshotIDByName "$1" "$2" "$3") || exitChildError "$VAR_RESULT"
  ! isEmpty "$VAR_RESULT"
}
