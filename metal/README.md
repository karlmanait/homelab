# Hardware Setup
This section guides you through the process of flashing the operating system image onto
a microSD card and configuring the initial boot settings.

Before proceeding, ensure that the `BLK_DEVICE` variable has the correct value.

## IP Cam
Flash motioneyeOS and configure initial settings, including WiFi and IP configuration.

#### Steps:
1. Download image<br/>
`$ make images/motioneyeos-raspberrypi-20200203.img.xz`
1. Flash image<br/>
`$ make ip-cam/flash-image`
1. Update the files in `ip-cam/configs/`
1. Setup initial boot configuration<br/>
`$ make ip-cam/post-flash-setup`
