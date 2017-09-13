from __future__ import division
import os,sys,time,libvirt
from xml.dom import minidom
av = 0
ac = 0
timeinterval=float(sys.argv[1])
conn=libvirt.open("qemu:///system")
dom=conn.lookupByName('u222u14L')
stats=dom.getCPUStats(True)
alltime1=stats[0]['cpu_time']
systime1=stats[0]['system_time']
#print alltime1,systime1,usertime1
ifacestat=dom.interfaceStats('vnet1')
rxbyte1=ifacestat[0]
txbyte1=ifacestat[4]
time.sleep(timeinterval)
ifacestat2=dom.interfaceStats('vnet1')
rxbyte2=ifacestat2[0]
txbyte2=ifacestat2[4]
rxrate=(rxbyte2-rxbyte1)/130000/timeinterval
txrate=(txbyte2-txbyte1)/130000/timeinterval
stats2=dom.getCPUStats(True)
alltime2=stats2[0]['cpu_time']
systime2=stats2[0]['system_time']
alltime=(alltime2-alltime1)/10000000
systime=(systime2-systime1)/10000000
percent0=100-100*systime/alltime
if percent0 < 20:
    percet0=percent0*0.7
elif percent0 > 20 and percent0 < 35:
    percent0=percent0*0.8
elif percent0 > 35 and percent0 < 45:
    percent0=percent0*0.9
elif percent0 > 65 and percent0 < 85:
    percent0=percent0*1.05
elif percent0 > 85:
    percent0=percent0*1.1
if alltime < 450:
    percent0=alltime/10
for i in range(1,8):
    if alltime > 600*i and alltime < 600*(i+1):
        percent0=percent0*(i+1)
print "percent:",percent0
print round(rxrate,2),round(txrate,2)
conn.close()
exit(0)
