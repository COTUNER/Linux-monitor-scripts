#!/bin/bash
while [ "1" ]
do
cb=`python cpu4.py 3`
rx=`echo $cb|awk 'NR==1{print $3}'`
rx1=`echo " $rx /1"|bc`
tx=`echo $cb|awk 'NR==1{print $4}'`
tx1=`echo " $tx /1"|bc`
bandwidth=`ovs-vsctl list queue|awk "NR==9"|cut -c 34-42`
bandwidth1=`echo " $bandwidth / 1000000"|bc`
bandusage=`echo "scale=2; 100* $tx1 / $bandwidth1"|bc`

#echo part

echo "bandwidth  rx   tx   bandusage"
echo "${bandwidth1}M       ${rx1}M   ${tx1}M   ${bandusage}%"

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
echo "banddown: $bandd"
bandii=`echo " $bandwidth / $bandd"|bc`
echo $bandii
if [ $(echo " $bandii < 100000000"|bc) -eq 1 ];then
bandii=100000000
fi
echo "turn band down to "$bandii

ovs-vsctl set queue 143c2966-fb80-45aa-a411-0d51d0fa3400 other_config:max-rate=$bandii
fi
echo "-------------------------------------------------"
done
