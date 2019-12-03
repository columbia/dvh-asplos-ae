#!/bin/bash
apt-get build-dep qemu
apt-get build-dep linux
apt-get install bridge-utils
apt-get install python-pip
pip install 'pexpect==3.1' --force-reinstall
