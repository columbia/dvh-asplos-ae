NETDEV_IOMMU_OPTION="iommu_platform=on,disable-modern=off,disable-legacy=on,ats=on"

IOH2="-device ioh3420,id=pcie.1,chassis=2"
IOMMU_VIRTIO_NETDEV2="-netdev tap,id=net2,vhostforce"
IOMMU_VIRTIO_NETDEV2="$IOMMU_VIRTIO_NETDEV2 -device virtio-net-pci,netdev=net2,bus=pcie.1,$NETDEV_IOMMU_OPTION"

find_available_mac 3
IOMMU_VIRTIO_NETDEV2="$IOMMU_VIRTIO_NETDEV2,mac=$MAC"

