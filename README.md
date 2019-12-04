# Optimizing Nested Virtualization Performance Using Direct Virtual Hardware
This repository is for Artifacts Evaluation for ASPLOS 2020. It has all the source code and instructions to run the key experiments presented in Figure 5 and 6 in the paper.

## Prerequisites
* Two physical machines connected by <em>private</em> network for stable and precise measurements.
  * Cloudlab.us provides machines and preconfigured profiles. Machines will be available upon request for artifact evaluation. See [Instructions for Cloudlab](#instructions-for-cloudlab).

## Overview
The experiments measure various application performance on one machine, the server machine (i.e. bare-metal machine and virtual machines), where the other machine, which is the client machine, sends workloads to the server machine.

We compare application performance on bare-metal to that on different virtualization levels (from 1 to 3) with different configurations (baseline, passthrough, DVH-VP, and DVH).

On both the server and client machines, you need to do the [basic preparation](#basic-preparation) for running various scripts and compiling source code.

For the server, you need to install [a proper kernel version](#branch-information), update [kernel parameters](#kernel-parameter-setup), and use [a proper qemu version](#qemu-branches-for-running-vms) for each experiment configurations.


## Basic preparation
Clone this repository on both machines as a **root** user. Note that all the commands other than this `git clone` command need to be executed in the directory this repo is cloned.
```
# git clone https://github.com/columbia/dvh-asplos-ae.git
# cd dvh-asplos-ae
```

Run this command to copy helper scripts to a local directory in $PATH, which is set to /usr/local/bin in the script.
```
# cd scripts
# ./install_scripts.sh
```

Run this command to install packages used to compile software and run VMs.
```
# ./install_packages.sh
```
## Physical / virtual machine setup
Prepare two physical machines and connect them through a private network. We use the following IP addresses in the experiments. Scripts in this repo uses those IP addresses. If you choose to use other IP addresses, please update scripts, too.
* A physical machine running virtual machines (i.e. server machine): 10.10.1.2
* A physical machine sending workloads to the virtual machines (i.e. client machine): 10.10.1.1

Download the virtual machine in the L0 machine. Then,run the `run-vm.py` script to set up the VM image path, virtualization level and vitualization configuration such as baseline, passthrough, dvh-pv, or dvh. This script will run to the last level virtual machine automatically.
```
# cd scripts
# ./run-vm.py
--------- VM configurations -------
1. [/sdb/v4.18.img] VM Image path
2. [base] VM Configuration
3. [2] Virtualization Level
Enter number to update configuration. Enter 0 to start a VM:
```

Virtual machines are configured to have the following IP addresses already.
* L1: 10.10.1.100
* L2: 10.10.1.101
* L3: 10.10.1.102

For convienient access from physical machines to virtual machines, the ssh public key in the L0 will be copied to virtual machines automatically when starting a VM. The client machine ssh public key, however, needs to be copied to `scripts/client_ssh_public` file first. Then it will be also copied to all virtual machines and L0 automatically when starting a VM.

## Kernel Setup
Download Linux source through git submodule command once.
Run all commands in this Kernel Setup section under `./linux` directory after Linux source is downloaded.
```
# git submodule update --init linux
# cd linux
```

### Branch information

|    | Baseline and passthrough |  DVH-VP  | DVH for L2| DVH for L3 |
| ---|------------| ---                    | ----------------| --------------- |
| L0 | v4.18-base | v4.18-dvh-vp-L0        | v4.18-dvh-L0    | v4.18-dvh-L0    |
| L1 | v4.18-base | v4.18-dvh-vp-guest     | v4.18-dvh-basic | v4.18-dvh-full  |
| L2 | v4.18-base | v4.18-dvh-vp-guest     | v4.18-base      | v4.18-dvh-basic |
| L3 | v4.18-base | v4.18-base             | -               | v4.18-base      |

Pick a branch name from the table above, and run this command to switch to the branch
```
# git checkout <branch-name>
```

### Kernel configuration
```
# make dvh_x86_defconfig
```

### Kernel compile
Run this script to compile and install kernel. Say Y for 'make modules_install' if this is the first time building a branch. The compiled kernel will have a local version of this format by default: 4.18.0-`branch name`, e.g. 4.18.0-base.
```
# build-n-install.sh
LOCALVERSION?[base]:
make modules_instsall?[y/N]:
```

### Kernel install
Copy new kernel files to a running physical/virtual machine. Note that the machine you ran `build-n-install.sh` on already has kernel files in place.
```
# copy-kernel.sh
Target machine IP?
10.10.1.100
```

### Kernel parameter setup

Once you copy kernel, you need to update grub to boot from the copied kernel with proper kernel parameters. This will be done by updating `/etc/default/grub` file.

Change `GRUB_DEFAULT` to point the copied kernel. This is an example of 4.18.0-base kernel.
```
K_VER=4.18.0-base
GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux $K_VER"
```

Depending on I/O virtualization, update the line starting GRUB_CMDLINE_LINUX in `/etc/default/grub` file. By default, it would look like this
```
GRUB_CMDLINE_LINUX="console=ttyS0,115200n8"
```
Append proper options to the line from the table below. Note that no configuration change is required for the last level VM.

* For L0 measurements
  
|    | Baseline        |
|--- |---------------- |
| L0 | maxcpus=4 <br>  |


* For L1 measurements
  
|    | Baseline        | Passthrough         |
|--- |---------------- | --------------------|
| L0 | maxcpus=6 <br>  | maxcpus=6 <br>  intel_iommu=on |


* For L2 measurements
  
|    | Baseline | Passthrough | DVH-VP and DVH|
| ---|----------| ------------| ----------    |
| L0 | maxcpus=8 <br> kvm-intel.nested=1 | maxcpus=8 <br> kvm-intel.nested=1 <br> intel_iommu=on | maxcpus=8 <br> kvm-intel.nested=1 |
| L1 | - | intel_iommu=on |intel_iommu=on |

* For L3 measurements

|    | Baseline | Passthrough | DVH-VP and DVH |
| ---| -------- | ---         | ---            |
| L0 | maxcpus=10 <br> kvm-intel.nested=1 |  maxcpus=10 <br> kvm-intel.nested=1 <br> intel_iommu=on | maxcpus=10 <br> kvm-intel.nested=1 |
| L1 | - | kvm-intel.nested=1 <br> intel_iommu=on | kvm-intel.nested=1 <br> intel_iommu=on |
| L2 | - | intel_iommu=on |intel_iommu=on |

For example, L0 kernel parameter for L3 baseline measurements would look like this.
```
GRUB_CMDLINE_LINUX="console=ttyS0,115200n8 maxcpus=10 kvm-intel.nested=1"
```

Once you updated the `grub` file, do the followings to make the change effective.
```
# update-grub
# reboot
```

Ensure that the kernel version and core numbers are changed correctly with the following commands.
```
# uname -r
# lscpu
```

## QEMU Setup

Download QEMU source through git submodule command once.
```
# git submodule update --init qemu
```

### QEMU branches for running VMs
|       | Baseline, passthrough| DVH-VP         | DVH                      |
| ---   |------------ | ----------------        |---------                 |
| L1 VM | v3.1.0-base | v3.1.0-vp-L0            | v3.1.0-dvh-L0            |
| L2 VM | v3.1.0-base | v3.1.0-dvh-common-guest | v3.1.0-dvh-common-guest  |
| L3 VM | v3.1.0-base | v3.1.0-dvh-common-guest | v3.1.0-dvh-common-guest  |

Pick a branch name from the table above, and run this command to switch to the branch. Note that QEMU is already ready in the virtual machine image provided, so only QEMUs for L1 VM need to be prepared as follows.

```
# cd qemu
# git checkout <branch-name>
```
### Configure and compile
```
./configure --target-list=x86_64-softmmu && make clean && make -j
```

## Client Setup
The client machine should have this repository in the home directory.
```
# git clone https://github.com/columbia/dvh-asplos-ae.git
```

The client machine should have the baseline kernel, which is v4.18-base. Update as described in [Kernel Setup]#Kernel Setup. 

## Run application benchmarks and and collect results
Run this command in the client. It will automatically run all the applications and save results.
```
# cd dvh-asplos-ae
# cd scripts
# ./run-benchmarks.sh [L0|L1|L2|L3]
[0] ==== Start Test =====
[1] All
[2] Hackbench
[3] mysql
[4] netperf-rr
[5] netperf-stream
[6] netperf-maerts
[7] apache
[8] memcached
Type test number(Enter 0 to start tests): 1
Enter test name: L2-dvh
How many times to repeat? 5
```

Once the experiments are done, run this command to collect results. It will show the results in csv format.
```
# ./results.py [test name]
netperf-rr
----------netperf-rr----
20081.91,19990.36
20089.42,20135.43
19987.31,19985.2
20029.22,20158.78
------------------------

netperf-stream
----------netperf-stream--
9413.8,9413.92
9411.59,9413.5
9414.17,9414.33
9414.13,9414.27
------------------------
```

## Instructions for Cloudlab
* Please sign up in cloud.us: https://www.cloudlab.us/signup.php to be able to access machines. Join the existing project: KVM/ARM, and I will receive a notification automatically and I will let you in.
* Use `x86-u16-two` profile for experiments. To get enough storage for the VM image, do the following in the server node. **Note that you need more than 45G storage**, and the sda4 partition will suffice.
```
# mkfs.ext4 /dev/sda4
# mkdir /vm
# mount /dev/sda4 /vm
```

* Copy the VM image to the directory
```
# cd /vm
# cp /proj/kvmarm-PG0/jintack/nested/ae-guest0.img.bz2 .
# pbzip2 -dk ae-guest0.img.bz2
```

* Use `tdataset` profile for compiling code, especially Linux kernel. To get enough storage for compiling kernel, do the following.
```
# cd /tmp/env/scripts 
# ./mkfs-wisc-sdc.sh
# cd /sdc
```

## TODOs
* Do memory consumption in L0 somewhere in the workflow.
* Troubleshoot when run-vm.py script got an error
* Troubleshoot when apt-get isn't working as expected (uncomment src source).
