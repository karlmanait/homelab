# Configurations #
BLK_DEVICE="/dev/sdc"
# End Configurations #


ip_cam_image_src="https://github.com/motioneye-project/motioneyeos/releases/download/20200203/motioneyeos-raspberrypi-20200203.img.xz"
cluster_node_image_src="https://raspi.debian.net/tested/20230612_raspi_4_bookworm.img.xz"
ip_cam_image=$(shell echo "${ip_cam_image_src}" | grep -oP "[^\/]+$$")
cluster_node_image=$(shell echo "${cluster_node_image_src}" | grep -oP "[^\/]+$$")

images/${ip_cam_image}:
	wget ${ip_cam_image_src} -O images/${ip_cam_image}

images/${cluster_node_image}:
	wget ${cluster_node_image_src} -O images/${cluster_node_image}

.PHONY: ip-cam/flash-image
ip-cam/flash-image:
	xz -d < images/${ip_cam_image} | sudo dd bs=128M of=${BLK_DEVICE} status=progress conv=fdatasync

.PHONY: ip-cam/post-flash-setup
ip-cam/post-flash-setup:
	ip-cam/post-flash-setup.sh ${BLK_DEVICE}

.PHONY: cluster-node/flash-image
cluster-node/flash-image:
	xz -d < images/${cluster_node_image} | sudo dd bs=128M of=${BLK_DEVICE} status=progress conv=fdatasync

.PHONY: cluster-node/post-flash-setup
cluster-node/post-flash-setup:
	cluster-node/post-flash-setup.sh ${BLK_DEVICE}
