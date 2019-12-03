#!/bin/bash

LIST='build-n-install.sh copy-kernel.sh pin_vcpus.sh qmp.py qmp-cpus'
DST=/usr/local/bin
cp $LIST $DST

mkdir -p /usr/local/etc/qemu/
echo "allow br0" >  /usr/local/etc/qemu/bridge.conf

