#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Make bootable usb with esxi installation'

##private consts
SYSLINUX_MBR_FILE='/usr/lib/syslinux/mbr/mbr.bin'
SYSLINUX_MODULE_BIOS_DIR='/usr/lib/syslinux/modules/bios'

##private vars
PRM_DEVICE='' #usb device, not
PRM_FILEISO='' #iso image file with esxi installation
VAR_TMP_USB_DIR_NAME='' #temporary usb directory name
VAR_TMP_ISO_DIR_NAME='' #temporary iso directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<device> <fileIso>' "/dev/sdb VMware-VMvisor-Installer-201701001-4887370.x86_64.iso" "Device is not partition, all data on device will be destroyed"

###check commands

PRM_DEVICE=$1
PRM_FILEISO=$2

checkCommandExist 'device' "$PRM_DEVICE" ''
checkCommandExist 'fileIso' "$PRM_FILEISO" ''

if [ ! -e $PRM_DEVICE ]
then
  exitError "device $PRM_DEVICE not found"
fi

checkRequiredFiles "$PRM_FILEISO"
checkRequiredFiles "$SYSLINUX_MBR_FILE"
checkDirectoryForExist "$SYSLINUX_MODULE_BIOS_DIR" ''

#comments

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'
checkDependencies 'syslinux mountpoint'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#comments

if isFileSystemMounted $PRM_DEVICE\1
then
  sudo umount $PRM_DEVICE\1
  sleep 3
fi

sudo dd if=/dev/zero of=$PRM_DEVICE bs=512 count=10000
sudo sync
sleep 3
echo "n
p
1


t
b
w
"|sudo fdisk $PRM_DEVICE;
if ! isRetValOK; then exitError; fi

sudo dd bs=440 count=1 conv=notrunc if=$SYSLINUX_MBR_FILE of=$PRM_DEVICE
if ! isRetValOK; then exitError; fi
sudo sync
if ! isRetValOK; then exitError; fi

sudo mkfs.vfat -F 32 -n USB $PRM_DEVICE\1
if ! isRetValOK; then exitError; fi

VAR_TMP_USB_DIR_NAME=$(mktemp -d) || exitChildError "$VAR_TMP_USB_DIR_NAME"
VAR_TMP_ISO_DIR_NAME=$(mktemp -d) || exitChildError "$VAR_TMP_ISO_DIR_NAME"

echo "VAR_TMP_ISO_DIR_NAME $VAR_TMP_ISO_DIR_NAME"
echo "VAR_TMP_USB_DIR_NAME $VAR_TMP_USB_DIR_NAME"

sudo mount $PRM_DEVICE\1 $VAR_TMP_USB_DIR_NAME -o rw,uid=$USER
if ! isRetValOK; then exitError; fi
sudo mount -r -o loop $PRM_FILEISO $VAR_TMP_ISO_DIR_NAME
if ! isRetValOK; then exitError; fi

sleep 3

cp -r $VAR_TMP_ISO_DIR_NAME/* $VAR_TMP_USB_DIR_NAME/
if ! isRetValOK; then exitError; fi
cat $VAR_TMP_USB_DIR_NAME/isolinux.cfg | sed -e "s#APPEND -c boot.cfg#APPEND -c boot.cfg -p 1#" > $VAR_TMP_USB_DIR_NAME/syslinux.cfg
if ! isRetValOK; then exitError; fi
rm $VAR_TMP_USB_DIR_NAME/isolinux.cfg
if ! isRetValOK; then exitError; fi
cp $SYSLINUX_MODULE_BIOS_DIR/* $VAR_TMP_USB_DIR_NAME
if ! isRetValOK; then exitError; fi

sudo sync
if ! isRetValOK; then exitError; fi

sudo umount $VAR_TMP_USB_DIR_NAME
if ! isRetValOK; then exitError; fi
sudo umount $VAR_TMP_ISO_DIR_NAME
if ! isRetValOK; then exitError; fi

sleep 3

rmdir $VAR_TMP_USB_DIR_NAME
if ! isRetValOK; then exitError; fi
rmdir $VAR_TMP_ISO_DIR_NAME
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
