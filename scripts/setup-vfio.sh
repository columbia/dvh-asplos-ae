#/bin/bash

source vfio-common.sh

modprobe -v vfio-pci
modprobe -v vfio_iommu_type1 $TYPE1_OPTION
echo $BDF > /sys/bus/pci/devices/$BDF/driver/unbind
echo $DEV_ID  > /sys/bus/pci/drivers/vfio-pci/new_id
ls /dev/vfio/
