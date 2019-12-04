source common.sh
SRIOV="/sys/class/net/$ETH/device/sriov_numvfs"

function create_vf()
{
	VF=`cat $SRIOV`
	if [[ $VF == 0 ]]; then
		echo "We are about to create two physical VFs"
		echo 2 > $SRIOV
	fi

	VF=`cat $SRIOV`
	echo "We have physical VFs: $VF"
}

CLOUD=""
uname -a | grep -q apt
err=$?
if [[ $err == 0 ]]; then
	CLOUD="APT"
fi

ifconfig | grep -q "128\."
err=$?

# Create VFs in x86 L0
if [[ $err == 0 ]]; then
	if [[ "$ARCH" == "x86_64" ]]; then
		create_vf
	fi
fi

# TODO: test this on ARM and remove this comment!
# This physical network device is for Wisc machines.
BDF_P=`lspci | grep Virtual.Function | head -1 | awk '{ print $1 }'`
# As we have multiple virtio modern devices, which have the device id 1041,
# let's get the last one, which is *probably* the one to pass to the nested VM.
BDF_V=`lspci | grep Red.Hat.*1041 | tail -n 1 | awk '{ print $1 }'`
#e1000 doesn't work
#BDF_E=`lspci | grep 82540EM  | awk '{ print $1 }'`
BDF_E=`lspci | grep Realtek.*8139 | awk '{ print $1 }'`

if [[ "$BDF_E" != "" ]]; then
	echo "Virtual-passthrough with the emulated device"
	BDF=$BDF_E
elif [[ "$BDF_P" != "" && "$BDF_V" != "" ]]; then
	echo "We have VF and virtio-net. Do the physical passthrough"
	BDF=$BDF_P
elif [[ "$BDF_P" == "" && "$BDF_V" == "" ]]; then
	echo "We have no device to assign to a VM."
	exit
elif [[ "$BDF_P" != "" ]]; then
	echo "Physical passthrough."
	BDF=$BDF_P
else
	echo "Virtual-passthrough. Yeah!"
	BDF=$BDF_V
fi

DEV_ID=`lspci -nn | grep $BDF | cut -d[ -f3 | cut -d] -f1 | sed 's/:/ /'`

if [[ "$ARCH" == "aarch64" ]]; then
	# ARM IOMMU emulation doesn't support interrupt remapping yet
	# Enable this option on x86 if you want not to use irq-remapping
	TYPE1_OPTION="allow_unsafe_interrupts=1"
fi

BDF=0000:$BDF

echo "BDF: "$BDF
echo "DEV_ID: "$DEV_ID

VFIO_DEV="-device vfio-pci,host=$BDF,id=net2"
