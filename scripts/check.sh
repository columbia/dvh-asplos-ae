#!/bin/bash

#########
TEST_KERNEL="4.18.0"
TEST_QEMU="3.1.0"
#########

L_IP[0]="$L0_IP"
L_IP[1]="$L1_IP"
L_IP[2]="$L2_IP"
L_IP[3]="$L3_IP"

# L0 to L3. Can be extended to Lx easilly
TEST_LEVEL=$1
# int version of test level
level=${TEST_LEVEL: -1}
USER=root

MACHINE=`uname -m`
KERNEL=`uname -r`
KERNEL_CMD='uname -r'

function check_all()
{
	fn=$1
	LOCAL_TEST_LEVEL=${2:-"$level"}

	for i in `seq 0 $LOCAL_TEST_LEVEL`
	do
		$fn L${i} root ${L_IP[$i]}
	done
}

# This checks everything except the target level
function check_all_one_less()
{
	fn=$1

	LOCAL_TEST_LEVEL=${2:-"$level"}
	LOCAL_TEST_LEVEL=`expr $LOCAL_TEST_LEVEL - 1`

	check_all $fn $LOCAL_TEST_LEVEL
}


SWAP_CMD="swapoff -a"
function swap_off()
{
	ssh $2@$3 $SWAP_CMD
}

function swap_off_all()
{
	echo "Turning off swap"
	check_all swap_off
}

swap_off_all
