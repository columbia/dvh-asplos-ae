#!/bin/bash

which netperf > /dev/null
if [[ $? != 0 ]]; then
	apt-get install -y netperf
	update-rc.d netperf disable
fi

