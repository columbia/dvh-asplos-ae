# Optimizing Nested Virtualization Performance Using Direct Virtual Hardware
This repository is for Artifacts Evaluation for ASPLOS 2020. It has all the source code and instructions to run the key experiments presented in Figures 5 and 6 and Table 4 in the paper.

## Prerequisites
* Two physical machines connected by <em>private</em> network for stable and precise measurements.
  * Cloudlab.us provides machines and preconfigured profiles. Machines will be available upon request for artifact evaluation. See [Instructions for Cloudlab](#instructions-for-cloudlab).

## Overview
The experiments measure various application performance on one machine, the server machine (i.e. bare-metal machine and virtual machines), while the other machine, which is the client machine, sends workloads to the server machine.

We compare application performance on bare-metal to that on virtual machines at different virtualization levels (from 1 to 3) with different configurations (baseline, passthrough, DVH-VP, and DVH).

On both the server and client machines, you need to do the [basic preparation](#basic-preparation) for running various scripts and compiling source code.

On the server, you need to install [a proper kernel version](#branch-information), update [kernel parameters](#kernel-parameter-setup), and use [a proper QEMU version](#qemu-branches-for-running-vms) for each experiment configurations in all virtualization levels. Once it's ready, you can start [running a virtual machine](#running-a-virtual-machine). Note that in a provided virtual machine image, kernel and QEMU binaries are already available. You still need to update [kernel parameters](#kernel-parameter-setup) accordingly.

On the client, you need to install [baseline kernel](#branch-information) without further updating kernel parameters and QEMU. Once the server is running a virtual machine (or none for bare-metal measurements), [run application benchmarks and collect results](#run-application-benchmarks-and-collect-results). The script to run the application benchmarks will automatically install the benchmarks on both the server (including virtual machines) and the client if they are not yet installed.

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

Run this command to install packages used to compile software and run VMs. See [troubleshooting](#troubleshooting) for any problems.
```
# ./install_packages.sh
```

Lastly, copy the client machine ssh public key to `scripts/client_ssh_public` file **on the server machine**. This enables the client machine to access any level of virtual machines, which is required for running application benchmarks. The copied client machine ssh public key as well as that of the server machine are copied to virtual machines at each level on the first virtual machine run automatically.

From the client,
```
# cat ~/.ssh/id_rsa.pub
ssh-rsa AABB...
```
From the server,
```
# cd scripts
# echo 'ssh-rsa AABB...' > client_ssh_public
```

## Physical/virtual machine setup
Prepare two physical machines and connect them through a private network. We use the following IP addresses in the experiments. Scripts in this repo use those IP addresses. If you choose to use other IP addresses, please update scripts, too.
* A physical machine running virtual machines (i.e. server machine): 10.10.1.2
* A physical machine sending workloads to the virtual machines (i.e. client machine): 10.10.1.1

In addition, configure virtual machines at each level use the following IP addresses on the server machine. If you are a cloudlab user, download a preconfigured VM image [here](#cloudlab-profiles)
* L1: 10.10.1.100
* L2: 10.10.1.101
* L3: 10.10.1.102

Once the physical machines and virtual machines are ready, follow those steps to run experiments.
1. Prepare [Linux kernel](#kernel-setup) and [QEMU](#qemu-setup), and install them at each virtualization level and bare-metal machines. Do this only once for the client machine. See [software configuration tables](#software-configurations) to get the correct version to install.
2. [Run a virtual machine](#running-a-virtual-machine) on the server machine or [get the server ready](#running-a-physical machine) for bare-metal measurements
3. [Run application benchmarks and collect results](#run-application-benchmarks-and-collect-results) on the client machine
4. Repeat 1 to 3 for all configurations in [here](#software-configurations)

## Kernel Setup
Kernel setup involves compiling and installing kernel, updating kernel parameter, and **rebooting** the machine.

Download Linux source through git submodule command once. See [here](#cloudlab-profiles) to select a machine for kernel compile for Cloudlab users.

Run all commands in this Kernel Setup section under `./linux` directory after Linux source is downloaded.
```
# git submodule update --init linux
# cd linux
```

Pick a branch name from the [software configuration tables](#software-configurations), and run this command to switch to the branch.
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

Once you copy kernel, you need to update grub to boot from the copied kernel with proper kernel parameters. This will be done by updating `/etc/default/grub` file. See additionl instructions for Cloudlab users [here](#kernel-parameter-in-cloudlab).

Change `GRUB_DEFAULT` to point the copied kernel. This is an example of 4.18.0-base kernel.
```
K_VER=4.18.0-base
GRUB_DEFAULT="Advanced options for Ubuntu>Ubuntu, with Linux $K_VER"
```

You also need to update the line starting `GRUB_CMDLINE_LINUX` in `/etc/default/grub` file. By default, it would look like this
```
GRUB_CMDLINE_LINUX="console=ttyS0,115200n8"
```
Append proper options to the line from the [software configuration tables](#software-configurations). For example, L0 kernel parameter for L3 baseline measurements would look like this.
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

Pick a branch name from the [software configuration tables](#software-configurations), and run these commands to switch to the branch and to compile. 

```
# cd qemu
# git checkout <branch-name>
./configure --target-list=x86_64-softmmu && make clean && make -j
```


## Client Setup
The client machine should have this repository in the home directory.
```
# git clone https://github.com/columbia/dvh-asplos-ae.git
```

The client machine should have the baseline kernel, which is v4.18-base. Update as described in [Kernel Setup](#kernel-setup). 

## Running a physical machine
For L0 measurements, we don't run any virtual machines. Run this script instead to limit the memory size as discussed in the paper. For virtual machine tests, the script is already included in `run-vm.py`.

```
# cd scripts
# ./consume_mem.sh 12
```

## Running a virtual machine

On the server machine, run the `run-vm.py` script to set up the VM image path, virtualization level and vitualization configuration such as baseline, passthrough, dvh-pv, or dvh. This script will run to the last level virtual machine automatically. Wait until you see `Ready to run experiments!` message. See [troubleshooting](#troubleshooting) for any problems.
```
# cd scripts
# ./run-vm.py
--------- VM configurations -------
1. [/sdb/v4.18.img] VM Image path
2. [base] VM Configuration
3. [2] Virtualization Level
Enter number to update configuration. Enter 0 to start a VM:
...
<virtual machine boot log>
...
Ready to run experiments!
```

## Running application benchmarks and collect results
Run this command in the client. It will automatically install and run all the applications for the performance evaluation on the server and the client machines. The result will be saved in the client machine under the directory you entered by "Enter test name:" prompt.
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
How many times to repeat? 3
```

Once the experiments are done, run this command to collect results. It will show the results in csv format. Each column is one run (typically consists of 50 iterations). For example, the following results show there are two runs of netperf rr and netperf stream where each run consists of four iterations for a demo purpose.
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

Once the data is collected, get the average of each run and pick the best average number of all runs for each application benchmark. That's how we get application performance. [This template](https://docs.google.com/spreadsheets/d/1LwybiiGdiOgiuagrn9A3zcAKfsIzDAv9VSb0myU-3d8/edit?usp=sharing) would help to collect data.

[Here are the results](https://docs.google.com/spreadsheets/d/1kJHflbqUu7mUiWMyHituv0whZJQagVIOqvtiBbd93kM/edit?usp=sharing) we have used for the paper.

## Instructions for Cloudlab

### Joining Cloudlab
Please sign up in cloud.us: https://www.cloudlab.us/signup.php to be able to access machines. Join the existing project: KVMARM, and I will receive a notification automatically and I will let you in.

### Cloudlab profiles
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
### Kernel parameter in Cloudlab
`/etc/default/grub` file in Cloudlab machine has duplicated entries such as GRUB_CMDLINE_LINUX. **Please delete the last three lines of the file.** You just need to do it only once per physical machine. It looks like the followings.

```
# The remaining lines were added by Emulab slicefix
# DO NOT ADD ANYTHING AFTER THIS POINT AS IT WILL GET REMOVED.
GRUB_CMDLINE_LINUX="console=ttyS0,115200"
GRUB_TERMINAL=serial
GRUB_SERIAL_COMMAND="serial --unit=0 --port=0x3F8 --speed=115200"
```

## Troubleshooting

* If `run-vm.py` script went wrong and if you can't type any command, enter ctrl+C. When the script went wrong, you are still in the execution of the script. Ctrl+C will take you back to the shell.

## Software configurations

### Client machine
|     |  Kernel branch                | Kernel param                      | QEMU branch|
| --- | ---        | ---                               | ---  |
| L0  | v4.18-base | -                         | -  |


### L0 experiments
* Baseline

|     |  Kernel branch                | Kernel param                      | QEMU branch|
| --- | ---        | ---                               | ---  |
| L0  | v4.18-base | maxcpus=4                         | -  |

### L1 experiments
* Baseline

|     |  Kernel branch                | Kernel param                      | QEMU branch|
| --- | ---        | ---                               | ---  |
| L0  | v4.18-base | maxcpus=6                         | v3.1.0-base |
| L1  | v4.18-base | -                                 | - |

* Passthrough

|     |  Kernel branch                | Kernel param                      | QEMU branch|
| --- | ---        | ---                               | ---  |
| L0  | v4.18-base | maxcpus=6 <br> intel_iommu=on     | v3.1.0-base |
| L1  | v4.18-base | -                                 | - |


### L2 experiments
* Baseline

|     |  Kernel branch                | Kernel param                      | QEMU branch|
| --- | ---        | ---                               | ---  |
| L0  | v4.18-base | maxcpus=8 <br> kvm-intel.nested=1 | v3.1.0-base |
| L1  | v4.18-base | -                                 | v3.1.0-base |
| L2  | v4.18-base | -                                 | - |

* Passthrough

|     |  Kernel branch                | Kernel param                      | QEMU branch|
| --- | ---        | ---                               | ---  |
| L0  | v4.18-base | maxcpus=8 <br> kvm-intel.nested=1 <br> intel_iommu=on | v3.1.0-base |
| L1  | v4.18-base | intel_iommu=on                    | v3.1.0-base |
| L2  | v4.18-base | -                                 | - |

* DVH-VP

|     |  Kernel branch                | Kernel param                      | QEMU branch|
| --- | ---        | ---                               | ---  |
| L0  | v4.18-base | maxcpus=8 <br> kvm-intel.nested=1 <br> | v3.1.0-base |
| L1  | v4.18-base | intel_iommu=on                    | v3.1.0-base |
| L2  | v4.18-base | -                                 | - |

* DVH

|     |  Kernel branch                | Kernel param                      | QEMU branch|
| --- | ---                    | ---                               | ---  |
| L0  | v4.18-dvh-L0-asplos    | maxcpus=8 <br> kvm-intel.nested=1 <br> | v3.1.0-dvh |
| L1  | v4.18-dvh-basic-asplos | intel_iommu=on                    | v3.1.0-base |
| L2  | v4.18-base | -                                             | - |

### L3 experiments

* Baseline

|     |  Kernel branch                | Kernel param                      | QEMU branch|
| --- | ---        | ---                               | ---  |
| L0  | v4.18-base | maxcpus=10 <br> kvm-intel.nested=1 | v3.1.0-base |
| L1  | v4.18-base | kvm-intel.nested=1                 | v3.1.0-base |
| L2  | v4.18-base | -                                 | v3.1.0-base |
| L3  | v4.18-base | -                                 | - |

* Passthrough

|     |  Kernel branch                | Kernel param                      | QEMU branch|
| --- | ---        | ---                               | ---  |
| L0  | v4.18-base | maxcpus=10 <br> kvm-intel.nested=1 <br> intel_iommu=on | v3.1.0-base |
| L1  | v4.18-base | intel_iommu=on <br> kvm-intel.nested=1 | v3.1.0-base |
| L2  | v4.18-base | intel_iommu=on                    | v3.1.0-base |
| L3  | v4.18-base | -                                 | - |

* DVH-VP

|     |  Kernel branch                | Kernel param                      | QEMU branch|
| --- | ---        | ---                               | ---  |
| L0  | v4.18-base | maxcpus=10 <br> kvm-intel.nested=1 <br> | v3.1.0-base |
| L1  | v4.18-base | intel_iommu=on <br> kvm-intel.nested=1 | v3.1.0-base |
| L1  | v4.18-base | intel_iommu=on                    | v3.1.0-base |
| L2  | v4.18-base | -                                 | - |

* DVH

|     |  Kernel branch                | Kernel param                      | QEMU branch|
| --- | ---                    | ---                               | ---  |
| L0  | v4.18-dvh-L0-asplos    | maxcpus=10 <br> kvm-intel.nested=1 <br> | v3.1.0-dvh |
| L1  | v4.18-dvh-full-asplos | intel_iommu=on <br> kvm-intel.nested=1  | v3.1.0-dvh |
| L1  | v4.18-dvh-basic-asplos | intel_iommu=on                    | v3.1.0-base |
| L2  | v4.18-base | -                                             | - |
