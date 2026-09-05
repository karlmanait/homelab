#!/bin/bash

# Configurations #
BLK_DEVICE="$1"
MOUNT_TARGET="/mnt/debian"
SSH_PUBKEY="${HOME}/.ssh/id_rsa.pub"
ROOT_PASSWORD="changeme"
TIMEZONE="Asia/Manila"
# End Configurations #


if [ -z "$1" ]; then
  echo "Empty BLK_DEVICE"
  exit 1
fi


proj_rootdir=$(git rev-parse --show-toplevel)
config_files="${proj_rootdir}/metal/compute-node/configs"


# check required tools
required_tools=(
  "/usr/sbin/parted"
  "/usr/sbin/partprobe"
  "/usr/sbin/sgdisk"
  "/usr/bin/qemu-aarch64-static"
)
missing_tools=()

for tool in "${required_tools[@]}"; do
  if [ ! -x "$tool" ]; then
    missing_tools+=("$tool")
  fi
done

if [ "${#missing_tools[@]}" -gt 0 ]; then
  echo "Missing required tools: ${missing_tools[*]}"
  echo "Installing missing packages..."
  sudo apt-get update -qq && sudo apt-get install -y -qq parted gdisk qemu-user-static binfmt-support  # parted also provides partprobe, gdisk provides sgdisk

  # verify everything was installed
  for tool in "${required_tools[@]}"; do
    if [ ! -x "$tool" ]; then
      echo "ERROR: Failed to install '$tool'. Please install the appropriate package manually."
      exit 1
    fi
  done
fi


# find the root (ext4) partition by filesystem type using lsblk
fs_partition=$(lsblk -lnpo NAME,FSTYPE ${BLK_DEVICE} | grep -i ext4 | awk '{print $1}')

if [ -z "$fs_partition" ]; then
  echo "Could not find root (ext4) partition on ${BLK_DEVICE}"
  lsblk -lpo NAME,FSTYPE,SIZE ${BLK_DEVICE}
  exit 1
fi

# resize root partition to fill the remaining space of the disk
echo "Resizing root partition to fill the remaining space of the disk..."

# fix GPT backup header if the disk was cloned from a smaller image
sudo sgdisk -e ${BLK_DEVICE} 2>/dev/null || true

fs_partnum=$(echo ${fs_partition} | grep -oP '\d+$')
sudo parted -s ${BLK_DEVICE} resizepart ${fs_partnum} 100%
sudo partprobe ${BLK_DEVICE}
sudo udevadm settle

# setup mounts (re-discover boot partition after partprobe)
echo "Setting up mounts..."
boot_partition=$(lsblk -lnpo NAME,FSTYPE ${BLK_DEVICE} | grep -i vfat | awk '{print $1}')

if [ -z "$boot_partition" ]; then
  echo "Could not find boot (vfat) partition on ${BLK_DEVICE}"
  lsblk -lpo NAME,FSTYPE,SIZE ${BLK_DEVICE}
  exit 1
fi

sudo mkdir -p ${MOUNT_TARGET} ${MOUNT_TARGET}/boot ${MOUNT_TARGET}/fs
sudo mount ${boot_partition} ${MOUNT_TARGET}/boot
sudo mount ${fs_partition} ${MOUNT_TARGET}/fs

# resize root filesystem to match the expanded partition
echo "Resizing root filesystem..."
sudo resize2fs ${fs_partition}


# write authorized_keys directly
echo "Writing authorized_keys..."
sudo mkdir -p ${MOUNT_TARGET}/fs/root/.ssh
sudo tee ${MOUNT_TARGET}/fs/root/.ssh/authorized_keys > /dev/null <<< "$(cat ${SSH_PUBKEY})"
sudo chmod 700 ${MOUNT_TARGET}/fs/root/.ssh
sudo chmod 600 ${MOUNT_TARGET}/fs/root/.ssh/authorized_keys

# set root password directly in shadow file
echo "Setting root password..."
if command -v mkpasswd >/dev/null 2>&1; then
  crypted_password=$(mkpasswd -m sha-512 "${ROOT_PASSWORD}")
else
  crypted_password=$(openssl passwd -6 "${ROOT_PASSWORD}")
fi
sudo sed -i "s|^root:[^:]*|root:${crypted_password}|" ${MOUNT_TARGET}/fs/etc/shadow

# set timezone directly
echo "Setting timezone..."
sudo mkdir -p ${MOUNT_TARGET}/fs/usr/share/zoneinfo
sudo tee ${MOUNT_TARGET}/fs/etc/timezone > /dev/null <<< "${TIMEZONE}"
sudo ln -sf /usr/share/zoneinfo/${TIMEZONE} ${MOUNT_TARGET}/fs/etc/localtime

# resolv.conf is a symlink on modern Debian; replace it with a regular file before chroot
echo "Replacing resolv.conf..."
sudo rm -f ${MOUNT_TARGET}/fs/etc/resolv.conf
sudo cp ${config_files}/resolv.conf ${MOUNT_TARGET}/fs/etc/resolv.conf

# install and enable openssh-server via QEMU chroot (if qemu-user-static is available)
echo "Installing openssh-server via QEMU chroot..."
if [ -x /usr/bin/qemu-aarch64-static ] && [ -d /proc/sys/fs/binfmt_misc ]; then
  sudo cp /usr/bin/qemu-aarch64-static ${MOUNT_TARGET}/fs/usr/bin/
  sudo chroot ${MOUNT_TARGET}/fs /usr/bin/qemu-aarch64-static /bin/bash -c "\
    apt-get update && \
    apt-get install -y openssh-server && \
    systemctl enable ssh"
  sudo rm ${MOUNT_TARGET}/fs/usr/bin/qemu-aarch64-static
else
  echo "WARNING: qemu-user-static not available. SSH server must be installed manually after first boot."
fi

# use a pre-configured static ip via systemd-networkd
echo "Setting up static IP via systemd-networkd..."
sudo mkdir -p ${MOUNT_TARGET}/fs/etc/systemd/network
sudo cp ${config_files}/10-end0.network ${MOUNT_TARGET}/fs/etc/systemd/network/10-end0.network


# unmount and cleanup
echo "Unmounting and cleaning up..."
sudo umount -R ${MOUNT_TARGET} 2>/dev/null || true
sudo rmdir ${MOUNT_TARGET}/boot ${MOUNT_TARGET}/fs ${MOUNT_TARGET} 2>/dev/null || true
