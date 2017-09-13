#!/bin/bash
u=0
axx=1
bxx=1
while [ "1" ]
do
cb=`python cpu5.py 1`
rx=`echo $cb|cut -d' ' -f3`
rx1=`echo " $rx /1"|bc`
tx=`echo $cb|cut -d' ' -f4`
tx1=`echo " $tx /1"|bc`
cpu=`virsh vcpucount u222u14L --guest`
free=`virsh dommemstat u222u14L|awk 'NR==6{print $2}'`
allmem=`virsh dommemstat u222u14L|awk 'NR==7{print $2}'`
used=`expr $allmem - $free`
mempercent=`echo "scale=3; 100*$used/$allmem"|bc`
bandwidth=`ovs-vsctl list queue|awk "NR==9"|cut -c 34-42`
bandwidth1=`echo " $bandwidth / 1000000"|bc`
bandusage=`echo "scale=2; 100* $tx1 / $bandwidth1"|bc`
#inbandwidth=`ovs-vsctl list queue|awk "NR==14"|cut -c 34-42`
#inbandwidth1=`echo "$inbandwidth / 1000000"|bc`
#inbandusage=`echo "scale=2; 100* $rx1 / $inbandwidth1"|bc`

alltime=`echo $cb|cut -d' ' -f1`
systime=`echo $cb|cut -d' ' -f2`
#echo $cb

axx=1
bxx=1

for ((i=1; i<=5; i ++))
do
#  echo "---$i---"
  if [ `echo "$alltime < 20000"|bc` -eq 1 ];then
    continue 2
  fi
  if [ `echo "$systime < 4000"|bc` -eq 1 ];then
    continue 2
  fi
  eval alltime$i=0.01
  if [ $i -eq 5 ];then
  alltime5=$alltime
  systime5=$systime
  else
  zz=$(($i+1))
  ooo=0
  oooo=0
  ooo=`eval echo '$'alltime$zz`
  oooo=`eval echo '$'systime$zz`
  eval alltime${i}=$ooo
  eval systime${i}=$oooo
  fi
echo "$i: $ooo,$oooo"



axx=`echo "scale=3; ($axx + $ooo) / 1"|bc`
bxx=`echo "scale=3; ($bxx + $oooo) / 1"|bc`
#echo $axx,$bxx
done 

cent=`echo "scale=0;100-(100* $bxx / $axx)"|bc`
echo "cent: $cent"
if [ `echo "$cent < 20"|bc` -eq 1 ];then
  cpupercent=`echo " $cent * 0.7"|bc`
elif [ `echo "$cent < 45"|bc` -eq 1 ];then
  cpupercent=`echo " $cent * 0.8"|bc`
elif [ `echo "$cent < 65"|bc` -eq 1 ];then
  cpupercent=`echo " $cent * 0.9"|bc`
elif [ `echo "$cent > 65 && $cent < 85"|bc` -eq 1 ];then
  cpupercent=`echo " $cent * 0.9"|bc` 
elif [ `echo "$cent > 85"|bc` -eq 1 ];then
  cpupercent=`echo " $cent * 1.1"|bc`
else
  cpupercent=`echo "$cent"`
fi
if [ `echo "$axx < 450000"|bc` -eq 1 ];then
  cpupercent=`echo " $axx / 10000"|bc`
fi
echo "cpupercent: $cpupercent"
for ((i=1;i<=8;i++));
do
  if [ `echo "$axx > 700000* $i && $axx < 700000*( $i +1)"|bc` -eq 1 ];then
  cpupercent=`echo "$cpupercent * ($i +1)"|bc`
  echo $cpupercent
  fi
done


#echo part
datek=`date +%k`
datem=`date +%M`
dates1=`date +%S`
dates2=`echo "$dates1 + 33"|bc`
if [ `echo "$dates2 > 60"|bc` -eq 1 ];then
  dates2=`echo "$dates2 - 60"|bc`
  datem=`echo "$datem + 1"|bc`
fi
datekms=`echo "$datek":"$datem":"$dates2"`
echo "systime  vcpu cusage   mem       musage rx"
echo "$datekms  $cpu   $cpupercent%       $allmem  $mempercent% $rx1"
echo "$datekms $cpu $cpupercent% $allmem $mempercent% $rx1" >> /home/ubuntu/monitor/pd.f
echo "bandwidth  tx   bandusage " 
echo "${bandwidth1}M   ${tx1}M   ${bandusage}% "
#echo "inbandwidth rx inbandusage"
#echo "${inbandwidth1}M ${rx1}M ${inbandusage}%"


#vcpu up part
#cpui is the final value of vcpu

if [ `echo "$cpupercent > 90 * $cpu"|bc` -eq 1 ];then
cpui=`expr $cpu + 1`
echo "try to turn vcpu up to: "$cpui
if [ $cpui -eq 9 ];then
cpui=8
fi
echo "finally turn vcpu count up to "$cpui
virsh setvcpus u222u14L --guest --live $cpui
fi

#vcpu down part
#pdown is the threshold of turning down vcpu count
#cpuii is the final value of vcpu

pdown=`echo "scale=5;90* ( $cpu - 1)"|bc`
echo "cpudown: $pdown"
if [ $(echo "$cpupercent < $pdown "|bc) -eq 1 ]; then
cpuii=`echo "$cpu - 1"|bc`

echo "try to turn vcpu down to: "$cpuii
if [ $cpuii -eq 0 ]; then
cpuii=`echo 1`
fi
let u+=1;
echo "ready to turn down: $u"
if [ $u -eq 2 ];then
echo "finally turn vcpu count down to "$cpuii
virsh setvcpus u222u14L --guest --live $cpuii 
u=0
fi
fi
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

#bandwidth up part
#bandup is the ratio of raising bandwidth
#bandi is the final value of bandwidth

if [ $(echo " $bandusage > 90"|bc) -eq 1 ]; then
#bandup=`echo "scale=3;( $bandusage/100-0.9)*3+1.1"|bc`
#echo "bandup: $bandup"
bandi1=`echo "scale=0;$bandwidth + 20000000"|bc`
bandi=`echo "$bandi1 / 1"|bc`
echo $bandi
if [ $(echo "$bandi > 1000000000"|bc) -eq 1 ];then
bandi=1000000000
fi
echo "turn band up to "$bandi
ovs-vsctl set queue 143c2966-fb80-45aa-a411-0d51d0fa3400 other_config:max-rate=$bandi
fi

#bandwidth down part
#bandd is the ratio of reducing bandwidth
#bandii is the final bandwidth value

if [ $(echo " $bandusage < 71"|bc) -eq 1 ]; then
bandd=`echo "scale=3;90 / ( $bandusage +1)"|bc`
#echo "banddown: $bandd"
bandii=`echo " $bandwidth / $bandd"|bc`
echo $bandii
if [ $(echo " $bandii < 100000000"|bc) -eq 1 ];then
bandii=100000000
fi
echo "turn band down to "$bandii
ovs-vsctl set queue 143c2966-fb80-45aa-a411-0d51d0fa3400 other_config:max-rate=$bandii
fi

#inband up part


echo "-------------------------------------------------"
done
