#!/bin/bash

source common.sh

if [[ "$ARCH" == "x86_64" ]]; then
	source run-guest-intel-viommu.sh
else
	source run-guest-smmu.sh
fi
