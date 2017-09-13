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
alltime=(alltime2-alltime1)/10000
systime=(systime2-systime1)/10000
print round(alltime,0)
print round(systime,0)
print round(rxrate,2)
print round(txrate,2)
conn.close()
exit(0)
