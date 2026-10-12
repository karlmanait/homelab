# Hardware Setup
This section guides you through the process of flashing the operating system image onto a microSD card or external SSD and configuring the initial boot settings.

Before proceeding, ensure the following variables in `metal/Makefile` have the correct values:
- `BLK_DEVICE` — the block device of your microSD card or external SSD (e.g. `/dev/sdc`).
  Check with `lsblk` before flashing, or override per run: `make <target> BLK_DEVICE=/dev/sdX`
- `COMPUTE_NODE_IMAGE_SRC` — the source URL for the compute node image
- `IP_CAM_IMAGE_SRC` — the source URL for the IP cam image

## Compute Node
Flash debian13 image for Raspberry Pi and configure initial settings.

Review these in `compute-node/post-flash-setup.sh`:
- `ROOT_PASSWORD` — the root password set on first boot
- `TIMEZONE` — the timezone (e.g. `Asia/Manila`, `UTC`)
- `SSH_PUBKEY` — path to your SSH public key

And in `compute-node/configs/`:
- `10-end0.network` — `Address` (static IP), `Gateway` and `DNS` for the wired interface (e.g. `192.168.1.40/24`, `192.168.1.1`)
- `resolv.conf` — DNS nameservers; also used during the QEMU chroot to install `openssh-server`

### Prerequisites
Install the following packages on your host machine:
- `qemu-user-static` and `binfmt-support` — allows the post-flash setup script to install packages into the ARM64 rootfs via QEMU emulation
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
Flash Raspberry Pi OS Lite (32-bit) for the Pi Zero W and configure initial settings, including SSH, WiFi and IP configuration.

Review these in `ip-cam/post-flash-setup.sh`:
- `ROOT_PASSWORD` — the root password for console login (SSH as root is key-only)
- `TIMEZONE` — the timezone (e.g. `Asia/Manila`, `UTC`)
- `WIFI_COUNTRY` — the WiFi regulatory domain (e.g. `PH`)
- `MEDIAMTX_SRC` — the source URL for the MediaMTX release (`linux_armv6`), downloaded into `packages/`
- `SSH_PUBKEY` — path to your SSH public key

And in `ip-cam/configs/wlan0.nmconnection`:
- `ssid` / `psk` — the WiFi network (2.4 GHz, WPA2) and password; don't commit the real password
- `address1` — the static IP and default gateway (e.g. `192.168.1.50/24,192.168.1.1`)

And in `ip-cam/configs/mediamtx.yml`:
- `pass` — the password of the `frigate` stream user, must match `FRIGATE_RTSP_PASSWORD` in `services/frigate/.env`; don't commit the real password
- `rpiCamera*` — the stream resolution, fps and bitrate

### Steps:
1. Download image<br/>
`$ make images/2026-10-06-raspios-trixie-armhf-lite.img.xz`
1. Flash image<br/>
`$ make ip-cam/flash-image`
1. Update the files in `ip-cam/configs/`
1. Setup initial boot configuration<br/>
`$ make ip-cam/post-flash-setup`
