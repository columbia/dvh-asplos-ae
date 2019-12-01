ETH=`ifconfig | grep "10\.10\." -B1 | head -n 1 | awk '{ print $1 }'`

IP=`ifconfig | grep "10\.10\." | awk '{ print $2 }' | cut -d ":" -f2`
# Could be multiple IPs. Take the first one
IP=`echo $IP | awk '{print $1}'`
IP_TAIL=`echo $IP | cut -d "." -f4`
if [ $IP_TAIL -ge 100 ]; then
	IS_HOST=0
else
	IS_HOST=1
fi

case $ETH in
 *br*)
    ETH=`brctl show | grep $ETH | awk '{ print $4 }'`
 ;;
esac

ARCH=`uname -m`
