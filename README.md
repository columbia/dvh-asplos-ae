# Optimizing Nested Virtualization Performance Using Direct Virtual Hardware
Artifacts Evaluation for ASPLOS 2020

(TODO) Table of contents.

## Prerequisites
* Virtual machine image file. (Download here(TODO))
* Two physical machines connected via private network for stable and precise measurements (Update for migration as well)

## Basic preparation
Run this command to copy helper scripts to a local directory in $PATH, which is set to /usr/local/bin in the script.
```
# cd scripts
# ./install_scripts.sh
```

## Kernel Setup
### Branch information

| Virtualization Level       | Baseline, passthrough, and  DVH-VP  | DVH for L2| DVH for L3 |
| -------------              |------------| ----------------| --------------- |
| L0                         | v4.18-base | v4.18-DVH-L0    | v4.18-DVH-L0    |
| L1                         | v4.18-base | v4.18-DVH-basic | v4.18-DVH-full  |
| L2                         | v4.18-base | v4.18-base      | v4.18-DVH-basic |
| L3                         | v4.18-base | -               | v4.18-base      |

Download Linux source through git submodule command once.
```
# git submodule update --init linux
```

Pick a branch name from the table above, and run this command to switch to the branch
```
# cd linux
# git checkout <branch-name>
```

### Kernel configuration
```
# make dvh_x86_defconfig
```

### Kernel compile
Run this script to compile and install kernel.
```
# build-n-install.sh
LOCALVERSION?[base]:
make modules_instsall?[y/N]:
```



### Kernel install

```
# copy-kernel.sh
Target machine IP?
128.105.144.129
success
Kernel version[4.18.0]:
```

### Update Kernel
* Set kernel parameters
  * For PV, PT, DVH-VP, and DVH
    * For L0 to L3
  
* Reboot

## QEMU Setup
### QEMU branches (TBD for L1~L3)
| Virtualization Level       | Baseline, passthrough, and  DVH-VP  | DVH for L2| DVH for L3 |
| -------------              |------------ | ----------------| --------------- |
| L0                         | v3.1.0-base | v3.1.0-dvh-L0    | v3.1.0-dvh-L0    |

Download QEMU source through git submodule command once.
```
# git submodule update --init qemu
```
Pick a branch name from the table above, and run this command to switch to the branch
```
# cd qemu
# git checkout <branch-name>
```
### Configure and compile
```
./configure --target-list=x86_64-softmmu && make clean && make -j
```

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



