#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Make bootable usb with esxi installation'

##private consts
SYSLINUX_MBR_FILE='/usr/lib/syslinux/mbr/mbr.bin'
SYSLINUX_MODULE_BIOS_DIR='/usr/lib/syslinux/modules/bios'

##private vars
PRM_DEVICE='' #usb device, not
PRM_ISOFILE='' #iso image file with esxi installation
TMP_USBDIRNAME='' #temporary usb directory name
TMP_ISODIRNAME='' #temporary iso directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<device> <isoFile>' "/dev/sdb VMware-VMvisor-Installer-201701001-4887370.x86_64.iso" "Device is not partition, all data on device will be destroyed"

###check commands

PRM_DEVICE=$1
PRM_ISOFILE=$2

checkCommandExist 'device' "$PRM_DEVICE" ''
checkCommandExist 'isoFile' "$PRM_ISOFILE" ''

if [ ! -e $PRM_DEVICE ]
then
  exitError "device $PRM_DEVICE not found"
fi

checkRequiredFiles "$PRM_ISOFILE"
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
if [ "$?" != '0' ]
then
  exitError
fi

sudo dd bs=440 count=1 conv=notrunc if=$SYSLINUX_MBR_FILE of=$PRM_DEVICE
sudo sync

sudo mkfs.vfat -F 32 -n USB $PRM_DEVICE\1

TMP_USBDIRNAME=$(mktemp -d) || exitChildError "$TMP_USBDIRNAME"
TMP_ISODIRNAME=$(mktemp -d) || exitChildError "$TMP_ISODIRNAME"

echo "TMP_ISODIRNAME $TMP_ISODIRNAME"
echo "TMP_USBDIRNAME $TMP_USBDIRNAME"

sudo mount $PRM_DEVICE\1 $TMP_USBDIRNAME -o rw,uid=$USER
sudo mount -r -o loop $PRM_ISOFILE $TMP_ISODIRNAME
sleep 3

cp -r $TMP_ISODIRNAME/* $TMP_USBDIRNAME/
cat $TMP_USBDIRNAME/isolinux.cfg | sed -e "s#APPEND -c boot.cfg#APPEND -c boot.cfg -p 1#" > $TMP_USBDIRNAME/syslinux.cfg
rm $TMP_USBDIRNAME/isolinux.cfg
cp $SYSLINUX_MODULE_BIOS_DIR/* $TMP_USBDIRNAME

sudo sync

sudo umount $TMP_USBDIRNAME
sudo umount $TMP_ISODIRNAME

sleep 3

rmdir $TMP_USBDIRNAME
rmdir $TMP_ISODIRNAME

doneFinalStage
exitOK
