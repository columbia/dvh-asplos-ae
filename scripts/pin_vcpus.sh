#!/bin/bash

# Assign all interrupts and processes on the sytem to low-numbered CPUs and
# assign the VCPU thread to high-numbered CPUs.

# Relies on starting QEMU with a qmp socket in /var/run/qmp, like this:
#   qemu-system-aarch64 -qmp unix:/var/run/qmp,server,nowait

# Get number of cores
NCORES=`getconf _NPROCESSORS_ONLN`

# Get number of virtual cores
VCORES=`./qmp-cpus -s /var/run/qmp | wc -l`

if [[ "$NCORES" -lt "$VCORES" ]]; then
    echo "Unsupported configuration, more virtual CPUs ($VCORES) than physical ($NCORES)" >&2
    exit 1
fi

echo "Pinning $VCORES QEMU VCPU threads:"
for i in `seq 0 $((VCORES - 1))`; do
    MASK=`printf '%x' $(( (0x1 << $i) << ($NCORES - $VCORES) ))`
    PID=`./qmp-cpus -s /var/run/qmp | awk '{ print $3 }' | head -n $((i + 1)) | tail -n 1`
    echo "vCPU$i (pid $PID): 0x$MASK"
    taskset -p 0x$MASK $PID > /dev/null
    if [[ $? != 0 ]]; then
        echo "taskset returned an error $?" >&2
        exit 1
    fi
done
echo "Done"
