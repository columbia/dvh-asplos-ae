#!/usr/bin/python

import vm_api_ae
import time

vm_api_ae.init(False)
#vm_api_ae.check_vms()
vm_api_ae.boot_vms()
child = vm_api_ae.get_child()
child.interact()
