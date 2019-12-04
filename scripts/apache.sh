#!/bin/bash

SRV=$1
REPTS=${2-40}

echo "Measuring performance of $SRV"

# requires that apache is installed with the gcc manual in place
NR_REQUESTS=100000
RESULTS=apache.txt
ab=/usr/bin/ab
CMD="$ab -t 10 -n $NR_REQUESTS -c 10 http://$SRV/gcc/index.html"

source exits.sh apache

for i in `seq 1 $REPTS`; do
	start_measurement

	$CMD | tee >(grep 'Requests per second' | awk '{ print $4 }' >> $RESULTS)

	end_measurement
	save_stat
done
