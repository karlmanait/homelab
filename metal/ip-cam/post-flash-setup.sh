#!/bin/bash

# Configurations #
BLK_DEVICE="$1"
MOUNT_TARGET="/mnt/motioneyeos"
SSH_PUBKEY="${HOME}/.ssh/id_rsa.pub"
# End Configurations #


if [ -z "$1" ]; then
  echo "Empty BLK_DEVICE"
  exit 1
fi
boot_partition=$(sudo fdisk -l | grep ${BLK_DEVICE} | grep FAT | awk '{print $1}')
fs_partition=$(sudo fdisk -l | grep ${BLK_DEVICE} | grep Linux | awk '{print $1}')
proj_rootdir=$(git rev-parse --show-toplevel)
config_files="${proj_rootdir}/metal/ip-cam/configs"

# setup mounts
sudo mkdir -p ${MOUNT_TARGET} ${MOUNT_TARGET}/boot ${MOUNT_TARGET}/fs
sudo mount ${boot_partition} ${MOUNT_TARGET}/boot
sudo mount ${fs_partition} ${MOUNT_TARGET}/fs
# update boot partition configs
sudo cp ${config_files}/config.txt ${MOUNT_TARGET}/boot
sudo cp ${config_files}/wpa_supplicant.conf ${MOUNT_TARGET}/boot
sudo cp ${config_files}/static_ip.conf ${MOUNT_TARGET}/boot
# update sshd config
sshd_config="${MOUNT_TARGET}/fs/etc/ssh/sshd_config"
cat ${SSH_PUBKEY} | sudo tee ${MOUNT_TARGET}/fs/etc/ssh/init_authorized_keys > /dev/null
sudo sed -i "s|^PermitRootLogin .*|PermitRootLogin without-password|" ${sshd_config}
sudo sed -i "s|^PermitEmptyPasswords .*|PasswordAuthentication no|" ${sshd_config}
if ! grep -qF "PubkeyAuthentication" ${sshd_config}; then
  echo "PubkeyAuthentication yes" | sudo tee -a ${sshd_config} > /dev/null
fi
if ! grep -qF "AuthorizedKeysFile" ${sshd_config}; then
  echo "AuthorizedKeysFile /etc/ssh/authorized_keys /etc/ssh/init_authorized_keys" | sudo tee -a ${sshd_config} > /dev/null
fi
# unmount and cleanup
sudo umount ${boot_partition}
sudo umount ${fs_partition}
sudo rm -rf ${MOUNT_TARGET}
