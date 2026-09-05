# Hardware Setup
This section guides you through the process of flashing the operating system image onto
a microSD card or external SSD and configuring the initial boot settings.

Before proceeding, ensure the following variables in `metal/Makefile` and `metal/compute-node/post-flash-setup.sh` have the correct values:
- `BLK_DEVICE` — the block device of your microSD card or external SSD (e.g. `/dev/sdb`)
- `COMPUTE_NODE_IMAGE_SRC` — the source URL for the compute node image
- `IP_CAM_IMAGE_SRC` — the source URL for the IP cam image

For the compute node, also review these in `metal/compute-node/post-flash-setup.sh`:
- `ROOT_PASSWORD` — the root password set on first boot
- `TIMEZONE` — the timezone (e.g. `Asia/Manila`, `UTC`)
- `SSH_PUBKEY` — path to your SSH public key

## Compute Node
Flash debian13 image for raspberry pi and configure initial settings.

### Prerequisites
Install the following packages on your host machine:
- `qemu-user-static` and `binfmt-support` — allows the post-flash setup script to install
  packages into the ARM64 rootfs via QEMU emulation
- `parted` — used to resize the root partition to fill the entire disk
- `gdisk` — provides `sgdisk`, used to relocate the GPT backup header when flashing
  a disk image to a larger SSD

```
$ sudo apt install qemu-user-static binfmt-support parted gdisk
```

### Steps:
1. Download image<br/>
`$ make images/debian-13-raspi-arm64-20260831-2587.tar.xz`
1. Flash image<br/>
`$ make compute-node/flash-image`
1. Update the files in `compute-node/configs/`
1. Setup initial boot configuration<br/>
`$ make compute-node/post-flash-setup`


## IP Cam
Flash motioneyeOS and configure initial settings, including WiFi and IP configuration.

### Steps:
1. Download image<br/>
`$ make images/motioneyeos-raspberrypi-20200203.img.xz`
1. Flash image<br/>
`$ make ip-cam/flash-image`
1. Update the files in `ip-cam/configs/`
1. Setup initial boot configuration<br/>
`$ make ip-cam/post-flash-setup`
