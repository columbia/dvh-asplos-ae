# Optimizing Nested Virtualization Performance Using Direct Virtual Hardware
Artifacts Evaluation for ASPLOS 2020

## Prerequisites
* Virtual machine image file. (Download here(TODO))
* Two physical machines connected via private network for stable and precise measurements

## Preparation
Run this command to copy helper scripts to a local directory in $PATH, which is set to /usr/local/bin in the script.
```
# cd scripts
# ./install_scripts.sh
```

## Compliation
### Kernel configuration
```
# make dvh_x86_defconfig
```

### Kernel compile
```
# LV=<put-your-local-version-as-you-like>
# make -j LOCALVERSION=$LV && make modules_install && make install
```
or just run the script below in the kernel source directory
```
# build-n-install.sh
LOCALVERSION?[dvh-L0]:
make modules_instsall?[y/N]:
```

* Command to compile QEMU

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
(TODO) move run_all.sh from kvmperf/cmdline_tests
```
# ./run_all.sh
(TODO) Display options
```

## Collect Results
This script prints out the experimental results.
```
# ./results.py
```



