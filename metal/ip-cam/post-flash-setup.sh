#!/bin/bash

# Configurations #
BLK_DEVICE="$1"
MOUNT_TARGET="/mnt/raspios"
SSH_PUBKEY="${HOME}/.ssh/id_rsa.pub"
ROOT_PASSWORD="changeme"
TIMEZONE="Asia/Manila"
WIFI_COUNTRY="PH"
# End Configurations #


if [ -z "$1" ]; then
  echo "Empty BLK_DEVICE"
  exit 1
fi

proj_rootdir=$(git rev-parse --show-toplevel)
config_files="${proj_rootdir}/metal/ip-cam/configs"


# find partitions by filesystem type using lsblk
boot_partition=$(lsblk -lnpo NAME,FSTYPE ${BLK_DEVICE} | grep -i vfat | awk '{print $1}')
fs_partition=$(lsblk -lnpo NAME,FSTYPE ${BLK_DEVICE} | grep -i ext4 | awk '{print $1}')

if [ -z "$boot_partition" ] || [ -z "$fs_partition" ]; then
  echo "Could not find boot (vfat) or root (ext4) partition on ${BLK_DEVICE}"
  lsblk -lpo NAME,FSTYPE,SIZE ${BLK_DEVICE}
  exit 1
fi

# setup mounts
echo "Setting up mounts..."
sudo mkdir -p ${MOUNT_TARGET} ${MOUNT_TARGET}/boot ${MOUNT_TARGET}/fs
sudo mount ${boot_partition} ${MOUNT_TARGET}/boot
sudo mount ${fs_partition} ${MOUNT_TARGET}/fs


# append ip-cam settings to the stock config.txt (keeps camera_auto_detect etc.)
echo "Updating config.txt..."
if ! grep -qF "# ip-cam:" ${MOUNT_TARGET}/boot/config.txt; then
  cat ${config_files}/config.txt | sudo tee -a ${MOUNT_TARGET}/boot/config.txt > /dev/null
fi

# set the wifi regulatory domain via kernel cmdline (same as Raspberry Pi Imager)
echo "Setting WiFi country..."
if ! grep -qF "cfg80211.ieee80211_regdom=" ${MOUNT_TARGET}/boot/cmdline.txt; then
  sudo sed -i "1 s|\$| cfg80211.ieee80211_regdom=${WIFI_COUNTRY}|" ${MOUNT_TARGET}/boot/cmdline.txt
fi

# enable sshd on first boot (handled by sshswitch.service)
echo "Enabling SSH..."
sudo touch ${MOUNT_TARGET}/boot/ssh

# write authorized_keys directly
echo "Writing authorized_keys..."
sudo mkdir -p ${MOUNT_TARGET}/fs/root/.ssh
sudo tee ${MOUNT_TARGET}/fs/root/.ssh/authorized_keys > /dev/null <<< "$(cat ${SSH_PUBKEY})"
sudo chmod 700 ${MOUNT_TARGET}/fs/root/.ssh
sudo chmod 600 ${MOUNT_TARGET}/fs/root/.ssh/authorized_keys

# set root password directly in shadow file (for console login)
echo "Setting root password..."
if command -v mkpasswd >/dev/null 2>&1; then
  crypted_password=$(mkpasswd -m sha-512 "${ROOT_PASSWORD}")
else
  crypted_password=$(openssl passwd -6 "${ROOT_PASSWORD}")
fi
sudo sed -i "s|^root:[^:]*|root:${crypted_password}|" ${MOUNT_TARGET}/fs/etc/shadow

# set timezone directly
echo "Setting timezone..."
sudo tee ${MOUNT_TARGET}/fs/etc/timezone > /dev/null <<< "${TIMEZONE}"
sudo ln -sf /usr/share/zoneinfo/${TIMEZONE} ${MOUNT_TARGET}/fs/etc/localtime

# skip the first-boot "create a user" dialog, we only use root over ssh
echo "Disabling first-boot user configuration dialog..."
sudo ln -sf /dev/null ${MOUNT_TARGET}/fs/etc/systemd/system/userconfig.service
# the dialog normally enables the console login prompt when done, so do it ourselves
sudo mkdir -p ${MOUNT_TARGET}/fs/etc/systemd/system/getty.target.wants
sudo ln -sf /usr/lib/systemd/system/getty@.service ${MOUNT_TARGET}/fs/etc/systemd/system/getty.target.wants/getty@tty1.service
sudo rm -f ${MOUNT_TARGET}/fs/etc/ssh/sshd_config.d/rename_user.conf

# use a pre-configured wifi connection with static ip via NetworkManager
echo "Setting up WiFi and static IP via NetworkManager..."
sudo cp ${config_files}/wlan0.nmconnection ${MOUNT_TARGET}/fs/etc/NetworkManager/system-connections/wlan0.nmconnection
sudo chmod 600 ${MOUNT_TARGET}/fs/etc/NetworkManager/system-connections/wlan0.nmconnection
# the image ships with the wifi radio disabled until the country is set via raspi-config
sudo sed -i "s|^WirelessEnabled=.*|WirelessEnabled=true|" ${MOUNT_TARGET}/fs/var/lib/NetworkManager/NetworkManager.state


# unmount and cleanup
echo "Unmounting and cleaning up..."
sync
if ! sudo umount ${MOUNT_TARGET}/boot ${MOUNT_TARGET}/fs; then
  echo "ERROR: failed to unmount ${MOUNT_TARGET}, do NOT remove the SD card yet"
  exit 1
fi
sudo rmdir ${MOUNT_TARGET}/boot ${MOUNT_TARGET}/fs ${MOUNT_TARGET} 2>/dev/null || true
