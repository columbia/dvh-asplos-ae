#!/bin/bash

TOTAL_RAM_KB=`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`
TOTAL_RAM=$(($TOTAL_RAM_KB/1024))
SETUP_RAM=${1:-12}
CONSUME_RAM=$((TOTAL_RAM-SETUP_RAM*1024))
RAMDISK=/mnt/ramdisk

echo "Consume memory except "$SETUP_RAM"G"

sudo umount -f $RAMDISK
sudo mkdir -p $RAMDISK
sudo mount -t ramfs none $RAMDISK
sudo dd if=/dev/zero of=$RAMDISK/use bs=1M count=$CONSUME_RAM
