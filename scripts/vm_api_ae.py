#!/usr/bin/python

import pexpect
import sys
import os
import datetime
import time
import socket
import argparse
import os.path
import pickle

QEMU_options = {'virtual_timer': 'vtimer', 'virtual_ipi': 'vipi', 'virtual_idle': 'vidle', 'fs_base': 'seg'}
class Params:
	def __init__(self):
		self.level = 2
                self.vm_image = None
		self.iovirt = 'pv'
                self.vm_config = 'base' # base, passthrough, DVH-VP, DVH
		self.posted = False
		self.mi = False
		self.mi_level = 0
		self.mi_role = None
		self.mi_fast = False
                self.micro = False
                self.dvh =  {
                            'virtual_ipi': 'n',
                            'virtual_timer': 'n',
                            'virtual_idle': 'n',
                            'fs_base': 'n',
                            }
		self.dvh_use = False
	
mi_src = " -s"
mi_dest = " -t"
LOCAL_SOCKET = 8890
l1_addr='10.10.1.100'
PIN = ' -w'
pin_waiting='waiting for connection.*server'
hostname = os.popen('hostname | cut -d . -f1').read().strip()
hostnames = []
hostnames.append(hostname)
hostnames += ['L1', 'L2', 'L3']
params=None
g_child=None

###############################
#### set default here #########
mi_default = "l2"
io_default = "vp"
###############################
def wait_for_prompt(child, hostname):
    child.expect('%s.*].*#' % hostname)

def wait_for_vm_prompt(child):
    child.expect('L.*].*#')

def pin_vcpus(level):

        if level == 1:
	    os.system('cd /usr/local/bin/ && sudo ./pin_vcpus.sh && cd -')
	if level == 2:
		os.system('ssh root@%s "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"' % l1_addr)
	if level == 3:
		os.system('ssh root@10.10.1.101 "cd vm/qemu/scripts/qmp/ && ./pin_vcpus.sh"')
	print ("vcpu is pinned")

cmd_pv = './run-guest.sh'
cmd_vfio = './run-guest-vfio.sh'
cmd_viommu = './run-guest-viommu.sh'
cmd_vfio_viommu = './run-guest-vfio-viommu.sh'
qemu_dvh_common_guest = ' -u ../qemu-dvh-common-guest'

def handle_mi_options(vm_level, lx_cmd):
        if vm_level == params.mi_level:
		# BTW, this is the only place to use mi_role
		if params.mi_role == "src":
			lx_cmd += mi_src
                if params.mi_role == "dest":
			lx_cmd += mi_dest

	return lx_cmd

def handle_pi_options(vm_level, lx_cmd):
	# We could support pt as well.
	if vm_level == 1 and params.iovirt == 'vp' and params.posted:
		lx_cmd += " --pi"

	return lx_cmd

def add_dvh_options(vm_level, lx_cmd):
    # WIP: we are supporting QEMU DVH support for L1 for now
    if vm_level != 1:
        return lx_cmd

    dvh_options = ""

    for f in params.dvh:
	# We never set virtual idle for L1
	if vm_level == 1 and f == 'virtual_idle':
		continue;
        if params.dvh[f] == 'y':
            if dvh_options:
                dvh_options += ","
            dvh_options += QEMU_options[f]+'=on'
            dvh_enabled = True

    if dvh_options:
        dvh_options = " -p \"-dvh " + dvh_options + "\""

    lx_cmd += dvh_options

    return lx_cmd

def add_special_options(vm_level, lx_cmd):
	lx_cmd = handle_pi_options(vm_level, lx_cmd)
        if params.mi:
	    lx_cmd = handle_mi_options(vm_level, lx_cmd)

        lx_cmd += PIN

	return lx_cmd

def get_base_cmd(vm_level):
	if vm_level == 1:
		lx_cmd = ''
	else:
		lx_cmd = 'cd ~/dvh-asplos-ae/scripts && '

	return lx_cmd

def add_qemu_path(vm_level, lx_cmd):
	if vm_level != 1 and params.iovirt == "vp":
		lx_cmd += qemu_dvh_common_guest
	return lx_cmd

def get_iovirt_cmd(vm_level, lx_cmd):
	iovirt = params.iovirt

	if vm_level == 1 and iovirt == "vp":
		lx_cmd += cmd_viommu
	elif iovirt == "vp" or iovirt == "pt":
		if vm_level == params.level:
			lx_cmd += cmd_vfio
		else:
			lx_cmd += cmd_vfio_viommu
	else:
		lx_cmd += cmd_pv

	return lx_cmd

def add_vm_image_path(vm_level, lx_cmd):
    if vm_level == 1:
        return lx_cmd + ' -i ' + params.vm_image
    return lx_cmd

def configure_dvh(vm_level):
    child = g_child

    # We configure DVH using QEMU cmd line in L0
    if vm_level == 1:
        return

    for f in params.dvh:
        dvh_filename='/sys/kernel/debug/dvh/' + f
        if not os.path.exists(dvh_filename):
            continue
        cmd = 'echo %s > %s' % (params.dvh[f], dvh_filename)
        child.sendline(cmd)
        # Wait for host prompt
        wait_for_prompt(child, hostnames[vm_level - 1])

def boot_vms(bootLevel=0):
    level = params.level
    mi_level = params.mi_level
    child = g_child

    vm_level = 0

    mem = 3
    while (vm_level < level):
        vm_level += 1

        if params.micro and vm_level == level:
            return

        lx_cmd = get_base_cmd(vm_level)
        lx_cmd = get_iovirt_cmd(vm_level, lx_cmd)
        lx_cmd = add_special_options(vm_level, lx_cmd)
        lx_cmd = add_dvh_options(vm_level, lx_cmd)
        lx_cmd = add_vm_image_path(vm_level, lx_cmd)
        lx_cmd = add_qemu_path(vm_level, lx_cmd)
        print (lx_cmd)

        configure_dvh(vm_level)

        child.sendline(lx_cmd)
        child.expect(pin_waiting)
        pin_vcpus(vm_level)

        if mi_level == vm_level and params.mi and params.mi_role == 'dest' :
            child.expect('\(qemu\)')
            break
        else:
            child.expect('L' + str(vm_level) + '.*$')

        if bootLevel == vm_level:
            return

REMOVE = 0
ADD = 1
def change_grub(option, add):
    child = g_child
    cmd = '/root/env/scripts/grub-change.sh ' + option + ' ' + str(add)
    child.sendline(cmd)
    wait_for_vm_prompt(child)

def check_vms():
    child = g_child
    bootLevel = params.level - 1
    if bootLevel == 0:
        return

    boot_vms(bootLevel)

    # If this is VP, the a hypervisor needs have iommu
    if params.iovirt in ['vp', 'pt']:
        change_grub('intel_iommu=on', ADD)
    else:
        change_grub('intel_iommu=on', REMOVE)

    terminate_vms(None, None, bootLevel)

def halt(level):
    child = g_child

    if level > 2:
        child.sendline('halt -p')
        child.expect('L2.*$')

    if level > 1:
        child.sendline('halt -p')
        child.expect('L1.*$')

    child.sendline('halt -p')
    wait_for_prompt(child, hostname)

#depricated for now
def reboot(params):
	halt(params.level)
	boot_nvm(params)

def terminate_vms(qemu_monitor, child = None, bootLevel=None):
	global g_child
	print ("Terminate VM.")

	if not child:
		child = g_child
        if not bootLevel:
                bootLevel = params.level

	if qemu_monitor:
		if params.level == 2 and params.mi_level == 2:
			child.sendline('stop')
			child.expect('\(qemu\)')
			child.sendline('q')
			child.expect('L1.*$')
			child.sendline('h')
			wait_for_prompt(child, hostname)

		if params.mi_level == 1:
			child.sendline('stop')
			child.expect('\(qemu\)')
			child.sendline('q')
			wait_for_prompt(child, hostname)

	else:
            for i in reversed(range(bootLevel)):
                child.sendline('halt -p')
                wait_for_prompt(child, hostnames[i])
	
def str_to_bool(s):
	if s == 'True':
		return True
	elif s == 'False':
		return False
	else:
		print (s)
		raise ValueError

EXP_PARAMS_PKL="/root/.exp_params.pkl"

def get_boolean_input(statement):

    while True:
        try:
            return {'y':True, 'n':False, '':False}[raw_input(statement).lower()]
        except KeyError:
            print "Invalid input please enter y, Y, n, or N"

def get_str_input(statement, str_set):

    while True:
        input_str = raw_input(statement).lower()
        if input_str in str_set:
            return input_str
        print "Invalid input. Please enter one of " + str(str_set) + '.'

def get_yn_input(statement):

    while True:
        try:
            return {'y':'y', 'n':'n'}[raw_input(statement).lower()]
        except KeyError:
            print "Invalid input please enter y, Y, n, or N"

def get_int_input(statement):

    while True:
        try:
            return int(raw_input(statement))
        except ValueError:
            print "Invalid input. Please enter integer"

def save_params(new_params):
    with open(EXP_PARAMS_PKL, 'wb+') as output:
        pickle.dump(new_params, output)

VM_IMAGE = 1
VM_CONFIG = 2
LEVEL = 3
MICRO = 4
MIGRAION = 10
MI_LEVEL = 11
MI_SPEED = 12

def print_params():
    print('--------- VM configurations -------')
    print("%d. [%s] VM Image path" % (VM_IMAGE, params.vm_image))

    print("%d. [%s] VM Configuration" % (VM_CONFIG, params.vm_config))

    print("%d. [%s] Virtualization Level" % (LEVEL, params.level))

    print("%d. [%s] Run for microbenchmarks?" % (MICRO, str(params.micro)))


    #print("%d. [%s] Migration" % (MIGRAION, str(params.mi)))
    #if params.mi:
    #    print("%d. [%s] Migration level" % (MI_LEVEL, str(params.mi_level)))
    #    if hostname == "kvm-node":
    #        print("%d. [%s] Fast migration" % (MI_SPEED, str(params.mi_fast)))

def update_params():
    global params

    num = int(raw_input("Enter number to update configuration. Enter 0 to start a VM: ") or "0")

    if num == 0:
        if not params.vm_image:
            print ('\nWarning: Please set a path of a VM image\n')
            return True
        return False

    if num == VM_IMAGE:
        params.vm_image = raw_input('Path to the VM image: ')

    if num == VM_CONFIG:
        params.vm_config = get_str_input('base, passthrough, dvh-vp, or dvh: ',
                                        ['base', 'passthrough', 'dvh-vp', 'dvh'])

        if params.vm_config == 'base':
            params.iovirt = 'pv'
        elif params.vm_config == 'passthrough':
            params.iovirt = 'pt'
        elif params.vm_config == 'dvh-vp':
            params.iovirt = 'vp'
        elif params.vm_config == 'dvh':
            params.iovirt = 'vp'
            params.posted = True
            for f in params.dvh:
                params.dvh[f] = 'y'

    if num == LEVEL:
        params.level = get_int_input("Input 1, 2, or 3: ")

    if num == MICRO:
        params.micro = get_boolean_input("y/n: ")

    if num == MIGRAION:
        params.mi = get_boolean_input("y/n: ")
        if params.mi:
            params.mi_level = get_int_input("Migration level: Input 1, 2, or 3: ")

            if hostname == "kvm-node":
                params.mi_fast = get_boolean_input("Fast migration speed [y/N]?: ")

            if hostname == "kvm-dest":
                params.mi_role = 'dest'
            else:
                params.mi_role = 'src'

    if num == MI_LEVEL:
        params.mi_level = get_int_input("Input 1, 2, or 3: ")

    if num == MI_SPEED:
        if hostname == "kvm-node":
            params.mi_fast = get_boolean_input("Fast migration speed [y/N]?: ")

    return True 

def set_params(reuse_force):
    global params

    exist = os.path.exists(EXP_PARAMS_PKL)
    reuse_param = 'y'
    if exist:
        with open(EXP_PARAMS_PKL, 'rb') as input:
            params = pickle.load(input)

    if (not exist) or (not reuse_force):

        if not params:
            params = Params()

        update = True
        while update:
            print_params()
            update = update_params()
            new_params = Params()

        save_params(params)


def set_l1_addr():
	global l1_addr
	if hostname == "kvm-dest":
		l1_addr = "10.10.1.110"
	
def create_child():
	global g_child

	child = pexpect.spawn('bash')
	child.timeout=None

	child.sendline('')
	wait_for_prompt(child, hostname)

	child.logfile_read=sys.stdout
	g_child = child
	return child

def get_child():
	global g_child
	return g_child

def get_mi_level():
	return params.mi_level

def get_mi_fast():
	return params.mi_fast

def init(reuse_param):

	set_params(reuse_param)
	set_l1_addr()

	child = create_child()

	return child
