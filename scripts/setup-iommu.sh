IOMMU="-device intel-iommu,intremap=on"
MACHINE="${MACHINE},kernel-irqchip=split"

if [ "$PI" == 1 ]; then
	IOMMU="$IOMMU,intpost=on"
fi

#TODO: why the options are different?
if [ "$1" == "pt" ]; then
	IOMMU="$IOMMU,caching-mode=on"
elif [ "$1" == "vp" ]; then
	IOMMU="$IOMMU,device-iotlb=on"
fi
