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

QEMU_CMD_x86='/srv/vm/qemu/x86_64-softmmu/qemu-system-x86_64 --version'
QEMU_CMD_ARM='/srv/vm/qemu-system-aarch64 --version'
QEMU_CMD_ARM_L1='/root/vm/qemu-system-aarch64 --version'

if [[ "$MACHINE" == "x86_64" ]]; then
	QEMU_CMD=$QEMU_CMD_x86
	TRACE_CMD='cat /boot/config-`uname -r` | grep CONFIG_FTRACE=y | wc -l'
else
	QEMU_CMD=$QEMU_CMD_ARM
	TRACE_CMD='gunzip -c /proc/config.gz | grep CONFIG_FTRACE=y | wc -l'
fi


IRQB_CMD="pgrep irqbalance"

function proceed()
{
	read -r -p "$1 [y/N] " response
	case "$response" in
	    [yY][eE][sS]|[yY]) 
		;;
	    *)
		exit
		;;
	esac
}

function kernel_ok()
{
	if [[ $1 == $2 ]]; then
		echo "KERNEL OK"
	else
		echo "**** WARNING: CHECK KERNEL VERSION"
		proceed "Want to Proceed?"
	fi
}

function qemu_ok()
{
	if [[ $1 == $TEST_QEMU ]]; then
		echo "QEMU OK"
	else
		echo "**** WARNING: CHECK QEMU VERSION"
		proceed "Want to Proceed?"
	fi
}

function vcpu_pin_check()
{

	if [[ "$TEST_LEVEL" == "L1" ]]; then
		proceed "Have you pinned vcpus in L0?"
	fi
	if [[ "$TEST_LEVEL" == "L2" ]]; then
		proceed "Have you pinned vcpus in L0 AND L1?"
	fi
}

function mem_check()
{
	proceed "Have you consumed memory in L0?"
}

function kernel_check()
{
	if [[ -z "$2" ]]; then
		MY_KERNEL=$KERNEL
	else
		MY_KERNEL=`ssh $2@$3 $KERNEL_CMD`
	fi
	echo "$1 Kernel: $MY_KERNEL"
	kernel_ok $MY_KERNEL $TEST_KERNEL
}

function trace_check()
{
	TRACE_ON=`ssh $2@$3 $TRACE_CMD`
	if [[ $TRACE_ON == "0" ]]; then
		echo "$1 TRACE OFF"
	else
		proceed "$1 TRACE is ON. Want to Proceed?"
	fi
}


function qemu_check()
{
	if [[ "$1" == "L1" && "$MACHINE" == "aarch64" ]]; then
		QEMU_CMD=$QEMU_CMD_ARM_L1
	fi
	QEMU_VERSION=`ssh $2@$3 $QEMU_CMD`

	MY_QEMU_VERSION=`echo $QEMU_VERSION | grep version | awk '{ print $4 }'`
	echo "$1 QEMU: $MY_QEMU_VERSION"
	qemu_ok $MY_QEMU_VERSION
}

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

function kernel_check_all()
{
	kernel_check Client
	check_all kernel_check
}

function trace_check_all()
{
	check_all trace_check
}

function qemu_check_all()
{
	check_all_one_less qemu_check
}

function irqb_check()
{
	if [[ -z "$2" ]]; then
		IRQB=`$IRQB_CMD`
	else
		IRQB=`ssh $2@$3 $IRQB_CMD`
	fi

	if [[ $? -eq 0 ]]; then
		echo "irqbalance is running: $IRQB in $1"
	else
		echo "irqbalance is NOT running"
		proceed "Want to Proceed?"
	fi
}

function irqbalance_check_all()
{
	irqb_check Client
	check_all irqb_check
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

kernel_check_all
trace_check_all
qemu_check_all
mem_check
swap_off_all
vcpu_pin_check
irqbalance_check_all
