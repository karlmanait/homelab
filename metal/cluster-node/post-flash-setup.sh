#!/bin/bash

# Configurations #
BLK_DEVICE="$1"
MOUNT_TARGET="/mnt/debian"
SSH_PUBKEY="${HOME}/.ssh/id_rsa.pub"
# End Configurations #


if [ -z "$1" ]; then
  echo "Empty BLK_DEVICE"
  exit 1
fi
boot_partition=$(sudo fdisk -l | grep ${BLK_DEVICE} | grep FAT | awk '{print $1}')
fs_partition=$(sudo fdisk -l | grep ${BLK_DEVICE} | grep Linux | awk '{print $1}')
proj_rootdir=$(git rev-parse --show-toplevel)
config_files="${proj_rootdir}/metal/cluster-node/configs"

# setup mounts
sudo mkdir -p ${MOUNT_TARGET} ${MOUNT_TARGET}/boot ${MOUNT_TARGET}/fs
sudo mount ${boot_partition} ${MOUNT_TARGET}/boot
sudo mount ${fs_partition} ${MOUNT_TARGET}/fs
# update boot partition configs
echo "root_authorized_key=$(cat ${SSH_PUBKEY})" | sudo tee ${MOUNT_TARGET}/boot/sysconf.txt > /dev/null
# use a pre-configured static ip and setup nameserver
sudo cp ${config_files}/eth0 ${MOUNT_TARGET}/fs/etc/network/interfaces.d/eth0
sudo cp ${config_files}/resolv.conf ${MOUNT_TARGET}/fs/etc/
# unmount and cleanup
sudo umount ${boot_partition}
sudo umount ${fs_partition}
sudo rm -rf ${MOUNT_TARGET}
