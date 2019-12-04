#!/bin/bash

# A stand-alone script to add ssh keys to VMs
# By default, it adds host and client keys to VMs.

ARCH=`uname -m`

if [[ "$ARCH" == "x86_64" ]]; then
	TARGET_IMG=/vm/guest0.img
else
	TARGET_IMG=/vmdata/linaro-trusty.img
fi

TARGET_IMG=${1:-$TARGET_IMG}

L2_IMG=0
L3_IMG=0
mkdir -p /mnt_l1
mkdir -p /mnt_l2
mkdir -p /mnt_l3
if [[ "$ARCH" == "aarch64" ]]; then
	sudo mount -o loop $TARGET_IMG /mnt_l1
	if [[ -f /mnt_l1/root/vm/l2.img ]]; then
		sudo mount -o loop /mnt_l1/root/vm/l2.img /mnt_l2
		L2_IMG=1
	fi
elif [[ "$ARCH" == "x86_64" ]]; then
	mount -o loop,offset=1048576 $TARGET_IMG /mnt_l1

	if [[ -f /mnt_l1/vm/guest0.img ]]; then
		mount -o loop,offset=1048576 /mnt_l1/vm/guest0.img /mnt_l2
		L2_IMG=1
	fi

	if [[ -f /mnt_l2/vm/guest0.img ]]; then
		mount -o loop,offset=1048576 /mnt_l2/vm/guest0.img /mnt_l3
		L3_IMG=1
	fi
fi

HOST_R_KEY=`cat /root/.ssh/id_rsa.pub`

EXP_NAME=`uname -a | awk '{print $2}' | cut -d. -f2`
CLIENT_KEY=`cat client_ssh_public`

L1_AUTH_FILE="/mnt_l1/root/.ssh/authorized_keys"
L2_AUTH_FILE="/mnt_l2/root/.ssh/authorized_keys"
if [[ $L3_IMG == 1 ]]; then
	L3_AUTH_FILE="/mnt_l3/root/.ssh/authorized_keys"
fi

for key in "$HOST_R_KEY" "$CLIENT_KEY"
do
	for auth_file in $L1_AUTH_FILE $L2_AUTH_FILE $L3_AUTH_FILE
	do
		if [ "$auth_file" == "$L3_AUTH_FILE" ] && [ -z $L3_AUTH_FILE ]; then
			continue
		fi

		if [[ -f $auth_file ]]; then
			grep -q "$key" $auth_file
			err=$?
			if [[ $err != 0 ]]; then
				echo "$key" >> $auth_file
			fi
		fi
	done
done

L0_AUTH_FILE="/root/.ssh/authorized_keys"
grep -q "$CLIENT_KEY" $L0_AUTH_FILE
err=$?
if [[ $err != 0 ]]; then
	echo "$CLIENT_KEY" >> $L0_AUTH_FILE
fi

if [[ $L3_IMG == 1 ]]; then
	sudo umount /mnt_l3
fi

if [[ $L2_IMG == 1 ]]; then
	sudo umount /mnt_l2
fi

sudo umount /mnt_l1
