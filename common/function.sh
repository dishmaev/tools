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

#$1 project action ($COMMON_CONST_PROJECT_ACTION_CREATE etc), $2 start time, $3 stop time, $4 result bool, $5 src file path, $6 bin file path, $7 log file path
addHistoryLog(){
  checkParmsCount $# 7 'addHistoryLog'
  local VAR_RESULT='error'
  local VAR_ESPD=''
  local VAR_STOP_STRING=''
  local VAR_FILE_NAME=''
  local VAR_FILE_PATH=''
  if isTrue "$4"; then VAR_RESULT='ok'; fi
  VAR_STOP_STRING=$(getTimeAsString "$3" "$COMMON_CONST_TRUE")
  VAR_ESPD=$(getElapsedTime "$2" "$3" "$COMMON_CONST_FALSE") || exitChildError "$VAR_ESPD"
  VAR_FILE_NAME=${VAR_STOP_STRING}_${VAR_ESPD}_${1}_${VAR_RESULT}.tar.gz
  VAR_FILE_PATH=$ENV_PROJECT_HISTORY_PATH/$VAR_FILE_NAME
  if isFileExistAndRead "$VAR_FILE_PATH"; then
    exitError "history file $VAR_FILE_PATH already exist"
  fi
  if ! isEmpty "$5"; then
    if isFileExistAndRead "$5"; then
      VAR_FILE_NAME=$(getFileNameFromUrlString "$5") || exitChildError "$VAR_FILE_NAME"
      tar -rvf $VAR_FILE_PATH -C $ENV_PROJECT_TMP_PATH $VAR_FILE_NAME
      checkRetValOK
    else
      exitError "source file $5 not found"
    fi
  fi
  if ! isEmpty "$6"; then
    if isFileExistAndRead "$6"; then
      VAR_FILE_NAME=$(getFileNameFromUrlString "$6") || exitChildError "$VAR_FILE_NAME"
      tar -rvf $VAR_FILE_PATH -C $ENV_PROJECT_TMP_PATH $VAR_FILE_NAME
      checkRetValOK
    else
      exitError "binary file $6 not found"
    fi
  fi
  if isFileExistAndRead "$7"; then
    VAR_FILE_NAME=$(getFileNameFromUrlString "$7") || exitChildError "$VAR_FILE_NAME"
    tar -rvf $VAR_FILE_PATH -C $ENV_PROJECT_TMP_PATH $VAR_FILE_NAME
    checkRetValOK
  else
    exitError "log file $7 not found"
  fi
  if ! isFileExistAndRead "$VAR_FILE_PATH"; then
    echoWarning "history file $VAR_FILE_PATH not found"
  fi
  return $COMMON_CONST_EXIT_SUCCESS
}
#$1 vm ip, $2 vm ssh port, $3 VAR_REMOTE_SCRIPT_FILE_NAME, $4 $VAR_LOG_TAR_FILE_PATH
packLogFiles(){
  checkParmsCount $# 4 'packLogFiles'
  local VAR_LOG_TAR_FILE_NAME=''
  VAR_LOG_TAR_FILE_NAME=$(getFileNameFromUrlString "$4") || exitChildError "$VAR_LOG_TAR_FILE_PATH"
  $SSH_CLIENT -p $2 $1 "tar -cvf $VAR_LOG_TAR_FILE_NAME --exclude='*.sh' ${3}*.*"
  checkRetValOK
  $SCP_CLIENT -P $2 ${1}:$VAR_LOG_TAR_FILE_NAME $4
  checkRetValOK
  return $COMMON_CONST_EXIT_SUCCESS
}
#$1 vm types pool
getAvailableVMType(){
  checkParmsCount $# 1 'getAvailableVMType'
  local VAR_RESULT=''
  local VAR_CUR_VM_TYPE=''
  local VAR_CUR_HOST=''
  local VAR_HOST_ERROR=''
  for VAR_CUR_VM_TYPE in $1; do
    if [ "$VAR_CUR_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ] && ! isEmpty "$COMMON_CONST_ESXI_HOSTS_POOL"; then
      VAR_HOST_ERROR="$COMMON_CONST_FALSE"
      for VAR_CUR_HOST in $COMMON_CONST_ESXI_HOSTS_POOL; do
        if ! isHostAvailableEx "$VAR_CUR_HOST"; then
          VAR_HOST_ERROR="$COMMON_CONST_TRUE"
          break
        fi
      done
      if ! isTrue "$VAR_HOST_ERROR"; then
        VAR_RESULT="$COMMON_CONST_VMWARE_VM_TYPE"
        break
      fi
    elif [ "$VAR_CUR_VM_TYPE" = "$COMMON_CONST_DOCKER_VM_TYPE" ]; then
#      echoWarning "TO-DO support Docker containers"
      :
    elif [ "$VAR_CUR_VM_TYPE" = "$COMMON_CONST_KUBERNETES_VM_TYPE" ]; then
#      echoWarning "TO-DO support Kubernetes containers"
      :
    elif [ "$VAR_CUR_VM_TYPE" = "$COMMON_CONST_VBOX_VM_TYPE" ]; then
      if isCommandExist "vboxmanage" && isCommandExist "vagrant"; then
        VAR_RESULT=$VAR_CUR_VM_TYPE
        break
      fi
    fi
  done
  echo "$VAR_RESULT"
}
#$1 project action (build or develop), $2 suite, $3 vm role
getProjectVMForAction(){
  checkParmsCount $# 3 'removeKnownHosts'
  local FCONST_PROJECT_BUILD_ACTION='build'
  local FCONST_PROJECT_DEPLOY_ACTION='deploy'
  local VAR_RESULT=''
  local VAR_CONFIG_FILE_NAME=''
  local VAR_CONFIG_FILE_PATH=''
  local VAR_CUR_VM_TYPE=''
  local VAR_CUR_VM=''
  local VAR_VM_NAME=''
  local VAR_HOST=''
  if [ "$1" != "$FCONST_PROJECT_BUILD_ACTION" ] && [ "$1" != "$FCONST_PROJECT_DEPLOY_ACTION" ]; then
    exitError "project action $1 not support for getProjectVMForAction"
  fi
  VAR_CONFIG_FILE_NAME=${2}_${3}.cfg
  VAR_CONFIG_FILE_PATH=$ENV_PROJECT_DATA_PATH/${VAR_CONFIG_FILE_NAME}
  for VAR_CUR_VM_TYPE in $ENV_VM_TYPES_POOL; do
    VAR_CUR_VM=$(cat $VAR_CONFIG_FILE_PATH | grep -E "^$VAR_CUR_VM_TYPE" | cat) || exitChildError "$VAR_CUR_VM"
    if isEmpty "$VAR_CUR_VM"; then continue; fi
    VAR_VM_NAME=$(echo $VAR_CUR_VM | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $3}') || exitChildError "$VAR_VM_NAME"
    if [ "$VAR_CUR_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
      VAR_HOST=$(echo $VAR_CUR_VM | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $4}') || exitChildError "$VAR_HOST"
      if isHostAvailableEx "$VAR_HOST" && isVMExistEx "$VAR_VM_NAME" "$VAR_HOST"; then
        VAR_RESULT=$VAR_CUR_VM
        break
      fi
    elif [ "$VAR_CUR_VM_TYPE" = "$COMMON_CONST_DOCKER_VM_TYPE" ]; then
#      echoWarning "TO-DO support Docker containers"
      :
    elif [ "$VAR_CUR_VM_TYPE" = "$COMMON_CONST_KUBERNETES_VM_TYPE" ]; then
#      echoWarning "TO-DO support Kubernetes containers"
      :
    elif [ "$VAR_CUR_VM_TYPE" = "$COMMON_CONST_VBOX_VM_TYPE" ]; then
      if isCommandExist "vboxmanage" && isCommandExist "vagrant" && isVMExistVb "$VAR_VM_NAME"; then
        VAR_RESULT=$VAR_CUR_VM
        break
      fi
    fi
  done
  echo "$VAR_RESULT"
}

removeKnownHosts(){
  checkParmsCount $# 0 'removeKnownHosts'
  if isFileExistAndRead "$HOME/.ssh/known_hosts"; then
    rm $HOME/.ssh/known_hosts
  fi
}

#$1 regular string
getOVFToolPassword(){
  checkParmsCount $# 1 'getOVFToolPassword'
  local FCONST_SPEC_SYMBOLS="@!#$^&*?[(){}<>~;'\"\`\|=,"
  local VAR_LENGTH=0
  local VAR_RESULT=''
  local VAR_INDEX=0;
  local VAR_CHAR='';
  local VAR_TEST='';
  VAR_LENGTH=${#1}
  while true; do
    VAR_INDEX=$((VAR_INDEX+1))
    if [ $VAR_INDEX -gt ${#1} ]; then break; fi
    VAR_CHAR=$(echo "$1" | cut -b $VAR_INDEX)
    VAR_TEST=$(echo "$VAR_CHAR" | grep -E '['$FCONST_SPEC_SYMBOLS']')
    if [ ! -z $VAR_TEST ]; then
      VAR_CHAR=$(printf '%%%x' "'$VAR_TEST")
    fi
    VAR_RESULT=$VAR_RESULT$VAR_CHAR
  done
  echo "$VAR_RESULT"
}
#$1 char, $2 count
getCharCountString(){
  checkParmsCount $# 2 'getCharCountString'
  local VAR_COUNT=1
  while true; do
    if [ "$VAR_COUNT" -gt "$2" ]; then break; fi
    VAR_COUNT=$((VAR_COUNT+1))
    echo -n $1
  done
}

getTime(){
  checkParmsCount $# 0 'getTime'
  echo "$(date +%Y%t%m%t%d%t%H%t%M%t%S)"
}
#$1 time with tab delimiter, $2 $COMMON_CONST_TIME_FORMAT_LONG
getTimeAsString(){
  checkParmsCount $# 2 'getTimeAsString'
  local VAR_RESULT=''
  VAR_RESULT=$(echo $1 | $SED 's/[ \t]/-/;s/[ \t]/-/;s/[ \t]/:/2;s/[ \t]/:/2')
  if ! isTrue "$2"; then
    VAR_RESULT=$(echo $VAR_RESULT | awk '{print $2}')
  fi
  echo "$VAR_RESULT"
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
#$1 start time, $2 stop time, $3 $COMMON_CONST_TIME_FORMAT_LONG
getElapsedTime(){
  checkParmsCount $# 3 'getElapsedTime'
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

  VAR_SS_START=$(echo $1 | awk '{printf ("%d", $6)}')
  VAR_SS_STOP=$(echo $2 | awk '{printf ("%d", $6)}')
  VAR_MM_START=$(echo $1 | awk '{printf ("%d", $5)}')
  VAR_MM_STOP=$(echo $2 | awk '{printf ("%d", $5)}')
  VAR_HH_START=$(echo $1 | awk '{printf ("%d", $4)}')
  VAR_HH_STOP=$(echo $2 | awk '{printf ("%d", $4)}')
  VAR_DD_START=$(echo $1 | awk '{printf ("%d", $3)}')
  VAR_DD_STOP=$(echo $2 | awk '{printf ("%d", $3)}')
  VAR_MH_START=$(echo $1 | awk '{printf ("%d", $2)}')
  VAR_MH_STOP=$(echo $2 | awk '{printf ("%d", $2)}')
  VAR_YY_START=$(echo $1 | awk '{printf ("%d", $1)}')
  VAR_YY_STOP=$(echo $2 | awk '{printf ("%d", $1)}')

  if [ "${VAR_SS_STOP}" -lt "${VAR_SS_START}" ]; then VAR_SS_STOP=$((VAR_SS_STOP+60)); VAR_MM_STOP=$((VAR_MM_STOP-1)); fi
  if [ "${VAR_MM_STOP}" -lt "0" ]; then VAR_MM_STOP=$((VAR_MM_STOP+60)); VAR_HH_STOP=$((VAR_HH_STOP-1)); fi
  if [ "${VAR_MM_STOP}" -lt "${VAR_MM_START}" ]; then VAR_MM_STOP=$((VAR_MM_STOP+60)); VAR_HH_STOP=$((VAR_HH_STOP-1)); fi
  if [ "${VAR_HH_STOP}" -lt "0" ]; then VAR_HH_STOP=$((VAR_HH_STOP+24)); VAR_DD_STOP=$((VAR_DD_STOP-1)); fi
  if [ "${VAR_HH_STOP}" -lt "${VAR_HH_START}" ]; then VAR_HH_STOP=$((VAR_HH_STOP+24)); VAR_DD_STOP=$((VAR_DD_STOP-1)); fi

  if [ "${VAR_DD_STOP}" -lt "0" ]; then VAR_DD_STOP=$((VAR_DD_STOP+$(getMhDays $VAR_MH_STOP $VAR_YY_STOP))); VAR_MH_STOP=$((VAR_MH_STOP-1)); fi
  if [ "${VAR_DD_STOP}" -lt "${VAR_DD_START}" ]; then VAR_DD_STOP=$((VAR_DD_STOP+$(getMhDays $VAR_MH_STOP $VAR_YY_STOP))); VAR_MH_STOP=$((VAR_MH_STOP-1)); fi

  if [ "${VAR_MH_STOP}" -lt "0" ]; then VAR_MH_STOP=$((VAR_MH_STOP+12)); VAR_YY_STOP=$((VAR_YY_STOP-1)); fi
  if [ "${VAR_MH_STOP}" -lt "${VAR_MH_START}" ]; then VAR_MH_STOP=$((VAR_MH_STOP+12)); VAR_YY_STOP=$((VAR_YY_STOP-1)); fi

  VAR_ESPD=$(printf "%04d-%02d-%02d %02d:%02d:%02d" $((${VAR_YY_STOP}-${VAR_YY_START})) $((${VAR_MH_STOP}-${VAR_MH_START})) $((${VAR_DD_STOP}-${VAR_DD_START})) $((${VAR_HH_STOP}-${VAR_HH_START})) $((${VAR_MM_STOP}-${VAR_MM_START})) $((${VAR_SS_STOP}-${VAR_SS_START})))

  if ! isTrue "$3"; then
    VAR_ESPD=$(echo $VAR_ESPD | awk '{print $2}')
  fi

  echo "$VAR_ESPD"
}
#$1 $COMMON_CONST_TIME_FORMAT_LONG
showElapsedTime(){
  checkParmsCount $# 1 'showElapsedTime'
  local VAR_START=''
  local VAR_STOP=''
  local VAR_ESPD=''
  local VAR_STOP_TAB=''

  if ! isEmpty "$VAR_START_TIME"; then
    VAR_STOP_TAB="$(getTime)"
    VAR_ESPD=$(getElapsedTime "$VAR_START_TIME" "$VAR_STOP_TAB" "$1") || exitChildError "$VAR_ESPD"
    VAR_START=$(getTimeAsString "$VAR_START_TIME" "$1")
    VAR_STOP=$(getTimeAsString "$VAR_STOP_TAB" "$1")

    echo "Elapsed time: $VAR_ESPD, from $VAR_START to $VAR_STOP"
  fi
}
#$1 VMID, $2 snapshotName, $3 snapshotId
getChildSnapshotsPoolVb(){
  checkParmsCount $# 3 'getChildSnapshotsPoolVb'
  local VAR_RESULT=''
  local VAR_CUR_SSID=''
  local VAR_CUR_SSNAME=''
  local VAR_SS_LIST=''
  VAR_CUR_SSNAME=$(vboxmanage snapshot ${1} list --machinereadable | grep ${3} | $SED -n 1p | awk -F= '{print $1}') || exitChildError "$VAR_CUR_SSNAME"
  if isEmpty "$VAR_CUR_SSNAME"; then
    exitError "snapshot $2 ID $3 not found for VMID $1"
  fi
  if isCommandExist "tac"; then
    VAR_SS_LIST=$(vboxmanage snapshot ${1} list --machinereadable | grep ${VAR_CUR_SSNAME}- | awk -F= '{print $2}' | $SED 's/["]//g' | tac) || exitChildError "$VAR_CUR_SSNAME"
  elif isCommandExist "tail"; then
    VAR_SS_LIST=$(vboxmanage snapshot ${1} list --machinereadable | grep ${VAR_CUR_SSNAME}- | awk -F= '{print $2}' | $SED 's/["]//g' | tail -r) || exitChildError "$VAR_CUR_SSNAME"
  fi
  for VAR_CUR_SSID in $VAR_SS_LIST; do
    VAR_RESULT="$VAR_RESULT $VAR_CUR_SSID"
  done
  echo "$VAR_RESULT"
}
#$1 VMID, $2 snapshotName, $3 snapshotId, $4 host
getChildSnapshotsPoolEx(){
  checkParmsCount $# 4 'getChildSnapshotsPoolEx'
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
      VAR_SS_LIST2=$(echo "$VAR_SS_LIST" | $SED -n '/'$VAR_CUR_SSNAME:$VAR_CUR_SSID:$VAR_CUR_LEVEL'/,$p' | $SED 1d) || exitChildError "$VAR_SS_LIST2"
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
    exitError "snapshot $2 ID $3 not found for VMID $1 on $4 host"
  fi
  echo "$VAR_RESULT"
}
#$1 VMID, $2 snapshotID
getVMSnapshotNameByIDVb(){
  checkParmsCount $# 2 'getVMSnapshotNameByIDVb'
  local VAR_RESULT=''
  VAR_RESULT=$(vboxmanage snapshot ${1} list --machinereadable | $SED -n "/${2}/{g;1!p;};h" | $SED -n 1p | awk -F= '{print $2}' | $SED 's/["]//g') || exitChildError "$VAR_RESULT"
  echo "$VAR_RESULT"
}
#$1 VMID, $2 snapshotID, $3 host
getVMSnapshotNameByIDEx(){
  checkParmsCount $# 3 'getVMSnapshotNameByIDEx'
  local VAR_RESULT=''
  local VAR_CUR_STR=''
  local VAR_CUR_SS_ID=''
  local VAR_FOUND=$COMMON_CONST_FALSE
  VAR_RESULT=$($SSH_CLIENT $3 "vim-cmd vmsvc/snapshot.get $1 | \
  egrep -- '--Snapshot Name|--Snapshot Id' | awk '{ORS=NR%2?FS:RS; print \$4\":\"(length(\$1)-8)/2}' | \
  awk '{print \$1\":\"\$2}' | awk -F: '{print \$1\":\"\$3\":\"\$2}'") || exitChildError "$VAR_RESULT"
  if ! isEmpty "$VAR_RESULT"; then
    for VAR_CUR_STR in $VAR_RESULT; do
      VAR_CUR_SS_ID=$(echo $VAR_CUR_STR | awk -F: '{print $2}') || exitChildError "$VAR_CUR_SS_ID"
      if [ "$2" = "$VAR_CUR_SS_ID" ]; then
        VAR_RESULT=$(echo $VAR_CUR_STR | awk -F: '{print $1}') || exitChildError "$VAR_RESULT"
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
#$1 VMID, $2 snapshotName
getVMSnapshotIDByNameVb(){
  checkParmsCount $# 2 'getVMSnapshotIDByNameVb'
  local VAR_RESULT=''
  VAR_RESULT=$(vboxmanage snapshot ${1} list --machinereadable | $SED -n "/${2}/,+1p" | $SED -n 2p | awk -F= '{print $2}' | $SED 's/["]//g') || exitChildError "$VAR_RESULT"
  echo "$VAR_RESULT"
}
#$1 VMID, $2 snapshotName, $3 host
getVMSnapshotIDByNameEx(){
  checkParmsCount $# 3 'getVMSnapshotIDByNameEx'
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
#$1 vm template, $2 vm type, $3 vm version
getVMUrl() {
  checkParmsCount $# 3 'getVMUrl'
  local FCONST_FILE_PATH="$ENV_ROOT_DIR/common/data/${1}_${2}_url.cfg"
  local VAR_RESULT=''
  if ! isFileExistAndRead "$FCONST_FILE_PATH"; then
    exitError "file $FCONST_FILE_PATH not found"
  fi
  VAR_RESULT=$(cat $FCONST_FILE_PATH | grep "$3$COMMON_CONST_DATA_CFG_SEPARATOR" | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $2}') || exitChildError "$VAR_RESULT"
  if isEmpty "$VAR_RESULT"; then
    exitError "missing url for VM template $1 version $3 in file $FCONST_FILE_PATH"
  fi
  echo "$VAR_RESULT"
}
#$1 vm template, $2 vm type
getAvailableVMTemplateVersions(){
  checkParmsCount $# 2 'getAvailableVMTemplateVersions'
  local FCONST_FILE_PATH="$ENV_ROOT_DIR/common/data/${1}_${2}_url.cfg"
  local VAR_RESULT=''
  local VAR_VM_TEMPLATE=''
  local VAR_FOUND=$COMMON_CONST_FALSE
  if ! isFileExistAndRead "$FCONST_FILE_PATH"; then
    exitError "file $FCONST_FILE_PATH not found"
  fi
  for VAR_VM_TEMPLATE in $COMMON_CONST_VM_TEMPLATES_POOL; do
    if [ "$1" = "$VAR_VM_TEMPLATE" ]; then
      VAR_RESULT=$($SED 1d $FCONST_FILE_PATH | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $1}'| awk '{ORS=FS} 1') || exitChildError "$VAR_RESULT"
      VAR_FOUND=$COMMON_CONST_TRUE
      break
    fi
  done
  if ! isTrue $VAR_FOUND; then
    exitError "VM template $1 not found"
  fi
  if isEmpty "$VAR_RESULT"; then
    exitError "cannot found any version for VM template $1 in file $FCONST_FILE_PATH"
  fi
  echo "$VAR_RESULT"
}
#$1 vm template, $2 vm type
getDefaultVMTemplateVersion(){
  checkParmsCount $# 2 'getDefaultVMTemplateVersion'
  local FCONST_FILE_PATH="$ENV_ROOT_DIR/common/data/${1}_${2}_url.cfg"
  local VAR_RESULT=''
  local VAR_VM_TEMPLATE=''
  local VAR_FOUND=$COMMON_CONST_FALSE
  if ! isFileExistAndRead "$FCONST_FILE_PATH"; then
    exitError "file $FCONST_FILE_PATH not found"
  fi
  for VAR_VM_TEMPLATE in $COMMON_CONST_VM_TEMPLATES_POOL; do
    if [ "$1" = "$VAR_VM_TEMPLATE" ]; then
      VAR_RESULT=$($SED -n 2p $FCONST_FILE_PATH | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $1}') || exitChildError "$VAR_RESULT"
      VAR_FOUND=$COMMON_CONST_TRUE
      break
    fi
  done
  if ! isTrue $VAR_FOUND; then
    exitError "VM template $1 not found"
  fi
  if isEmpty "$VAR_RESULT"; then
    exitError "missing default version for VM template $1 in file $FCONST_FILE_PATH"
  fi
  echo "$VAR_RESULT"
}
#$1 path
getParentDirectoryPath(){
  checkParmsCount $# 1 'getParentDirectoryPath'
  echo $1 | rev | $SED 's!/!:!' | rev | awk -F: '{print $1}'
}
#$1 vm name
powerOnVMVb()
{
  checkParmsCount $# 1 'powerOnVMVb'
  local FCONST_LOCAL_VMS_PATH=$COMMON_CONST_LOCAL_VMS_PATH/$COMMON_CONST_VBOX_VM_TYPE
  local VAR_RESULT=''
  local VAR_VM_ID=''
  local VAR_CUR_DIR_PATH='' #current directory name
  VAR_VM_ID=$(getVMIDByVMNameVb "$1") || exitChildError "$VAR_VM_ID"
  if isEmpty "$VAR_VM_ID"; then
    exitError "VM $1 type $COMMON_CONST_VBOX_VM_TYPE not found"
  fi
  VAR_RESULT=$(vboxmanage list runningvms | grep "{$VAR_VM_ID}")
  if isEmpty "$VAR_RESULT"; then
    echoInfo "required power on VM $1 ID $VAR_VM_ID"
    VAR_CUR_DIR_PATH=$PWD
    cd "$FCONST_LOCAL_VMS_PATH/$1"
    checkRetValOK
    vagrant up
    checkRetValOK
    cd $VAR_CUR_DIR_PATH
    checkRetValOK
  fi
  return $COMMON_CONST_EXIT_SUCCESS
}
#$1 vm name, $2 esxi host
powerOnVMEx()
{
  checkParmsCount $# 2 'powerOnVMEx'
  local VAR_VM_ID=''
  local VAR_RESULT=''
  local VAR_COUNT=$COMMON_CONST_TRY_LONG
  local VAR_TRY=$COMMON_CONST_TRY_NUM
  VAR_VM_ID=$(getVMIDByVMNameEx "$1" "$2") || exitChildError "$VAR_VM_ID"
  if isEmpty "$VAR_VM_ID"; then
    exitError "VM $1 not found on $2 host"
  fi
  echoInfo "required power on VM $1 ID $VAR_VM_ID on $2 host"
  VAR_RESULT=$($SSH_CLIENT $2 "if [ \"\$(vim-cmd vmsvc/power.getstate $VAR_VM_ID | sed -e '1d')\" != 'Powered on' ]; then vim-cmd vmsvc/power.on $VAR_VM_ID; else echo $COMMON_CONST_TRUE; fi") || exitChildError "$VAR_RESULT"
  if isTrue "$VAR_RESULT"; then return $COMMON_CONST_EXIT_SUCCESS; else echoResult "$VAR_RESULT"; fi
  while true; do
    echo -n '.'
    sleep $COMMON_CONST_SLEEP_LONG
    #check status
    VAR_RESULT=$($SSH_CLIENT $2 "if [ \"\$(vim-cmd vmsvc/power.getstate $VAR_VM_ID | sed -e '1d')\" = 'Powered on' ]; then echo $COMMON_CONST_TRUE; fi") || exitChildError "$VAR_RESULT"
    if isTrue "$VAR_RESULT"; then break; fi
    VAR_COUNT=$((VAR_COUNT-1))
    if [ $VAR_COUNT -eq 0 ]; then
      VAR_TRY=$((VAR_TRY-1))
      if [ $VAR_TRY -eq 0 ]; then  #still not powered on, force kill vm
        exitError "failed power on the VM $1 ID $VAR_VM_ID on $2 host. Check VM Tools install and running"
      else
        echo ''
        echoWarning "still cannot power on the VM $1 ID $VAR_VM_ID on $2 host, left $VAR_TRY attempts"
      fi;
      VAR_COUNT=$COMMON_CONST_TRY_LONG
    fi
  done
  echo ''
  return $COMMON_CONST_EXIT_SUCCESS
}
#$1 vm name
powerOffVMVb()
{
  checkParmsCount $# 1 'powerOffVMVb'
  local FCONST_LOCAL_VMS_PATH=$COMMON_CONST_LOCAL_VMS_PATH/$COMMON_CONST_VBOX_VM_TYPE
  local VAR_RESULT=''
  local VAR_VM_ID=''
  local VAR_CUR_DIR_PATH='' #current directory name
  VAR_VM_ID=$(getVMIDByVMNameVb "$1") || exitChildError "$VAR_VM_ID"
  if isEmpty "$VAR_VM_ID"; then
    exitError "VM $1 type $COMMON_CONST_VBOX_VM_TYPE not found"
  fi
  VAR_RESULT=$(vboxmanage list runningvms | grep "{$VAR_VM_ID}")
  if ! isEmpty "$VAR_RESULT"; then
    echoInfo "required power off VM $1 ID $VAR_VM_ID"
    VAR_CUR_DIR_PATH=$PWD
    cd "$FCONST_LOCAL_VMS_PATH/$1"
    checkRetValOK
    vagrant halt
    checkRetValOK
    cd $VAR_CUR_DIR_PATH
    checkRetValOK
  fi
  return $COMMON_CONST_EXIT_SUCCESS
}
#$1 vm name, $2 esxi host
powerOffVMEx()
{
  checkParmsCount $# 2 'powerOffVMEx'
  local VAR_VM_ID=''
  local VAR_RESULT=''
  local VAR_COUNT=$COMMON_CONST_TRY_LONG
  local VAR_TRY=$COMMON_CONST_TRY_NUM
  VAR_VM_ID=$(getVMIDByVMNameEx "$1" "$2") || exitChildError "$VAR_VM_ID"
  if isEmpty "$VAR_VM_ID"; then
    exitError "VM $1 not found on $2 host"
  fi
  echoInfo "required power off VM $1 ID $VAR_VM_ID on $2 host"
  VAR_RESULT=$($SSH_CLIENT $2 "if [ \"\$(vim-cmd vmsvc/power.getstate $VAR_VM_ID | sed -e '1d')\" != 'Powered off' ]; then vim-cmd vmsvc/power.shutdown $VAR_VM_ID; else echo $COMMON_CONST_TRUE; fi") || exitChildError "$VAR_RESULT"
  if isTrue "$VAR_RESULT"; then return $COMMON_CONST_EXIT_SUCCESS; else echoResult "$VAR_RESULT"; fi
  while true; do
    echo -n '.'
    sleep $COMMON_CONST_SLEEP_LONG
    #check status
    VAR_RESULT=$($SSH_CLIENT $2 "if [ \"\$(vim-cmd vmsvc/power.getstate $VAR_VM_ID | sed -e '1d')\" = 'Powered off' ]; then echo $COMMON_CONST_TRUE; fi") || exitChildError "$VAR_RESULT"
    if isTrue "$VAR_RESULT"; then break; fi
    VAR_COUNT=$((VAR_COUNT-1))
    if [ $VAR_COUNT -eq 0 ]; then
      VAR_TRY=$((VAR_TRY-1))
      if [ $VAR_TRY -eq 0 ]; then  #still running, force kill vm
        echoWarning "failed standard power off the VM $1 ID $VAR_VM_ID on $2 host, use force power off."
        VAR_RESULT=$($SSH_CLIENT $2 "vmdumper -l | grep -i 'displayName=\"$PRM_VMNAME\"' | awk '{print \$1}' | awk -F'/|=' '{print \$(NF)}'") || exitChildError "$VAR_RESULT"
        $SSH_CLIENT $2 "esxcli vm process kill --type force --world-id $VAR_RESULT"
        checkRetValOK
        sleep $COMMON_CONST_SLEEP_LONG
        VAR_RESULT=$($SSH_CLIENT $2 "vmdumper -l | grep -i 'displayName=\"$PRM_VMNAME\"' | awk '{print \$1}' | awk -F'/|=' '{print \$(NF)}'") || exitChildError "$VAR_RESULT"
        if ! isEmpty "$VAR_RESULT"; then
          exitError "failed force power off the VM $1 ID $VAR_VM_ID on $2 host"
        fi
      else
        echo ''
        echoWarning "still cannot standard power off the VM $1 ID $VAR_VM_ID on $2 host, left $VAR_TRY attempts"
      fi;
      VAR_COUNT=$COMMON_CONST_TRY_LONG
    fi
  done
  echo ''
  return $COMMON_CONST_EXIT_SUCCESS
}
#$1 vm name
getPortAddressByVMNameVb()
{
  checkParmsCount $# 1 'getPortAddressByVMNameVb'
  local FCONST_LOCAL_VMS_PATH=$COMMON_CONST_LOCAL_VMS_PATH/$COMMON_CONST_VBOX_VM_TYPE
  local VAR_RESULT=''
  local VAR_VM_ID=''
  local VAR_CUR_DIR_PATH='' #current directory name
  VAR_VM_ID=$(getVMIDByVMNameVb "$1") || exitChildError "$VAR_VM_ID"
  if isEmpty "$VAR_VM_ID"; then
    exitError "VM $1 type $COMMON_CONST_VBOX_VM_TYPE not found"
  fi
  VAR_RESULT=$(vboxmanage list runningvms | grep "{$VAR_VM_ID}")
  if ! isEmpty "$VAR_RESULT"; then
    VAR_CUR_DIR_PATH=$PWD
    cd "$FCONST_LOCAL_VMS_PATH/$1"
    checkRetValOK
    VAR_RESULT=$(vagrant port --guest $COMMON_CONST_DEFAULT_SSH_PORT) || exitChildError "$VAR_RESULT"
    cd $VAR_CUR_DIR_PATH
    checkRetValOK
  fi
  echo "$VAR_RESULT"
}
#$1 vm name, $2 esxi host, $3 fast mode bool value
getIpAddressByVMNameEx()
{
  checkParmsCount $# 3 'getIpAddressByVMNameEx'
  local VAR_RESULT=''
  local VAR_COUNT=$COMMON_CONST_TRY_LONG
  local VAR_TRY=$COMMON_CONST_TRY_NUM
  local VAR_VM_ID=''
  VAR_VM_ID=$(getVMIDByVMNameEx "$1" "$2") || exitChildError "$VAR_VM_ID"
  while true
  do
    VAR_RESULT=$($SSH_CLIENT $2 "vim-cmd vmsvc/get.guest $VAR_VM_ID | grep 'ipAddress = \"' | \
        sed -n 1p | cut -d '\"' -f2") || exitChildError "$VAR_RESULT"
    #vim-cmd vmsvc/get.guest vmid |grep -m 1 "ipAddress = \""
    if ! isEmpty "$VAR_RESULT" || isTrue "$3"; then break; fi
    VAR_COUNT=$((VAR_COUNT-1))
    if [ $VAR_COUNT -eq 0 ]; then
      VAR_TRY=$((VAR_TRY-1))
      if [ $VAR_TRY -eq 0 ]; then
        exitError "failed get ip address of the VM $1 on $2 host. Check VM Tools install and running"
      #else
        #echoWarning "still cannot get ip address of the VMID $1 on $2 host, left $VAR_TRY attempts"
      fi;
      VAR_COUNT=$COMMON_CONST_TRY_LONG
    fi
    sleep $COMMON_CONST_SLEEP_LONG
  done
  echo "$VAR_RESULT"
}
#$1 vm template pool. Return value format 'vmname:vmid'
getVmsPoolVb(){
  checkParmsCount $# 1 'getVmsPoolVb'
  local VAR_RESULT=''
  if [ "$1" = "$COMMON_CONST_ALL" ]; then
    VAR_RESULT=$(vboxmanage list vms | awk '{print $1":"$2}' | $SED 's/["{}]//g') || exitChildError "$VAR_RESULT"
  else
    VAR_RESULT=$(vboxmanage list vms | awk '{print $1":"$2}' | grep "${1}-" | $SED 's/["{}]//g') || exitChildError "$VAR_RESULT"
  fi
  echo "$VAR_RESULT"
}
#$1 vm template pool, $2 esxi host pool. Return value format 'vmname:esxihost:vmid'
getVmsPoolEx(){
  checkParmsCount $# 2 'getVmsPoolEx'
  local VAR_CUR_ESXI=''
  local VAR_RESULT=''
  local VAR_ESXI_HOSTS_POOL=$2
  if [ "$VAR_ESXI_HOSTS_POOL" = "$COMMON_CONST_ALL" ]; then
    VAR_ESXI_HOSTS_POOL=$COMMON_CONST_ESXI_HOSTS_POOL
  fi
  for VAR_CUR_ESXI in $VAR_ESXI_HOSTS_POOL; do
    local VAR_RESULT1
    checkSSHKeyExistEsxi "$VAR_CUR_ESXI"
    checkRetValOK
    if [ "$1" = "$COMMON_CONST_ALL" ]; then
      VAR_RESULT1=$($SSH_CLIENT $VAR_CUR_ESXI "vim-cmd vmsvc/getallvms | sed -e '1d' | \
awk '{print \$1\":\"\$2}' | awk -F: '{print \$2\":$VAR_CUR_ESXI:\"\$1}'") || exitChildError "$VAR_RESULT1"
    else
      VAR_RESULT1=$($SSH_CLIENT $VAR_CUR_ESXI "vim-cmd vmsvc/getallvms | sed -e '1d' | \
awk '{print \$1\":\"\$2}' | grep ':'$1'-' | awk -F: '{print \$2\":$VAR_CUR_ESXI:\"\$1}'") || exitChildError "$VAR_RESULT1"
    fi
    VAR_RESULT=$VAR_RESULT$VAR_RESULT1
  done
  echo "$VAR_RESULT"
}
#$1 vm name
getVMIDByVMNameVb() {
  checkParmsCount $# 1 'getVMIDByVMNameVb'
  local VAR_RESULT
  VAR_RESULT=$(vboxmanage list vms | awk '{print $1":"$2}' | grep -e "\"${1}\":" | awk -F: '{print $2}' |  $SED 's/[{}]//g') || exitChildError "$VAR_RESULT"
  echo "$VAR_RESULT"
}
#$1 vm name, $2 esxi host
getVMIDByVMNameEx() {
  checkParmsCount $# 2 'getVMIDByVMNameEx'
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
  elif ! isEmpty "$3"; then
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
  local VAR_VM_IP=''
  local VAR_INPUT=''
  local VAR_RESULT=''
  local VAR_LOG=''
  pausePrompt "Pause 1 of 3: Check guest OS type, virtual hardware on template VM $1 on $2 host. Typically for Linux without GUI: \
vCPUs - $COMMON_CONST_DEFAULT_VCPU_COUNT, Memory - ${COMMON_CONST_DEFAULT_MEMORY_SIZE}MB, HDD - ${COMMON_CONST_DEFAULT_HDD_SIZE}G"
  VAR_RESULT=$(powerOnVMEx "$1" "$2") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  echoResult "$4"
  pausePrompt "Pause 2 of 3: Manually make changes on template VM $1 on $2 host from ESXi GUI"
  VAR_VM_IP=$(getIpAddressByVMNameEx "$1" "$2" "$COMMON_CONST_FALSE") || exitChildError "$VAR_VM_IP"
  echoInfo "VM ${1} ip $VAR_VM_IP port $COMMON_CONST_DEFAULT_SSH_PORT"
  $SSH_COPY_ID $COMMON_CONST_ESXI_BASE_USER_NAME@$VAR_VM_IP
  checkRetValOK
  $SCP_CLIENT "$ENV_ROOT_DIR/common/trigger/${1}_create.sh" $COMMON_CONST_ESXI_BASE_USER_NAME@$VAR_VM_IP:
  checkRetValOK
  echoInfo "start ${1}_create.sh executing on template VM ${1} ip $VAR_VM_IP port $COMMON_CONST_DEFAULT_SSH_PORT on $2 host"
  #exec trigger script
  VAR_RESULT=$($SSH_CLIENT $COMMON_CONST_ESXI_BASE_USER_NAME@$VAR_VM_IP "chmod u+x ${1}_create.sh;./${1}_create.sh $ENV_SSH_USER_NAME $ENV_SSH_USER_PASS $1 $3; \
if [ -r ${1}_create.ok ]; then cat ${1}_create.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_RESULT"
  if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
    VAR_LOG=$($SSH_CLIENT $COMMON_CONST_ESXI_BASE_USER_NAME@$VAR_VM_IP "if [ -r ${1}_create.log ]; then cat ${1}_create.log; fi") || exitChildError "$VAR_LOG"
    if ! isEmpty "$VAR_LOG"; then echoInfo "stdout\n$VAR_LOG"; fi
  fi
  VAR_LOG=$($SSH_CLIENT $COMMON_CONST_ESXI_BASE_USER_NAME@$VAR_VM_IP "if [ -r ${1}_create.err ]; then cat ${1}_create.err; fi") || exitChildError "$VAR_LOG"
  if ! isEmpty "$VAR_LOG"; then echoInfo "stderr\n$VAR_LOG"; fi
  if ! isTrue "$VAR_RESULT"; then
    exitError "failed execute ${1}_create.sh on template VM ${1} ip $VAR_VM_IP port $COMMON_CONST_DEFAULT_SSH_PORT on $2 host"
  else
    echoInfo "finish execute ${1}_create.sh on template VM ${1} ip $VAR_VM_IP port $COMMON_CONST_DEFAULT_SSH_PORT on $2 host"
  fi
  pausePrompt "Pause 3 of 3: Last check template VM ${1} ip $VAR_VM_IP port $COMMON_CONST_DEFAULT_SSH_PORT on $2 host"
  VAR_RESULT=$(powerOffVMEx "$1" "$2") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
}
#$1 title, $2 values pool, $3 allowed values
checkCommandValue() {
  checkParmsCount $# 3 'checkCommandValue'
  local VAR_VALUE=''
  local VAR_COMMAND=''
  local VAR_FOUND=$COMMON_CONST_FALSE
  for VAR_VALUE in $2; do
    VAR_FOUND=$COMMON_CONST_FALSE
    for VAR_COMMAND in $3; do
      if [ "$VAR_COMMAND" = "$VAR_VALUE" ]
      then
        VAR_FOUND=$COMMON_CONST_TRUE
      fi
    done
    if ! isTrue "$VAR_FOUND"
    then
      exitError "option $1 value '$VAR_VALUE' invalid. Allowed values: $3"
    fi
  done
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
    if ! isCommandExist "$VAR_DEPENDENCE"; then
      echoWarning "try to install missing dependence $VAR_DEPENDENCE"
      if isLinuxOS; then
        local VAR_LINUX_BASED
        VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
        if isAPTLinux "$VAR_LINUX_BASED"; then
          checkDpkgUnlock
          sudo apt -y install $VAR_DEPENDENCE
        elif isRPMLinux "$VAR_LINUX_BASED"; then
          sudo yum -y install $VAR_DEPENDENCE
        fi
      elif isFreeBSDOS; then
        setenv ASSUME_ALWAYS_YES yes
        pkg install $VAR_DEPENDENCE
        setenv ASSUME_ALWAYS_YES
      fi
      #repeat check for availability dependence
      if ! isCommandExist $VAR_DEPENDENCE; then
        exitError "dependence $VAR_DEPENDENCE not found"
      fi
    fi
  done
}

checkRequiredFiles() {
  checkParmsCount $# 1 'checkRequiredFiles'
  local VAR_FILE=''
  for VAR_FILE in $1; do
    if ! isFileExistAndRead $VAR_FILE
    then
      exitError "file $VAR_FILE not found"
    fi
  done
}

checkDpkgUnlock(){
  checkParmsCount $# 0 'checkDpkgUnlock'
  local FCONST_LOCK_FILE='/var/lib/dpkg/lock'
  local VAR_COUNT=$COMMON_CONST_TRY_LONG
  local VAR_TRY=$COMMON_CONST_TRY_NUM
  echoInfo "Check /var/lib/dpkg/lock"
  while sudo fuser $FCONST_LOCK_FILE >/dev/null 2>&1; do
    echo -n '.'
    sleep $COMMON_CONST_SLEEP_LONG
    VAR_COUNT=$((VAR_COUNT-1))
    if [ $VAR_COUNT -eq 0 ]; then
      VAR_TRY=$((VAR_TRY-1))
      if [ $VAR_TRY -eq 0 ]; then  #still not powered on, force kill vm
        exitError "failed wait while unlock $FCONST_LOCK_FILE. Check another long process using it"
      else
        echo ''
        echoWarning "still locked $FCONST_LOCK_FILE, left $VAR_TRY attempts"
      fi;
      VAR_COUNT=$COMMON_CONST_TRY_LONG
    fi
  done
  echo ''
  return $COMMON_CONST_EXIT_SUCCESS
}

checkLinuxAptOrRpm(){
  checkParmsCount $# 0 'checkLinuxAptOrRpm'
  if isFileExistAndRead "/etc/debian_version"; then
    echo "$COMMON_CONST_LINUX_APT"
  elif isFileExistAndRead "/etc/redhat-release"; then
    echo "$COMMON_CONST_LINUX_RPM"
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
    setErrorEnvironment "set variable $1"
  fi
}
#$1 esxi hosts pool
checkSSHKeyExistEsxi(){
  checkParmsCount $# 1 'checkSSHKeyExistEsxi'
  local FCONST_HV_SSHKEYS_DIRNAME="/etc/ssh/keys-$ENV_SSH_USER_NAME"
  local VAR_RESULT="$COMMON_CONST_FALSE"
  local VAR_TMP_FILE_PATH=''
  local VAR_TMP_FILE_NAME=''
  local VAR_CUR_ESXI=''
  VAR_TMP_FILE_PATH=$(mktemp -u) || exitChildError "$VAR_TMP_FILE_PATH"
  VAR_TMP_FILE_NAME=$(basename $VAR_TMP_FILE_PATH) || exitChildError "$VAR_TMP_FILE_NAME"
  checkRequiredFiles "$ENV_SSH_KEYID"
  for VAR_CUR_ESXI in $1; do
    VAR_RESULT=$($SSHP_CLIENT $VAR_CUR_ESXI "if [ ! -d $FCONST_HV_SSHKEYS_DIRNAME ]; then mkdir $FCONST_HV_SSHKEYS_DIRNAME; fi; \
if [ ! -r $FCONST_HV_SSHKEYS_DIRNAME/authorized_keys ]; then \
cat > $FCONST_HV_SSHKEYS_DIRNAME/authorized_keys; else cat > $FCONST_HV_SSHKEYS_DIRNAME/$VAR_TMP_FILE_NAME; \
cat $FCONST_HV_SSHKEYS_DIRNAME/authorized_keys | grep -F - -f $FCONST_HV_SSHKEYS_DIRNAME/$VAR_TMP_FILE_NAME || cat $FCONST_HV_SSHKEYS_DIRNAME/$VAR_TMP_FILE_NAME >> $FCONST_HV_SSHKEYS_DIRNAME/authorized_keys; \
rm $FCONST_HV_SSHKEYS_DIRNAME/$VAR_TMP_FILE_NAME; fi; echo $COMMON_CONST_TRUE" < $ENV_SSH_KEYID) || exitChildError "$VAR_RESULT"
  done
  return "$COMMON_CONST_EXIT_SUCCESS"
}

checkProjectRepository(){
  checkParmsCount $# 0 'checkProjectRepository'
  if isEmpty "$ENV_PROJECT_REPO"; then
    exitError "set variable ENV_GIT_USER_NAME in environment.sh"
  fi
}

checkGitUserAndEmail(){
  checkParmsCount $# 0 'checkGitUserAndEmail'
  if isEmpty "$ENV_GIT_USER_NAME"; then
    exitError "variable ENV_GIT_USER_NAME is empty. Try to exec 'git config user.name <userName>'"
  fi
  if isEmpty "$ENV_GIT_USER_EMAIL"; then
    exitError "variable ENV_GIT_USER_EMAIL is empty. Try to exec 'git config user.email <userEmail>'"
  fi
}

checkUserPassword(){
  checkParmsCount $# 0 'checkUserPassword'
  if isEmpty "$ENV_SSH_USER_PASS"; then
    exitError "variable ENV_SSH_USER_PASS is empty. Try to exec $ENV_ROOT_DIR/common/initialize.sh"
  fi
  if isEmpty "$ENV_OVFTOOL_USER_PASS"; then
    exitError "variable ENV_OVFTOOL_USER_PASS is empty. Try to exec $ENV_ROOT_DIR/common/initialize.sh"
  fi
}
#$1 message
setErrorEnvironment()
{
  checkParmsCount $# 1 'setErrorEnvironment'
  if ! isEmpty "$VAR_ENVIRONMENT_ERROR"; then
    VAR_ENVIRONMENT_ERROR="${VAR_ENVIRONMENT_ERROR}\n"
  fi
  VAR_ENVIRONMENT_ERROR="$VAR_ENVIRONMENT_ERROR$1 in environment.sh"
}
#$1 description, [$2] allowed autoyes
targetDescription(){
  local VAR_MODE=$COMMON_CONST_FALSE
  if ! isEmpty "$VAR_ENVIRONMENT_ERROR"; then
    echoResult "Error: $VAR_ENVIRONMENT_ERROR"
    echo "Try to exec $ENV_ROOT_DIR/common/initialize.sh"
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
    showElapsedTime "$COMMON_CONST_TIME_FORMAT_LONG"
    if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
      echo "Stop session [$$] with $COMMON_CONST_EXIT_SUCCESS (Ok)"
    fi
  fi
  exit $COMMON_CONST_EXIT_SUCCESS
}
#[$1] message, [$2] if set $COMMON_CONST_EXIT_ERROR, it is child error
exitError(){
  if [ "$2" != "$COMMON_CONST_EXIT_ERROR" ]; then
    echo "Error: ${1:-$COMMON_CONST_ERROR_MESS_UNKNOWN}. See '$ENV_SCRIPT_FILE_NAME --help'"
    if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
      getTrace
    fi
    showElapsedTime "$COMMON_CONST_TIME_FORMAT_LONG"
    if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
      echo "Stop session [$$] with $COMMON_CONST_EXIT_ERROR (Error)"
    fi
  else
    echo "$1"
  fi
  exit $COMMON_CONST_EXIT_ERROR
}

getTrace(){
  checkParmsCount $# 0 'getTrace'
  local VAR_TRACE=""
  local VAR_CP=$$ # PID of the script itself [1]
  local VAR_PP=''
  local VAR_CMD_LINE=''
  if isLinuxOS; then
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
    VAR_TRACE=$(echo "$VAR_TRACE" | tac | grep -n ":" | tac) # using tac to "print in reverse" [3]
  elif isMacOS; then
    echoWarning "TO-DO MacOS stack trace"
  elif isFreeBSDOS; then
    echoWarning "TO-DO FreeBSD stack trace"
  fi
  echo "Debug: begin trace"
  echoResult "$VAR_TRACE"
  echo "Debug: end trace"
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
  if ! isTrue "$VAR_NEED_HELP" && [ $1 -gt $2 ]; then
    exitError "too many options"
    VAR_NEED_HELP=$COMMON_CONST_TRUE
  fi
  if isTrue "$VAR_NEED_HELP"; then
    if [ "$VAR_AUTO_YES" != "$COMMON_CONST_NULL" ]; then
      echo "Usage: $ENV_SCRIPT_FILE_NAME [-y] $3"
    else
      echo "Usage: $ENV_SCRIPT_FILE_NAME $3"
    fi
    echo "Sample: $ENV_SCRIPT_FILE_NAME $4"
    if ! isEmpty "$5"; then
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
  local VAR_TIME_STRING=''
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
  VAR_START_TIME="$(getTime)"
  if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
    VAR_TIME_STRING=$(getTimeAsString "$VAR_START_TIME" "$COMMON_CONST_TIME_FORMAT_LONG")
    echo "Start session [$$] at $VAR_TIME_STRING"
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
  echo $1 | rev | $SED 's/[.]/:/' | rev | awk -F: '{print $1}'
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
putVmtoolsToEsxi(){
  checkParmsCount $# 1 'putVmtoolsToEsxi'
  local VAR_TMP_DIR_PATH
  VAR_TMP_DIR_PATH=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_PATH"
  tar -xzf $COMMON_CONST_LOCAL_VMTOOLS_PATH --strip-component=2 -C $VAR_TMP_DIR_PATH
  checkRetValOK
  $SCP_CLIENT -r $VAR_TMP_DIR_PATH/* $1:$COMMON_CONST_ESXI_VMTOOLS_PATH/
  checkRetValOK
  rm -fR $VAR_TMP_DIR_PATH
  checkRetValOK
}
#$1 esxi host
putOvftoolToEsxi(){
  checkParmsCount $# 1 'putOvftoolToEsxi'
  $SCP_CLIENT -r $COMMON_CONST_LOCAL_OVFTOOL_PATH $1:$COMMON_CONST_ESXI_TOOLS_PATH/
  checkRetValOK
  $SSH_CLIENT $1 "sed -i 's@^#!/bin/bash@#!/bin/sh@' $COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool"
  checkRetValOK
}
#$1 esxi host
put_template_tools_to_esxi(){
  checkParmsCount $# 1 'put_template_tools_to_esxi'
  $SCP_CLIENT -r $ENV_SCRIPT_DIR_NAME/template $1:$COMMON_CONST_ESXI_TEMPLATES_PATH/
  checkRetValOK
}

#[$1] error message
checkRetValOK(){
  if [ "$?" != "0" ]; then exitError "$1"; fi
}
#$1 return result
echoResult(){
  checkParmsCount $# 1 'echoResult'
  if ! isEmpty "$1"; then
    if isTrue "$ENV_SHELL_WITH_ESC"; then
      echo "$1"
    else
      echo -e "$1"
    fi
  fi
}
#$1 message
echoInfo(){
  checkParmsCount $# 1 'echoInfo'
  echoResult "Info: $1"
}
#$1 message
echoWarning(){
  checkParmsCount $# 1 'echoWarning'
  echoResult "Warning: $1"
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
  [ "$(uname -s)" = "Linux" ]
}

isMacOS(){
  checkParmsCount $# 0 'isMacOS'
  [ "$(uname -s)" = "Darwin" ]
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
  [ "$(uname -s)" = "FreeBSD" ]
}

isFileSystemMounted(){
  checkParmsCount $# 1 'isDirectoryMounted'
  mount | awk '{print $1}' | grep -w $1 >/dev/null
  [ "$?" = "$COMMON_CONST_EXIT_SUCCESS" ]
}

isRetValOK(){
  [ "$?" = "$COMMON_CONST_EXIT_SUCCESS" ]
}
#$1 vm name
isVMExistVb(){
  checkParmsCount $# 1 'isVMExistVb'
  local VAR_RESULT=''
  VAR_RESULT=$(getVMIDByVMNameVb "$1") || exitChildError "$VAR_RESULT"
  ! isEmpty "$VAR_RESULT"
}
#$1 vm name, $2 host
isVMExistEx(){
  checkParmsCount $# 2 'isVMExistEx'
  local VAR_RESULT=''
  VAR_RESULT=$(getVMIDByVMNameEx "$1" "$2") || exitChildError "$VAR_RESULT"
  ! isEmpty "$VAR_RESULT"
}
#$1 VMID, $2 snapshotName
isSnapshotVMExistVb(){
  checkParmsCount $# 2 'isSnapshotVMExistVb'
  local VAR_RESULT=''
  local VAR_VM_ID=''
  VAR_RESULT=$(getVMSnapshotIDByNameVb "$1" "$2") || exitChildError "$VAR_RESULT"
  ! isEmpty "$VAR_RESULT"
}
#$1 VMID, $2 snapshotName, $3 host
isSnapshotVMExistEx(){
  checkParmsCount $# 3 'isSnapshotVMExistEx'
  local VAR_RESULT=''
  local VAR_VM_ID=''
  VAR_RESULT=$(getVMSnapshotIDByNameEx "$1" "$2" "$3") || exitChildError "$VAR_RESULT"
  ! isEmpty "$VAR_RESULT"
}
#$1 esxi host
isHostAvailableEx(){
  checkParmsCount $# 1 'isHostAvailableEx'
  local VAR_RESULT=''
  VAR_RESULT=$(checkSSHKeyExistEsxi "$1") || return "$COMMON_CONST_EXIT_ERROR"
  return  "$COMMON_CONST_EXIT_SUCCESS"
}
