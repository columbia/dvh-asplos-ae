#!/bin/bash

source run-guest-common.sh

source setup-iommu.sh vp
source setup-virtio-vp.sh

if [ "$VIRTIO_STATE_CAP" == 1 ]; then
	QEMU="./qemu-migration/x86_64-softmmu/qemu-system-x86_64"
fi

source qemu-command-x86.sh

