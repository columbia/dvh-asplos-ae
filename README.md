# Optimizing Nested Virtualization Performance Using Direct Virtual Hardware
Artifacts Evaluation for ASPLOS 2020

## Prerequisites
* Virtual machine image file. (Download here(TODO))
* Two physical machines connected via private network for stable and precise measurements

## Compliation
* (TODO) PV, PT, DVH-VP, DVH configuration
* Command to compile kernel
```
make -j 40 LOCALVERSION=$LV $BZ_IMAGE && $MOD_INSTALL && sudo make install
```
* Command to copy kernel to the host and VMs
```
rsync -av /boot/*$KERNEL_VER root@$TARGET_IP:/boot/.
```
or just run and set local version and choose whether to compile modules or not
```
# build-n-install.sh
LOCALVERSION?[dvh-L0]:
make modules_instsall?[y/N]:
```
