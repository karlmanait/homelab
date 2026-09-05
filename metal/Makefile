# Configurations #
BLK_DEVICE="/dev/sdb"
COMPUTE_NODE_IMAGE_SRC="https://cloud.debian.org/images/cloud/trixie/20260831-2587/debian-13-raspi-arm64-20260831-2587.tar.xz"
IP_CAM_IMAGE_SRC="https://github.com/motioneye-project/motioneyeos/releases/download/20200203/motioneyeos-raspberrypi-20200203.img.xz"
# End Configurations #

compute_node_image=$(shell echo "${COMPUTE_NODE_IMAGE_SRC}" | grep -oP "[^\/]+$$")
ip_cam_image=$(shell echo "${IP_CAM_IMAGE_SRC}" | grep -oP "[^\/]+$$")

images/${compute_node_image}:
	wget ${COMPUTE_NODE_IMAGE_SRC} -O images/${compute_node_image}

images/${ip_cam_image}:
	wget ${IP_CAM_IMAGE_SRC} -O images/${ip_cam_image}

.PHONY: compute-node/flash-image
compute-node/flash-image:
	sudo wipefs -a ${BLK_DEVICE}
	if echo "${compute_node_image}" | grep -q '\.tar\.xz$$'; then \
		tar -xJf images/${compute_node_image} -O | sudo dd bs=128M of=${BLK_DEVICE} status=progress conv=fdatasync; \
	else \
		xz -d < images/${compute_node_image} | sudo dd bs=128M of=${BLK_DEVICE} status=progress conv=fdatasync; \
	fi

.PHONY: compute-node/post-flash-setup
compute-node/post-flash-setup:
	compute-node/post-flash-setup.sh ${BLK_DEVICE}

.PHONY: ip-cam/flash-image
ip-cam/flash-image:
	sudo wipefs -a ${BLK_DEVICE}
	xz -d < images/${ip_cam_image} | sudo dd bs=128M of=${BLK_DEVICE} status=progress conv=fdatasync

.PHONY: ip-cam/post-flash-setup
ip-cam/post-flash-setup:
	ip-cam/post-flash-setup.sh ${BLK_DEVICE}
