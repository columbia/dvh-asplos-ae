#!/bin/bash

SERVER=${1-127.0.0.1}
REPTS=${2-40}
RESULTS=memcached.txt

source exits.sh memcached

echo "Benchmarking $SERVER" | tee >(cat >> $RESULTS)
for i in `seq 1 $REPTS`; do
	start_measurement

	memtier_benchmark --test-time=10 -p 11211 -P memcache_binary -s $SERVER 2>&1 | \
		tee >(grep 'Totals' | awk '{ print $2 }' >> $RESULTS)

	end_measurement
	save_stat
done
