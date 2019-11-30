#!/bin/bash

branch_name=`git symbolic-ref -q --short HEAD`
if [ -z $branch_name ]; then
	branch_name=""
fi

LV_DEFAULT=`echo $branch_name | cut -d"-" -f2-`

if [ -z "$1" ]; then
	read -p "LOCALVERSION?[$LV_DEFAULT]:" LV
	if [ "$LV" == "" ]; then
		if [ "$LV_DEFAULT" != "" ]; then
			LV=-$LV_DEFAULT
		else
			LV=""
		fi
	fi
else
	LV="$1"
fi

read -p "make modules_instsall??[y/N]:" MOD
if [ "$MOD" == "y" ]; then
	MOD_INSTALL="sudo make modules_install"
	BZ_IMAGE=""
else
	# dummy command
	MOD_INSTALL="ls"
	BZ_IMAGE="bzImage"
fi

time make -j 40 LOCALVERSION=$LV $BZ_IMAGE && $MOD_INSTALL && sudo make install
