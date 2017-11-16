#!/bin/sh

##using files: consts.sh, environment.sh

##private vars
VAR_AUTO_YES=$COMMON_CONST_FALSE #batch mode, allow $COMMON_CONST_NULL
VAR_NEED_HELP=$COMMON_CONST_FALSE #show help and exit
VAR_ENVIRONMENT_ERROR='' #result of check environment, ok if empty
VAR_STAGE_NUM=0 #stage num
VAR_TARGET_DESCRIPTION='' #target description
VAR_COMMAND_VALUE='' #value of commands
VAR_START_TIME='' #start execution script

#$1 char, $2 count
getCharCountString(){
  checkParmsCount $# 2 'getCharCountString'
  getMhDays
  local VAR_COUNT=1
  while true; do
    if [ "$VAR_COUNT" -gt "$2" ]; then break; fi
    VAR_COUNT=$((VAR_COUNT+1))
    echo -n $1
    break;
  done
}
#$1 mh stop, $2 yy stop
getMhDays(){
  checkParmsCount $# 2 'getMhDays'
  local VAR_MH_STOP=0
  case $1 in
    [1,3,5,7,8,10,12]) VAR_MH_STOP=31
       ;;
    2) (( !($2 % 4) && ($2 % 100 || !($2 % 400) ) )) && ( $1=29 || $1=28 )
       ;;
    [4,6,9,11]) VAR_MH_STOP=30
       ;;
  esac
  echo "$VAR_MH_STOP"
}

#$1 start time, $2 elapsed long version
getElapsedTime(){
  checkParmsCount $# 2 'getElapsedTime'
  local VAR_END_TAB
  local VAR_END
  local VAR_START
  local VAR_ESPD
  local VAR_SS_START=0
  local VAR_SS_STOP=0
  local VAR_MM_START=0
  local VAR_MM_STOP=0
  local VAR_HH_START=0
  local VAR_HH_STOP=0
  local VAR_DD_START=0
  local VAR_DD_STOP=0
  local VAR_MH_START=0
  local VAR_MH_STOP=0
  local VAR_YY_START=0
  local VAR_YY_STOP=0

  VAR_END_TAB="$(date +%Y%t%m%t%d%t%H%t%M%t%S)"

  VAR_SS_START=$(echo $1 | awk '{printf ("%d", $6)}')
  VAR_SS_STOP=$(echo $VAR_END_TAB | awk '{printf ("%d", $6)}')
  VAR_MM_START=$(echo $1 | awk '{printf ("%d", $5)}')
  VAR_MM_STOP=$(echo $VAR_END_TAB | awk '{printf ("%d", $5)}')
  VAR_HH_START=$(echo $1 | awk '{printf ("%d", $4)}')
  VAR_HH_STOP=$(echo $VAR_END_TAB | awk '{printf ("%d", $4)}')
  VAR_DD_START=$(echo $1 | awk '{printf ("%d", $3)}')
  VAR_DD_STOP=$(echo $VAR_END_TAB | awk '{printf ("%d", $3)}')
  VAR_MH_START=$(echo $1 | awk '{printf ("%d", $2)}')
  VAR_MH_STOP=$(echo $VAR_END_TAB | awk '{printf ("%d", $2)}')
  VAR_YY_START=$(echo $1 | awk '{printf ("%d", $1)}')
  VAR_YY_STOP=$(echo $VAR_END_TAB | awk '{printf ("%d", $1)}')

  if [ "${VAR_SS_STOP}" -lt "${VAR_SS_START}" ]; then VAR_SS_STOP=$((VAR_SS_STOP+60)); VAR_MM_STOP=$((VAR_MM_STOP-1)); fi
  if [ "${VAR_MM_STOP}" -lt "0" ]; then VAR_MM_STOP=$((VAR_MM_STOP+60)); VAR_HH_STOP=$((VAR_HH_STOP-1)); fi
  if [ "${VAR_MM_STOP}" -lt "${VAR_MM_START}" ]; then VAR_MM_STOP=$((VAR_MM_STOP+60)); VAR_HH_STOP=$((VAR_HH_STOP-1)); fi
  if [ "${VAR_HH_STOP}" -lt "0" ]; then VAR_HH_STOP=$((VAR_HH_STOP+24)); VAR_DD_STOP=$((VAR_DD_STOP-1)); fi
  if [ "${VAR_HH_STOP}" -lt "${VAR_HH_START}" ]; then VAR_HH_STOP=$((VAR_HH_STOP+24)); VAR_DD_STOP=$((VAR_DD_STOP-1)); fi

  if [ "${VAR_DD_STOP}" -lt "0" ]; then VAR_DD_STOP=$((VAR_DD_STOP+$(getMhDays $VAR_MH_STOP $VAR_YY_STOP))); VAR_MH_STOP=$((VAR_MH_STOP-1)); fi
  if [ "${VAR_DD_STOP}" -lt "${VAR_DD_START}" ]; then VAR_DD_STOP=$((VAR_DD_STOP+$(getMhDays $VAR_MH_STOP $VAR_YY_STOP))); VAR_MH_STOP=$((VAR_MH_STOP-1)); fi

  if [ "${VAR_MH_STOP}" -lt "0" ]; then VAR_MH_STOP=$((VAR_MH_STOP+12)); VAR_YY_STOP=$((VAR_YY_STOP-1)); fi
  if [ "${VAR_MH_STOP}" -lt "${VAR_MH_START}" ]; then VAR_MH_STOP=$((VAR_MH_STOP+12)); VAR_YY_STOP=$((VAR_YY_STOP-1)); fi

  VAR_START=$(echo $1| sed 's/[ \t]/-/;s/[ \t]/-/;s/[ \t]/:/2;s/[ \t]/:/2')
  VAR_END=$(echo $VAR_END_TAB | sed 's/[ \t]/-/;s/[ \t]/-/;s/[ \t]/:/2;s/[ \t]/:/2')

  if isTrue "$2"; then
    VAR_ESPD=$(printf "%04d-%02d-%02d %02d:%02d:%02d" $((${VAR_YY_STOP}-${VAR_YY_START})) $((${VAR_MH_STOP}-${VAR_MH_START})) $((${VAR_DD_STOP}-${VAR_DD_START})) $((${VAR_HH_STOP}-${VAR_HH_START})) $((${VAR_MM_STOP}-${VAR_MM_START})) $((${VAR_SS_STOP}-${VAR_SS_START})))
  else
    VAR_START=$(echo $VAR_START | awk '{print $2}')
    VAR_END=$(echo $VAR_END | awk '{print $2}')
    VAR_ESPD=$(printf "%02d:%02d:%02d" $((${VAR_HH_STOP}-${VAR_HH_START})) $((${VAR_MM_STOP}-${VAR_MM_START})) $((${VAR_SS_STOP}-${VAR_SS_START})))
  fi

  echo "Elapsed time: $VAR_ESPD, from $VAR_START to $VAR_END"
}
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
  VAR_SS_LIST=$($SSH_CLIENT $4 "vim-cmd vmsvc/snapshot.get $1 | \
  egrep -- '--Snapshot Name|--Snapshot Id' | awk '{ORS=NR%2?FS:RS; print \$4\":\"(length(\$1)-8)/2}' | \
  awk '{print \$1\":\"\$2}' | awk -F: '{print \$1\":\"\$3\":\"\$2}'") || exitChildError "$VAR_SS_LIST"
  for VAR_CUR_STR in $VAR_SS_LIST; do
    VAR_CUR_SSNAME=$(echo $VAR_CUR_STR | awk -F: '{print $1}') || exitChildError "$VAR_CUR_SSNAME"
    VAR_CUR_SSID=$(echo $VAR_CUR_STR | awk -F: '{print $2}') || exitChildError "$VAR_CUR_SSID"
    if [ "$2:$3" = "$VAR_CUR_SSNAME:$VAR_CUR_SSID" ]; then
      VAR_CUR_LEVEL=$(echo $VAR_CUR_STR | awk -F: '{print $3}') || exitChildError "$VAR_CUR_LEVEL"
      VAR_SS_LIST2=$(echo "$VAR_SS_LIST" | sed -n '/'$VAR_CUR_SSNAME:$VAR_CUR_SSID:$VAR_CUR_LEVEL'/,$p' | sed 1d) || exitChildError "$VAR_SS_LIST2"
      VAR_CUR_LEVEL=$((VAR_CUR_LEVEL+1)) || exitChildError "$VAR_CUR_LEVEL"
      for VAR_CUR_STR2 in $VAR_SS_LIST2; do
        VAR_CUR_LEVEL2=$(echo $VAR_CUR_STR2 | awk -F: '{print $3}') || exitChildError "$VAR_CUR_LEVEL2"
        if [ $VAR_CUR_LEVEL2 -eq $VAR_CUR_LEVEL ]; then
          VAR_CUR_SSID2=$(echo $VAR_CUR_STR2 | awk -F: '{print $2}') || exitChildError "$VAR_CUR_SSID2"
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
  VAR_RESULT=$($SSH_CLIENT $3 "vim-cmd vmsvc/snapshot.get $1 | \
  egrep -- '--Snapshot Name|--Snapshot Id' | awk '{ORS=NR%2?FS:RS; print \$4\":\"(length(\$1)-8)/2}' | \
  awk '{print \$1\":\"\$2}' | awk -F: '{print \$1\":\"\$3\":\"\$2}'") || exitChildError "$VAR_RESULT"
  if ! isEmpty "$VAR_RESULT"; then
    for VAR_CUR_STR in $VAR_RESULT; do
      VAR_CUR_SSNAME=$(echo $VAR_CUR_STR | awk -F: '{print $1}') || exitChildError "$VAR_CUR_SSNAME"
      if [ "$2" = "$VAR_CUR_SSNAME" ]; then
        VAR_RESULT=$(echo $VAR_CUR_STR | awk -F: '{print $2}') || exitChildError "$VAR_RESULT"
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
  VAR_RESULT=$($SSH_CLIENT $2 "vim-cmd vmsvc/snapshot.get $1 | egrep -- '--\|-CHILD|^\|-ROOT' | wc -l") || exitChildError "$VAR_RESULT"
  VAR_RESULT=${VAR_RESULT:-"0"}
  echo "$VAR_RESULT"
}
#$1 vm template, $2 vm version
getVMUrl() {
  checkParmsCount $# 2 'getVMUrl'
  local CONST_FILE_PATH="./../vmware/data/${1}_ver_url.cfg"
  local VAR_RESULT=''
  if ! isFileExistAndRead "$CONST_FILE_PATH"; then
    exitError "file $CONST_FILE_PATH not found"
  fi
  VAR_RESULT=$(cat $CONST_FILE_PATH | grep "$2$COMMON_CONST_DATA_CFG_SEPARATOR" | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $2}') || exitChildError "$VAR_RESULT"
  if isEmpty "$VAR_RESULT"; then
    exitError "missing url for VM template $1 version $2 in file $CONST_FILE_PATH"
  fi
  echo "$VAR_RESULT"
}
#$1 vm template
getAvailableVMTemplateVersions(){
  checkParmsCount $# 1 'getAvailableVMTemplateVersions'
  local CONST_FILE_PATH="./../vmware/data/${1}_ver_url.cfg"
  local VAR_RESULT=''
  local VAR_VM_TEMPLATE=''
  local VAR_FOUND=$COMMON_CONST_FALSE
  if ! isFileExistAndRead "$CONST_FILE_PATH"; then
    exitError "file $CONST_FILE_PATH not found"
  fi
  for VAR_VM_TEMPLATE in $COMMON_CONST_VM_TEMPLATES_POOL; do
    if [ "$1" = "$VAR_VM_TEMPLATE" ]; then
      VAR_RESULT=$(sed 1d $CONST_FILE_PATH | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $1}'| awk '{ORS=FS} 1') || exitChildError "$VAR_RESULT"
      VAR_FOUND=$COMMON_CONST_TRUE
      break
    fi
  done
  if ! isTrue $VAR_FOUND; then
    exitError "VM template $1 not found"
  fi
  if isEmpty "$VAR_RESULT"; then
    exitError "cannot found any version for VM template $1 in file $CONST_FILE_PATH"
  fi
  echo "$VAR_RESULT"
}
#$1 vm template
getDefaultVMTemplateVersion(){
  checkParmsCount $# 1 'getDefaultVMTemplateVersion'
  local CONST_FILE_PATH="./../vmware/data/${1}_ver_url.cfg"
  local VAR_RESULT=''
  local VAR_VM_TEMPLATE=''
  local VAR_FOUND=$COMMON_CONST_FALSE
  if ! isFileExistAndRead "$CONST_FILE_PATH"; then
    exitError "file $CONST_FILE_PATH not found"
  fi
  for VAR_VM_TEMPLATE in $COMMON_CONST_VM_TEMPLATES_POOL; do
    if [ "$1" = "$VAR_VM_TEMPLATE" ]; then
      VAR_RESULT=$(sed -n 2p $CONST_FILE_PATH | awk -F: '{print $1}') || exitChildError "$VAR_RESULT"
      VAR_FOUND=$COMMON_CONST_TRUE
      break
    fi
  done
  if ! isTrue $VAR_FOUND; then
    exitError "VM template $1 not found"
  fi
  if isEmpty "$VAR_RESULT"; then
    exitError "missing default version for VM template $1 in file $CONST_FILE_PATH"
  fi
  echo "$VAR_RESULT"
}
#$1 path
getParentDirectoryPath(){
  checkParmsCount $# 1 'getParentDirectoryPath'
  echo $1 | rev | sed 's!/!:!' | rev | awk -F: '{print $1}'
}
#$1 VMID, $2 esxi host
powerOnVM()
{
  checkParmsCount $# 2 'powerOnVM'
  local VAR_RESULT=''
  local VAR_COUNT=$COMMON_CONST_ESXI_TRY_LONG
  local VAR_TRY=$COMMON_CONST_ESXI_TRY_NUM
  echo "Required power on VMID $1 on $2 host"
  VAR_RESULT=$($SSH_CLIENT $2 "if [ \"\$(vim-cmd vmsvc/power.getstate $1 | sed -e '1d')\" != 'Powered on' ]; then vim-cmd vmsvc/power.on $1; else echo $COMMON_CONST_TRUE; fi") || exitChildError "$VAR_RESULT"
  if isTrue "$VAR_RESULT"; then return $COMMON_CONST_EXIT_SUCCESS; else echoResult "$VAR_RESULT"; fi
  while true; do
    echo -n '.'
    sleep $COMMON_CONST_ESXI_SLEEP_LONG
    #check status
    VAR_RESULT=$($SSH_CLIENT $2 "if [ \"\$(vim-cmd vmsvc/power.getstate $1 | sed -e '1d')\" = 'Powered on' ]; then echo $COMMON_CONST_TRUE; fi") || exitChildError "$VAR_RESULT"
    if isTrue "$VAR_RESULT"; then break; fi
    VAR_COUNT=$((VAR_COUNT-1))
    if [ $VAR_COUNT -eq 0 ]; then
      VAR_TRY=$((VAR_TRY-1))
      if [ $VAR_TRY -eq 0 ]; then  #still not powered on, force kill vm
        exitError "failed power on the VMID $1 on $2 host. Check VM Tools install and running"
      else
        echo ''
        echo "Still cannot power on the VMID $1 on $2 host, left $VAR_TRY attempts"
      fi;
      VAR_COUNT=$COMMON_CONST_ESXI_TRY_LONG
    fi
  done
  echo ''
  return $COMMON_CONST_EXIT_SUCCESS
}
#$1 VMID, $2 esxi host
powerOffVM()
{
  checkParmsCount $# 2 'powerOffVM'
  local VAR_RESULT=''
  local VAR_COUNT=$COMMON_CONST_ESXI_TRY_LONG
  local VAR_TRY=$COMMON_CONST_ESXI_TRY_NUM
  echo "Required power off VMID $1 on $2 host"
  VAR_RESULT=$($SSH_CLIENT $2 "if [ \"\$(vim-cmd vmsvc/power.getstate $1 | sed -e '1d')\" != 'Powered off' ]; then vim-cmd vmsvc/power.shutdown $1; else echo $COMMON_CONST_TRUE; fi") || exitChildError "$VAR_RESULT"
  if isTrue "$VAR_RESULT"; then return $COMMON_CONST_EXIT_SUCCESS; else echoResult "$VAR_RESULT"; fi
  while true; do
    echo -n '.'
    sleep $COMMON_CONST_ESXI_SLEEP_LONG
    #check status
    VAR_RESULT=$($SSH_CLIENT $2 "if [ \"\$(vim-cmd vmsvc/power.getstate $1 | sed -e '1d')\" = 'Powered off' ]; then echo $COMMON_CONST_TRUE; fi") || exitChildError "$VAR_RESULT"
    if isTrue "$VAR_RESULT"; then break; fi
    VAR_COUNT=$((VAR_COUNT-1))
    if [ $VAR_COUNT -eq 0 ]; then
      VAR_TRY=$((VAR_TRY-1))
      if [ $VAR_TRY -eq 0 ]; then  #still running, force kill vm
        echo "Failed standard power off the VMID $1 on $2 host, use force power off."
        $SSH_CLIENT $PRM_HOST "esxcli vm process kill --type force --world-id $VAR_RESULT"
        if ! isRetValOK; then exitError; fi
        sleep $COMMON_CONST_ESXI_SLEEP_LONG
        VAR_RESULT=$($SSH_CLIENT $PRM_HOST "vmdumper -l | grep -i 'displayName=\"$PRM_VMNAME\"' | awk '{print \$1}' | awk -F'/|=' '{print \$(NF)}'") || exitChildError "$VAR_RESULT"
        if ! isEmpty "$VAR_RESULT"; then
          exitError "failed force power off the VMID $1 on $2 host"
        fi
      else
        echo ''
        echo "Still cannot standard power off the VMID $1 on $2 host, left $VAR_TRY attempts"
      fi;
      VAR_COUNT=$COMMON_CONST_ESXI_TRY_LONG
    fi
  done
  echo ''
  return $COMMON_CONST_EXIT_SUCCESS
}
#$1 vm name, $2 esxi host
getIpAddressByVMName()
{
  checkParmsCount $# 2 'getIpAddressByVMName'
  local VAR_RESULT=''
  local VAR_COUNT=$COMMON_CONST_ESXI_TRY_LONG
  local VAR_TRY=$COMMON_CONST_ESXI_TRY_NUM
  local VAR_VM_ID=''
  VAR_VM_ID=$(getVMIDByVMName "$1" "$2") || exitChildError "$VAR_VM_ID"
  while true
  do
    VAR_RESULT=$($SSH_CLIENT $2 "vim-cmd vmsvc/get.guest $VAR_VM_ID | grep 'ipAddress = \"' | \
        sed -n 1p | cut -d '\"' -f2") || exitChildError "$VAR_RESULT"
    #vim-cmd vmsvc/get.guest vmid |grep -m 1 "ipAddress = \""
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
#$1 vm template, list with space delimiter. Return value format 'vmname:host:vmid'
getVmsPoolEsxi(){
  checkParmsCount $# 1 'getVmsPoolEsxi'
  local VAR_CUR_ESXI=''
  local VAR_RESULT=''
  for VAR_CUR_ESXI in $COMMON_CONST_ESXI_HOSTS_POOL; do
    local VAR_RESULT1
    checkSSHKeyExistEsxi "$VAR_CUR_ESXI"
    VAR_RESULT1=$($SSH_CLIENT $VAR_CUR_ESXI "vim-cmd vmsvc/getallvms | sed -e '1d' | \
awk '{print \$1\":\"\$2}' | grep ':'$1'-' | awk -F: '{print \$2\":$VAR_CUR_ESXI:\"\$1}'") || exitChildError "$VAR_RESULT1"
    VAR_RESULT=$VAR_RESULT$VAR_RESULT1
  done
  echo "$VAR_RESULT"
}
#$1 vm name, $2 esxi host
getVMIDByVMName() {
  checkParmsCount $# 2 'getVMIDByVMName'
  local VAR_RESULT
  VAR_RESULT=$($SSH_CLIENT $2 "vim-cmd vmsvc/getallvms | sed -e '1d' -e 's/ \[.*$//' \
| awk '\$1 ~ /^[0-9]+$/ {print \$1\":\"\$2\":\"}' | grep ':'$1':' | awk -F: '{print \$1}'") || exitChildError "$VAR_RESULT"
  echo "$VAR_RESULT"
}
#$1 VMID, $2 esxi host
getVMNameByVMID() {
  checkParmsCount $# 2 'getVMNamebyVMID'
  local VAR_RESULT
  VAR_RESULT=$($SSH_CLIENT $2 "vim-cmd vmsvc/getallvms | sed -e '1d' -e 's/ \[.*$//' \
| awk '\$1 ~ /^[0-9]+$/ {print \$1\":\"substr(\$0,8,80)}' | grep $1':' | awk -F: '{print \$2}'") || exitChildError "$VAR_RESULT"
  echo "$VAR_RESULT"
}
#$1 title, $2 value, [$3] allow values
checkCommandExist() {
  checkParmsCount $# 3 'checkCommandExist'
  local VAR_CHAR='\n'
  if isEmpty "$2"
  then
    exitError "option $1 missing"
  elif ! isEmpty "$3"
  then
    checkCommandValue "$1" "$2" "$3"
  fi
  if isEmpty "$VAR_COMMAND_VALUE"; then
    VAR_CHAR=''
  fi
  VAR_COMMAND_VALUE="$VAR_COMMAND_VALUE${VAR_CHAR}Option ${1}=${2}"
}
#$1 vm name , $2 esxi host, $3 vm OS version, $4 pause message
checkTriggerTemplateVM(){
  checkParmsCount $# 4 'checkTriggerTemplateVM'
  local VAR_VM_ID=''
  local VAR_VM_IP=''
  local VAR_INPUT=''
  local VAR_RESULT=''
  local VAR_LOG=''
  pausePrompt "Pause 1 of 3: Check guest OS type, necessary virtual hardware on template VM $1 on $2 host: \
vCPUs - $COMMON_CONST_ESXI_DEFAULT_VCPU_COUNT, Memory - $COMMON_CONST_ESXI_DEFAULT_MEMORY_SIZE, HDD - $COMMON_CONST_ESXI_DEFAULT_HDD_SIZE"
  VAR_VM_ID=$(getVMIDByVMName "$1" "$2") || exitChildError "$VAR_VM_ID"
  VAR_RESULT=$(powerOnVM "$VAR_VM_ID" "$2") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  if ! isAutoYesMode; then
    echoResult "$4"
  fi
  pausePrompt "Pause 2 of 3: Manually make changes on template VM $1 on $2 host"
  VAR_VM_IP=$(getIpAddressByVMName "$1" "$2") || exitChildError "$VAR_VM_IP"
  echo "VM ${1} ip address: $VAR_VM_IP"
  $SSH_COPY_ID root@$VAR_VM_IP
  if ! isRetValOK; then exitError; fi
  $SCP_CLIENT $ENV_SCRIPT_DIR_NAME/trigger/${1}_create.sh root@$VAR_VM_IP:
  if ! isRetValOK; then exitError; fi
  echo "Start ${1}_create.sh executing on template VM ${1} ip $VAR_VM_IP on $2 host"
  #exec trigger script
  VAR_RESULT=$($SSH_CLIENT root@$VAR_VM_IP "chmod u+x ${1}_create.sh;./${1}_create.sh $ENV_SSH_USER_NAME $ENV_SSH_USER_PASS $1 $3; \
if [ -r ${1}_create.ok ]; then cat ${1}_create.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_RESULT"
  if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
    VAR_LOG=$($SSH_CLIENT root@$VAR_VM_IP "if [ -r ${1}_create.log ]; then cat ${1}_create.log; fi") || exitChildError "$VAR_LOG"
    if ! isEmpty "$VAR_LOG"; then echo "Stdout:\n$VAR_LOG"; fi
  fi
  VAR_LOG=$($SSH_CLIENT root@$VAR_VM_IP "if [ -r ${1}_create.err ]; then cat ${1}_create.err; fi") || exitChildError "$VAR_LOG"
  if ! isEmpty "$VAR_LOG"; then echo "Stderr:\n$VAR_LOG"; fi
  if ! isTrue "$VAR_RESULT"; then
    exitError "failed execute ${1}_create.sh on template VM ${1} ip $VAR_VM_IP on $2 host"
  fi
  pausePrompt "Pause 3 of 3: Last check template VM ${1} ip $VAR_VM_IP on $2 host"
  if isAutoYesMode; then
    sleep $COMMON_CONST_ESXI_SLEEP_LONG
  fi
  VAR_RESULT=$(powerOffVM "$VAR_VM_ID" "$2") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
}
#$1 title, $2 value, $3 allowed values
checkCommandValue() {
  checkParmsCount $# 3 'checkCommandValue'
  local VAR_COMMAND=''
  local VAR_FOUND=$COMMON_CONST_FALSE
  for VAR_COMMAND in $3
  do
    if [ "$VAR_COMMAND" = "$2" ]
    then
      VAR_FOUND=$COMMON_CONST_TRUE
    fi
  done
  if ! isTrue "$VAR_FOUND"
  then
    exitError "option $1 value $2 invalid. Allowed values: $3"
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
#$1 directory name, $2 error message prefix
checkDirectoryForNotExist() {
  checkParmsCount $# 2 'checkDirectoryForNotExist'
  if ! isEmpty "$1" && [ -d "$1" ]
  then
    exitError "$2directory $1 already exist"
  fi
}
#$1 file name, $2 error message prefix
checkFileForNotExist() {
  checkParmsCount $# 2 'checkFileForNotExist'
  if isFileExistAndRead "$1"; then
    exitError "file $1 already exist"
  fi
}
#$1 keyID
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
  local VAR_DEPENDENCE=''
  for VAR_DEPENDENCE in $1
  do
    if ! isCommandExist "$VAR_DEPENDENCE"
    then
      if isLinuxOS
      then
        local VAR_LINUX_BASED
        VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
        if isAPTLinux "$VAR_LINUX_BASED"
        then
          sudo apt -y install $VAR_DEPENDENCE
        elif isRPMLinux "$VAR_LINUX_BASED"
        then
          sudo yum -y install $VAR_DEPENDENCE
        fi
      elif isFreeBSDOS
      then
        setenv ASSUME_ALWAYS_YES yes
        pkg install $VAR_DEPENDENCE
        setenv ASSUME_ALWAYS_YES
      fi
      #repeat check for availability dependence
      if ! isCommandExist $VAR_DEPENDENCE
      then
        exitError "dependence $VAR_DEPENDENCE not found"
      fi
    fi
  done
}

checkRequiredFiles() {
  checkParmsCount $# 1 'checkRequiredFiles'
  local VAR_FILE=''
  for VAR_FILE in $1
  do
    if ! isFileExistAndRead $VAR_FILE
    then
      exitError "file $VAR_FILE not found"
    fi
  done
}

checkLinuxAptOrRpm(){
  checkParmsCount $# 0 'checkLinuxAptOrRpm'
  if isFileExistAndRead "/etc/debian_version"; then
      echo 'apt'
  elif isFileExistAndRead "/etc/redhat-release"; then
    echo 'rpm'
  else
    exitError "unknown Linux based package system"
  fi
}
#$1 env name, $2
checkNotEmptyEnvironment(){
  checkParmsCount $# 1 'checkNotEmptyEnvironment'
  local VAR_ENV_VALUE=''
  VAR_ENV_VALUE=$(eval echo \$${1}) || exitChildError "$VAR_ENV_VALUE"
  if isEmpty "$VAR_ENV_VALUE"; then
    setErrorEnvironment "set constant $1"
  fi
}
#$1 host
checkSSHKeyExistEsxi(){
  checkParmsCount $# 1 'checkSSHKeyExistEsxi'
  local CONST_HV_SSHKEYS_DIRNAME="/etc/ssh/keys-$ENV_SSH_USER_NAME"
  local VAR_RESULT=''
  VAR_RESULT=$($SSH_CLIENT $1 "if [ ! -d $CONST_HV_SSHKEYS_DIRNAME ]; \
then mkdir $CONST_HV_SSHKEYS_DIRNAME; \
cat > $CONST_HV_SSHKEYS_DIRNAME/authorized_keys; else cat > /dev/null; fi; \
echo $COMMON_CONST_TRUE" < $HOME/.ssh/$ENV_SSH_KEYID) || exitChildError "$VAR_RESULT"
}
#$1 message
setErrorEnvironment()
{
  checkParmsCount $# 1 'setErrorEnvironment'
  VAR_ENVIRONMENT_ERROR="$1 in environment.sh"
}
#$1 description, [$2] allowed autoyes
targetDescription(){
  local VAR_MODE=$COMMON_CONST_FALSE
  if ! isEmpty "$VAR_ENVIRONMENT_ERROR"; then
    echo "Error: $VAR_ENVIRONMENT_ERROR"
    exit $COMMON_CONST_EXIT_ERROR
  fi
  VAR_TARGET_DESCRIPTION=$1
  VAR_MODE=${2:-$COMMON_CONST_TRUE}
  checkCommandValue 'modeAutoYes' "$VAR_MODE" "$COMMON_CONST_BOOL_VALUES"
  if ! isTrue "$VAR_MODE"; then
    VAR_AUTO_YES=$COMMON_CONST_NULL
  fi
}
#$1 total stage, $2 stage description
beginStage(){
  checkParmsCount $# 2 'beginStage'
  VAR_STAGE_NUM=$((VAR_STAGE_NUM+1))
  if [ $VAR_STAGE_NUM -gt $1 ]
  then
    exitError 'too many stages'
  fi
  echo -n "Stage $VAR_STAGE_NUM of $1: $2..."
}

doneStage(){
  checkParmsCount $# 0 'doneStage'
  echo ' Done'
}

doneFinalStage(){
  checkParmsCount $# 0 'doneFinalStage'
  if [ $VAR_STAGE_NUM -gt 0 ]
  then
    doneStage
  fi
  echo "Success target $(getFileNameWithoutExt "$ENV_SCRIPT_FILE_NAME")!"
}
#[$1] message
exitOK(){
  if ! isEmpty "$1"; then
    echo $1
  fi
  if ! isEmpty "$VAR_START_TIME"; then
    getElapsedTime "$VAR_START_TIME" "$COMMON_CONST_FALSE"
  fi
  if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
    echo "Stop session [$$] with $COMMON_CONST_EXIT_SUCCESS (Ok)"
  fi
  exit $COMMON_CONST_EXIT_SUCCESS
}
#[$1] message, [$2] child error
exitError(){
  if isEmpty "$2"; then
    echo -n "Error: ${1:-$COMMON_CONST_ERROR_MESS_UNKNOWN}"
    echo ". See '$ENV_SCRIPT_FILE_NAME --help'"
    if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
      getTrace
    fi
  else
    echo "$1"
  fi
  if ! isEmpty "$VAR_START_TIME"; then
    getElapsedTime "$VAR_START_TIME" "$COMMON_CONST_FALSE"
  fi
  if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
    echo "Stop session [$$] with $COMMON_CONST_EXIT_ERROR (Error)"
  fi
  exit $COMMON_CONST_EXIT_ERROR
}

getTrace(){
  checkParmsCount $# 0 'getTrace'
  local VAR_TRACE=""
  local VAR_CP=$$ # PID of the script itself [1]
  local VAR_PP=''
  local VAR_CMD_LINE=''
  while true # safe because "all starts with init..."
  do
    VAR_CMD_LINE=$(ps -o args= -f -p $VAR_CP) || exitChildError "$VAR_CMD_LINE"
    VAR_PP=$(grep PPid /proc/$VAR_CP/status | awk '{ print $2; }') || exitChildError "$VAR_PP" # [2]
    VAR_TRACE="$VAR_TRACE [$VAR_CP]:$VAR_CMD_LINE\n"
    if [ "$VAR_CP" = "1" ]; then # we reach 'init' [PID 1] => backtrace end
      break
    fi
    VAR_CP=$VAR_PP
  done
  echo "Begin trace"
  echo -n "$VAR_TRACE" | tac | grep -n ":" | tac # using tac to "print in reverse" [3]
  echo "End trace"
}
#$1 message
exitChildError(){
  checkParmsCount $# 1 'exitChildError'
  if isEmpty "$1"; then
    exitError
  else
    exitError "$1" "$COMMON_CONST_EXIT_ERROR"
  fi
}
#$1 options count, $2 must be count, $3 usage message, $4 sample message, $5 add tooltip message
echoHelp(){
  checkParmsCount $# 5 'echoHelp'
  local VAR_TOOL_TIP=''
  if isTrue "$VAR_NEED_HELP"; then
    if [ "$VAR_AUTO_YES" != "$COMMON_CONST_NULL" ]; then
      echo "Usage: $ENV_SCRIPT_FILE_NAME [-y] $3"
    else
      echo "Usage: $ENV_SCRIPT_FILE_NAME $3"
    fi
    echo "Sample: $ENV_SCRIPT_FILE_NAME $4"
    if ! isEmpty "$5"
    then
      if [ "$VAR_AUTO_YES" != "$COMMON_CONST_NULL" ]; then
        VAR_TOOL_TIP="$COMMON_CONST_TOOL_TIP. $5"
      else
        VAR_TOOL_TIP="$5"
      fi
    else
      if [ "$VAR_AUTO_YES" != "$COMMON_CONST_NULL" ]; then
        VAR_TOOL_TIP=$COMMON_CONST_TOOL_TIP
      fi
    fi
    if ! isEmpty "$VAR_TOOL_TIP"; then
      echo "Tooltip: $VAR_TOOL_TIP"
    fi
    exit $COMMON_CONST_EXIT_SUCCESS
  fi
}
#1 pause message
pausePrompt()
{
  checkParmsCount $# 1 'pausePrompt'
  local VAR_INPUT=''
  if isAutoYesMode; then return; fi
  read -r -p "$1. When you are done, press Enter for resume procedure " VAR_INPUT
}

startPrompt(){
  checkParmsCount $# 0 'startPrompt'
  local VAR_INPUT=''
  local VAR_YES=$COMMON_CONST_FALSE
  local VAR_DO_FLAG=$COMMON_CONST_TRUE
  echoResult "$VAR_COMMAND_VALUE"
  if ! isAutoYesMode; then
    while isTrue "$VAR_DO_FLAG"; do
      read -r -p 'Do you want to continue? [y/N] ' VAR_INPUT
      if isEmpty "$VAR_INPUT"; then
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
    if ! isTrue $VAR_YES; then
      exitOK 'Good bye!'
    fi
  fi
  VAR_START_TIME=$(date +%Y%t%m%t%d%t%H%t%M%t%S)
  if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
    echo "Start session [$$]"
  fi
}
#$1 parameter
checkAutoYes() {
  checkParmsCount $# 1 'checkAutoYes'
  echo "Target: $(getFileNameWithoutExt "$ENV_SCRIPT_FILE_NAME")"
  if [ "$1" = "-y" ]; then
    if [ "$VAR_AUTO_YES" = "$COMMON_CONST_NULL" ]; then
      exitError 'not allowed batch mode, try without -y option'
    fi
    VAR_AUTO_YES=$COMMON_CONST_TRUE
    return $COMMON_CONST_TRUE
  elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Description: $VAR_TARGET_DESCRIPTION"
    VAR_NEED_HELP=$COMMON_CONST_TRUE
    return $COMMON_CONST_TRUE
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
  echo $1 | rev | sed 's/[.]/:/' | rev | awk -F: '{print $1}'
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
put_vmtools_to_esxi(){
  checkParmsCount $# 1 'put_vmtools_to_esxi'
  local VAR_TMP_DIR_PATH
  VAR_TMP_DIR_PATH=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_PATH"
  tar -xzf $COMMON_CONST_LOCAL_VMTOOLS_PATH --strip-component=2 -C $VAR_TMP_DIR_PATH
  if ! isRetValOK; then exitError; fi
  $SCP_CLIENT -r $VAR_TMP_DIR_PATH/* $1:$COMMON_CONST_ESXI_VMTOOLS_PATH/
  if ! isRetValOK; then exitError; fi
  rm -fR $VAR_TMP_DIR_PATH
  if ! isRetValOK; then exitError; fi
}
#$1 esxi host
put_ovftool_to_esxi(){
  checkParmsCount $# 1 'put_ovftool_to_esxi'
  $SCP_CLIENT -r $COMMON_CONST_LOCAL_OVFTOOL_PATH $1:$COMMON_CONST_ESXI_TOOLS_PATH/
  if ! isRetValOK; then exitError; fi
  $SSH_CLIENT $1 "sed -i 's@^#!/bin/bash@#!/bin/sh@' $COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool"
  if ! isRetValOK; then exitError; fi
}
#$1 esxi host
put_template_tools_to_esxi(){
  checkParmsCount $# 1 'put_template_tools_to_esxi'
  $SCP_CLIENT -r $ENV_SCRIPT_DIR_NAME/template $1:$COMMON_CONST_ESXI_TEMPLATES_PATH/
  if ! isRetValOK; then exitError; fi
}
#$1 return result
echoResult(){
  checkParmsCount $# 1 'echoResult'
  if ! isEmpty "$1"; then
    echo "$1"
  fi
}
#$1 message
echoWarning(){
  checkParmsCount $# 1 'echoWarning'
  if ! isEmpty "$1"; then
    echo "Warning: $1"
  fi
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
  VAR_LOCAL_MAJOR=$(echo $1 | awk -F. '{print $1}') || exitChildError "$VAR_LOCAL_MAJOR"
  VAR_LOCAL_MINOR=$(echo $1 | awk -F. '{print $2}') || exitChildError "$VAR_LOCAL_MINOR"
  VAR_LOCAL_PATCH=$(echo $1 | awk -F. '{print $3}') || exitChildError "$VAR_LOCAL_PATCH"
  VAR_LOCAL_TEST=$(echo $1 | awk -F. '{print $4}') || exitChildError "$VAR_LOCAL_TEST"
  VAR_REMOTE_MAJOR=$(echo $2 | awk -F. '{print $1}') || exitChildError "$VAR_REMOTE_MAJOR"
  VAR_REMOTE_MINOR=$(echo $2 | awk -F. '{print $2}') || exitChildError "$VAR_REMOTE_MINOR"
  VAR_REMOTE_PATCH=$(echo $2 | awk -F. '{print $3}') || exitChildError "$VAR_REMOTE_PATCH"
  VAR_REMOTE_TEST=$(echo $2 | awk -F. '{print $4}') || exitChildError "$VAR_REMOTE_TEST"
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
  ! isEmpty "$1" && [ -r "$1" ]
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
  isTrue "$VAR_AUTO_YES"
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
  [ "$?" = "$COMMON_CONST_EXIT_SUCCESS" ]
}

isRetValOK(){
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
  local VAR_VM_ID=''
  VAR_RESULT=$(getVMSnapshotIDByName "$1" "$2" "$3") || exitChildError "$VAR_RESULT"
  ! isEmpty "$VAR_RESULT"
}
