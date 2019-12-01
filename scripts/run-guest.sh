#!/bin/bash

source run-guest-common.sh

if [[ "$ARCH" == "x86_64" ]]; then
	source qemu-command-x86.sh
else
	source qemu-command-arm.sh
fi
