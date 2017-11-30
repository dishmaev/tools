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
checkRetValOK

sudo dd bs=440 count=1 conv=notrunc if=$SYSLINUX_MBR_FILE of=$PRM_DEVICE
checkRetValOK
sudo sync
checkRetValOK

sudo mkfs.vfat -F 32 -n USB $PRM_DEVICE\1
checkRetValOK

VAR_TMP_USB_DIR_NAME=$(mktemp -d) || exitChildError "$VAR_TMP_USB_DIR_NAME"
VAR_TMP_ISO_DIR_NAME=$(mktemp -d) || exitChildError "$VAR_TMP_ISO_DIR_NAME"

sudo mount $PRM_DEVICE\1 $VAR_TMP_USB_DIR_NAME -o rw,uid=$USER
checkRetValOK
sudo mount -r -o loop $PRM_FILEISO $VAR_TMP_ISO_DIR_NAME
checkRetValOK

sleep 3

cp -r $VAR_TMP_ISO_DIR_NAME/* $VAR_TMP_USB_DIR_NAME/
checkRetValOK
cat $VAR_TMP_USB_DIR_NAME/isolinux.cfg | sed -e "s#APPEND -c boot.cfg#APPEND -c boot.cfg -p 1#" > $VAR_TMP_USB_DIR_NAME/syslinux.cfg
checkRetValOK
rm $VAR_TMP_USB_DIR_NAME/isolinux.cfg
checkRetValOK
cp $SYSLINUX_MODULE_BIOS_DIR/* $VAR_TMP_USB_DIR_NAME
checkRetValOK

sudo sync
checkRetValOK

sudo umount $VAR_TMP_USB_DIR_NAME
checkRetValOK
sudo umount $VAR_TMP_ISO_DIR_NAME
checkRetValOK

sleep 3

rmdir $VAR_TMP_USB_DIR_NAME
checkRetValOK
rmdir $VAR_TMP_ISO_DIR_NAME
checkRetValOK

doneFinalStage
exitOK
