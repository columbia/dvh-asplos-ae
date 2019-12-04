#!/bin/bash

SRV=$1
TEST=${2-ALL}
RESULTS=${3-netperf.txt}
REPTS=${4-40}

echo "Measuring netperf performance of $SRV"

for _TEST in TCP_STREAM TCP_RR TCP_MAERTS ; do
	if [[ "$TEST" != "ALL" && "$TEST" != "$_TEST" ]]; then
		continue
	fi
	# Uncomment this to enable exit count capturing
	#source exits.sh $_TEST L1
	source exits.sh $_TEST
	echo $_TEST >> $RESULTS
	for i in `seq 1 $REPTS`; do

		start_measurement

		if [[ "$_TEST" == "TCP_STREAM" ]]; then
			netperf -T ,2 -H $SRV -t $_TEST | tee >(cat > /tmp/netperf_single.txt)
		elif [[ "$_TEST" == "TCP_MAERTS" ]]; then
			netperf -T 2,2 -H $SRV -t $_TEST | tee >(cat > /tmp/netperf_single.txt)
		else
			netperf -H $SRV -t $_TEST | tee >(cat > /tmp/netperf_single.txt)
		fi

		end_measurement
		save_stat

		if [[ $? == 0 ]]; then
			if [[ "$_TEST" == "TCP_RR" ]]; then
				ret=`cat /tmp/netperf_single.txt | tail -n 2 | head -n 1 | awk '{ print $6 }'`
				echo $ret >> $RESULTS
				save_performance $ret
			else
				cat /tmp/netperf_single.txt | tail -n 1 | awk '{ print $5 }' >> $RESULTS
			fi
		fi
	done
done
