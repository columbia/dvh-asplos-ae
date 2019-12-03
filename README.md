# Optimizing Nested Virtualization Performance Using Direct Virtual Hardware
This repository is for Artifacts Evaluation for ASPLOS 2020. It has all the source code and instructions to run experiments presented in the paper

## Prerequisites
* Two physical machines connected by <em>private</em> network for stable and precise measurements.
* A virtual machine image file available in the archive having (TBD as the last step of the submission) DOI number.

## Basic preparation
Clone this repository. Note that all the commands other than this git clone command need to be executed in the directory this repo is cloned.
```
# git clone https://github.com/columbia/dvh-asplos-ae.git
```

Run this command to copy helper scripts to a local directory in $PATH, which is set to /usr/local/bin in the script.
```
# cd scripts
# ./install_scripts.sh
```

Run this command to install packages to compile software and to run VMs.
```
# ./install_packages.sh
```
## Physical / virtual machine setup
Prepare two physical machines and connect them through a private network. We use the following IP addresses in the experiments.
* A physical machine running virtual machines (i.e. L0): 10.10.1.2
* A physical machine sending workloads to the virtual machines (i.e. client machine): 10.10.1.1

Run the `run-vm.py` script and set up the VM image path, virtualization level and vitualization configuration such as baseline, passthrough, dvh-pv, or dvh. This script will run to the last level virtual machine automatically.
```
# cd scripts
# ./run-vm.py
--------- VM configurations -------
1. [/sdb/v4.18.img] VM Image path
2. [base] VM Configuration
3. [2] Virtualization Level
Enter number to update configuration. Enter 0 to finish:
```

Virtual machines are configured to use the following IP addresses already.
* L1: 10.10.1.100
* L2: 10.10.1.101
* L3: 10.10.1.102

For convienient access from physical machines to virtual machines, the ssh public key in the L0 will be copied to virtual machines automatically in the first run. (TODO: do the same for the client ssh key.)

## Kernel Setup
Download Linux source through git submodule command once.
Run all commands in this Kernel Setup section under `./linux` directory after Linux source is downloaded.
```
# git submodule update --init linux
# cd linux
```

### Branch information

| Virtualization Level       | Baseline, passthrough, and  DVH-VP  | DVH for L2| DVH for L3 |
| -------------              |------------| ----------------| --------------- |
| L0                         | v4.18-base | v4.18-DVH-L0    | v4.18-DVH-L0    |
| L1                         | v4.18-base | v4.18-DVH-basic | v4.18-DVH-full  |
| L2                         | v4.18-base | v4.18-base      | v4.18-DVH-basic |
| L3                         | v4.18-base | -               | v4.18-base      |

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

For example, L0 kernel parameter for L3 measurements would look like this.
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
This needs to be done on bare-metal machine and virtual machines.

### QEMU branches (TBD for L1~L3)
| Virtualization Level       | Baseline, passthrough  | DVH-VP | DVH for L2| DVH for L3 |
| -------------              |------------ | ----------------| --------------- |
| L0                         | v3.1.0-base | TBD | v3.1.0-dvh-L0    | v3.1.0-dvh-L0    |
| L1                         | v3.1.0-base | TBD | v3.1.0-dvh-L0    | v3.1.0-dvh-L0    |
| L2                         | v3.1.0-base | TBD | v3.1.0-dvh-L0    | v3.1.0-dvh-L0    |

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

# From here, to be done.

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
