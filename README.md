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
or just run and set local version and choose whether to compile modules or not
```
# build-n-install.sh
LOCALVERSION?[dvh-L0]:
make modules_instsall?[y/N]:
```

## Install Kernel
* Command to copy kernel to the host and VMs
```
rsync -av /boot/*$KERNEL_VER root@$TARGET_IP:/boot/.
```
or just run
```
# copy-kernel.sh
Target machine IP?
```

## Update Kernel
* Set kernel parameters
  * For PV, PT, DVH-VP, and DVH
    * For L0 to L3
  
* Reboot

## Server Setup
### QEMU Install (TODO)
### Run Virtual machines
TODO: Update env/vm_api_example.py. Remove Small mem option. Maybe have one option for DVH
Select options
```
# ./vm_api_example.py
1. [True] SMP
2. [False] SmallMemory
3. [2] Virtualization Level
4. [pv] I/O virtualization model (pv, pt, or vp)
6. [n] Virtual timer
7. [n] Virtual ipi
8. [n] Virtual idle
9. [n] FS_BASE fix
10. [False] Migration
Enter number to update configuration. Enter 0 to finish:
```

## Client Setup
(TODO) Make this repo only have scripts
(TODO) Make another repo for Linux, QEMU and add them as submodules
(TODO) Update only necessary submodules since Linux is a large code base, something like this
```
git submodule update --init submoduleName
```

## Run Experiments
