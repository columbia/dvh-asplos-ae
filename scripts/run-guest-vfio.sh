#!/bin/bash

source run-guest-common.sh

source setup-vfio.sh

# Do not provide a normal virtio-net device.
# Doing that resulted in a severe performance drop for vp on x86
# This is because the VM having both virtio and assigned device will be
# receiving packets from one of them arbitrarily.
VIRTIO_NETDEV=""

if [[ "$ARCH" == "x86_64" ]]; then
	source qemu-command-x86.sh
else
	source qemu-command-arm.sh
fi
