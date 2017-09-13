#!/bin/bash
while [ "1" ]
do
free=`virsh dommemstat u222u14L|awk 'NR==6{print $2}'`
allmem=`virsh dommemstat u222u14L|awk 'NR==7{print $2}'`
used=`expr $allmem - $free`
mempercent=`echo "scale=5; 100*$used/$allmem" |bc`

#echo part

echo "systime    mem     musage "
echo "`date +%k:%M:%S`   $allmem $mempercent% "


#mem up part
#memup is the ratio of raising mem
#memi is the final mem value

if [ $(echo "$mempercent > 90"|bc) -eq 1 ]; then
up=`echo "scale=3;( $mempercent/100-0.9)*3+1.1"| bc`
# 0.9 1.4 1.1 
echo "memup: $up"
memi1=`echo "scale=6;$allmem * $up"|bc` 
memi=`echo " $memi1 / 1"|bc`
echo $memi
if [ $(echo "$memi > 8183764"|bc) -eq 1  ]; then
memi=8183764
fi
echo "turn mem up to "$memi
virsh setmem u222u14L --live $memi
fi

#mem down part
#down is the ratio of reducing mem
#memii is the final value of mem

if [ $(echo " $mempercent < 71"|bc) -eq  1 ]; then
down=`echo "scale=3;90/ $mempercent"|bc`
echo "memdown: $down"
memii=`echo " $allmem / $down"|bc`
echo $memii
if [ $(echo " $memii < 1024576"|bc) -eq 1 ]; then
memii=1024576
fi
echo "turn mem down to "$memii
virsh setmem u222u14L --live $memii
fi

echo "-------------------------------------------------"
sleep 1
done
