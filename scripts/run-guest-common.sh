#!/bin/bash

source common.sh

CONSOLE=mon:stdio
KERNEL=Image
INCOMING=""
# This is not effective on x86
CMDLINE="earlycon=pl011,0x09000000"
DUMPDTB=""
DTB=""
NESTED=""
SMMU="v8"
MODERN="disable-modern=off,disable-legacy=on"
OV=""
TELNET_PORT=4444
WAIT="nowait"
MON="-monitor telnet:127.0.0.1:$TELNET_PORT,server,nowait"
QEMU_APPEND=""

#Check if we are on a bare-metal machine
uname -n | grep -q cloudlab
err=$?

if [[ $err == 0 ]]; then
#L0 specific settings
	FS=/vmdata/linaro-trusty.img
	NESTED=",nested=true"
else
#L1 specific settings
	FS=l2.img
fi

HOST_CPU=`nproc`
SMP=`expr $HOST_CPU - 2`

# 12 (default) + 12G per each virt level
# e.g. L2 got 12G, and L1 got 24G and L0 got 36G
# memsize = 12 + (smp - 4) / 2 * 12
MEMSIZE=`expr $SMP \* 6 - 12`

if [[ "$ARCH" == "x86_64" ]]; then
	QEMU=./qemu/x86_64-softmmu/qemu-system-x86_64
	FS=/vm/guest0.img
	MACHINE="q35,accel=kvm"
else
	QEMU="./qemu-system-aarch64"
	# FS is already set
	MACHINE="virt${DUMPDTB}"
fi

usage() {
	U=""
	if [[ -n "$1" ]]; then
		U="${U}$1\n\n"
	fi
	U="${U}Usage: $0 [options]\n\n"
	U="${U}Options:\n"
	U="$U    -c | --CPU <nr>:       Number of cores (default ${SMP})\n"
	U="$U    -m | --mem <GB>:       Memory size (default ${MEMSIZE})\n"
	U="$U    -s | --migration-src:   Run the guest as the migration source\n"
	U="$U    -t | --migration-dst: run the guest as the migration dest\n"
	U="$U    -l | --migration-dst-file: run the guest restoring from a file\n"
	U="$U    -k | --kernel <Image>: Use kernel image (default ${KERNEL})\n"
	U="$U    -s | --serial <file>:  Output console to <file>\n"
	U="$U    -i | --image <image>:  Use <image> as block device (default $FS)\n"
	U="$U    -a | --append <snip>:  Add <snip> to the kernel cmdline\n"
	U="$U    -p | --qemu-append <snip>:  Add <snip> to the QEMU cmdline\n" 
	U="$U    -v | --smmu <version>:  Specify SMMUv3 patch version\n"
	U="$U    -q | --mq <nr>:        Number of multiqueus for virtio-net\n"
	U="$U    -u | --qemu <src_path> : Use qemu in the given path\n"
	U="$U    -x | --xen:		Run Xen as a guest hypervisor\n"
	U="$U    -o | --over-commit:	Make the guest control power mode\n"
	U="$U    -w | --wait:		Wait until vcpus are pinned\n"
	U="$U    --modern:		Run a modern virtio net dev\n"
	U="$U    --legacy:		Run a legacy virtio net dev\n"
	U="$U    --monitor:		Run a qemu monitor\n"
	U="$U    --pi:		       Enable posted interrupt cap in vIOMMU\n"
	U="$U    --win:		       Run windows guest\n"
	U="$U    --cap:		       Add state capture capability to virtio dev\n"
	U="$U    --dumpdtb <file>       Dump the generated DTB to <file>\n"
	U="$U    --dtb <file>           Use the supplied DTB instead of the auto-generated one\n"
	U="$U    --debug-bios <file>:	Debug custom BIOS\n"
	U="$U    -h | --help:           Show this output\n"
	U="${U}\n"
	echo -e "$U" >&2
}

while :
do
	case "$1" in
	  -c | --cpu)
		SMP="$2"
		shift 2
		;;
	  -m | --mem)
		MEMSIZE="$2"
		shift 2
		;;
	  -s | --migration-src)
		M_SRC=1
		MIGRAION_SET=1
		shift 1
		;;
	  -t | --migration-dst)
		MIGRAION_SET=1
		MIGRAION_DST=1
		shift 1
		;;
	  -l | --migration-dst-file)
		M_FILE="$2"
		MIGRAION_SET=1
		shift 2
		;;
	  -k | --kernel)
		KERNEL="$2"
		shift 2
		;;
	  -s | --serial)
		CONSOLE="file:$2"
		shift 2
		;;
	  -i | --image)
		FS="$2"
		shift 2
		;;
	  -a | --append)
		CMDLINE="$2"
		shift 2
		;;
	  -p | --qemu-append)
		QEMU_APPEND="$2"
		shift 2
		;;
	  -v | --smmu)
		SMMU="$2"
		shift 2
		;;
	  -q | --mq)
		MQ_NUM="$2"
		shift 2
		;;
	  -u | --qemu)
		QEMU_F="$2"
		shift 2
		;;
	  --modern)
		shift 1
		;;
	  --legacy)
		MODERN=""
		shift 1
		;;
	  --monitor)
		MONITOR_F=1
		shift 1
		;;
	  --pi)
		PI=1
		shift 1
		;;
	  --dumpdtb)
		DUMPDTB=",dumpdtb=$2"
		shift 2
		;;
	  --dtb)
		DTB="-dtb $2"
		shift 2
		;;
	  --win)
	  	WINDOWS=1
		shift 1
		;;
	  -x | --xen)
		XEN=1
		shift 1
		;;
	  -o | --over-commit)
		OV="-overcommit cpu-pm=on"
		shift 1
		;;
	  -w | --wait)
		WAIT="wait"
		shift 1
		;;
	  --cap)
		VIRTIO_STATE_CAP=1
		shift 1
		;;
	  --debug-bios)
		  # clone https://github.com/coreboot/seabios.git, and build it
		  # Run the script.
		  # ./run-guest.sh --debug-bios seabios/out/bios.bin
		  CUSTOM_BIOS="-bios $2"
		  DBG_BIOS_OPTION="-chardev stdio,id=seabios -device isa-debugcon,iobase=0x402,chardev=seabios"
		  DBG_BIOS="$CUSTOM_BIOS $DBG_BIOS_OPTION"
		  MON="-monitor none"
		  CONSOLE="telnet:127.0.0.1:$TELNET_PORT,server,nowait"
		shift 2
		;;
	  -h | --help)
		usage ""
		exit 1
		;;
	  --) # End of all options
		shift
		break
		;;
	  -*) # Unknown option
		echo "Error: Unknown option: $1" >&2
		exit 1
		;;
	  *)
		break
		;;
	esac
done

USER_NETDEV="-netdev user,id=net0,hostfwd=tcp::2222-:22"
USER_NETDEV="$USER_NETDEV -device virtio-net-pci,netdev=net0"

echo "Using bridged networking"
VIRTIO_NETDEV="-netdev tap,id=net1,vhost=on"
if [ ! -z "$MQ_NUM" ]; then
	VIRTIO_NETDEV="$VIRTIO_NETDEV,queues=$MQ_NUM"
else
	# We know where QEMU is for AE repo
	VIRTIO_NETDEV="$VIRTIO_NETDEV,helper=../qemu/qemu-bridge-helper"
fi

VIRTIO_NETDEV="$VIRTIO_NETDEV -device virtio-net-pci,netdev=net1"
if [ ! $MODERN == "" ]; then
	VIRTIO_NETDEV="$VIRTIO_NETDEV,$MODERN"
fi

if [ ! -z "$MQ_NUM" ]; then
	VECTOR_NUM=`expr 2 \* "$MQ_NUM" + 2`
	VIRTIO_NETDEV="$VIRTIO_NETDEV,mq=on,vectors=$VECTOR_NUM"
fi

find_available_mac() {
    # Need to append "x:yz" to the prefix
    # x: machine ID (i.e. last digit of host private IP)
    # y: virtualization level
    # z: device ID in this VM
    MAC_PREFIX="de:ad:be:ef:f"
    z=$1

    if [ "$IS_HOST" == 1 ]; then
        x=$IP_TAIL
        y=1
    else
        MAC_TMP=`ifconfig | grep -m 1 "de:ad" | awk '{ print $5 }'`
        # Inherit the machine ID
        x=`echo ${MAC_TMP:13:1}`
        # Add one more virt level
        y=`echo ${MAC_TMP:15:1}`
        let "y++"
    fi

    MAC=$MAC_PREFIX$x":"$y$z
}

find_available_mac 1
VIRTIO_NETDEV="$VIRTIO_NETDEV,mac=$MAC"

find_available_mac 2
USER_NETDEV="$USER_NETDEV,mac=$MAC"

set_remote_fs () {
	mount | grep vm_nfs 2>&1 > /dev/null
	if [[ $? != 0 ]]; then
		echo "Trying to mount nfs directory from 10.10.1.1"
		mkdir -p /vm_nfs
		mount 10.10.1.1:/vm /vm_nfs
		echo "Mount done"
	fi
	FS=/vm_nfs/$1
}

# Migration related settings
if [ -n "$MIGRAION_SET" ]; then
	if [ -n "$MIGRAION_DST" ]; then
		M_PORT=5555
		TELNET_PORT=4445
		MIGRAION=(-incoming tcp:0:$M_PORT)

		# Tweak params which conflict with the source
		USER_NETDEV=`echo $USER_NETDEV | sed  "s/2222/2223/"`
		MONITOR_F=1
	elif [ -n "$M_FILE" ]; then
		MIGRAION=(-incoming "exec: gzip -c -d $M_FILE")
		MONITOR_F=1
	fi

	set_remote_fs guest0.img

	if [ "$WINDOWS" == 1 ]; then
		echo "We don't support Windows migration yet"
		# TODO: just set FS correctly.
		exit
	fi
fi

if [ "$WINDOWS" == 1 ]; then
	WIN_ISO=en_windows_server_2016_updated_feb_2018_x64_dvd_11636692.iso
	VIRTIO_ISO=virtio-win.iso
	CPU_HV=",hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time"
	WINDOWS_OPTIONS=""
	WINDOWS_OPTIONS="$WINDOWS_OPTIONS -usb -device usb-tablet"
	WINDOWS_OPTIONS="$WINDOWS_OPTIONS -rtc base=localtime,clock=host"
	WINDOWS_OPTIONS="$WINDOWS_OPTIONS -vnc 127.0.0.1:4"
	#WINDOWS_OPTIONS="$WINDOWS_OPTIONS --cdrom ${WIN_ISO}"
	#WINDOWS_OPTIONS="$WINDOWS_OPTIONS --drive file=${VIRTIO_ISO},index=3,media=cdrom"
	WINDOWS_OPTIONS="$WINDOWS_OPTIONS --cdrom ${VIRTIO_ISO}"
	MONITOR_F=1
fi

if [ "$XEN" == 1 ]; then
	# If we do viommu + vfio, which changes QEMU, the QEMU has already patch for Xen.
	# So, this QEMU is only for the viommu only case.
#	QEMU="./qemu-xen-fix/x86_64-softmmu/qemu-system-x86_64"

	# If we alloc 24G for L1, and dedicate 12G for L2 dom0, then we can't alloc 12G for L2 domU.
	# So, give 1G buffer. Note that L2 dom0 and L2 domU will remain to have exactly 12G.
	MEMSIZE=`expr $MEMSIZE + 1`
fi

hostname=`hostname | cut -d . -f1`
if [ -z $MIGRAION_DST ]  && [ "$IS_HOST" == 1 ]; then
	# Install host ssh key to VM
	if [ "$WINDOWS" != 1 ]; then
		source mount-and-copy-ssh-key.sh $FS
	fi
fi

