TIME="/usr/bin/time --format=%e -o $TIMELOG --append"

uname -a | grep -q x86_64
if [[ $? == 0 ]]; then
	TOOLS=tools_x86
	x86=1
	arm64=0
else
	TOOLS=tools_arm64
	x86=0
	arm64=1
fi

refresh() {
	sync && echo 3 > /proc/sys/vm/drop_caches
	sleep 15
}


apt-get install -y time bc pbzip2 gawk wget

for i in time awk yes date bc pbzip2 wget
do
	iname=`which $i`
	if [[ ! -a $iname ]] ; then
		echo "$i not found in path, please install it; exiting"
		exit
	else
		echo "$i is found: $iname"
	fi
done

