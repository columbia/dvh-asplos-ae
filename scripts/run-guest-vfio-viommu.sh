#!/bin/bash

source run-guest-common.sh

source setup-vfio.sh

if [[ "$ARCH" == "x86_64" ]]; then
	source setup-iommu.sh pt
	source qemu-command-x86.sh
else
	source qemu-command-arm.sh
fi
