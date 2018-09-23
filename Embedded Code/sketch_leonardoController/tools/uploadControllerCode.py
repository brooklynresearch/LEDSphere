#!/usr/bin/python

import sys
import serial
import serial.tools.list_ports
from time import sleep
import subprocess
import time


for eachArg in sys.argv:   
    print(eachArg)

comlist = serial.tools.list_ports.comports()
leonardoDevice = None
for element in comlist:
    if (element.vid == 0x2341 and element.pid == 0x8036):
        leonardoDevice = element.device

if (leonardoDevice!=None):
    print "Leonardo Found on: " + leonardoDevice
    leonardoSerial = serial.Serial(leonardoDevice,baudrate=1200,timeout=0.01,rtscts=1)
    #sleep(0.1)
    leonardoSerial.close()
    
    sleep(1)
    
    flashHex = "leonardoController20180923.hex"
    
    if (len(sys.argv)>1):
        print "write ID: "+sys.argv[1]
        subprocess.call(["./generate_eeprom_content.py",sys.argv[1]])
        eepromHex = "controller_id_eeprom.hex"
        subprocess.call(["/Users/sundeqing/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino9/bin/avrdude", "-C/Users/sundeqing/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino9/etc/avrdude.conf", "-v","-patmega32u4","-cavr109","-P"+leonardoDevice,"-b57600","-D","-Uflash:w:"+flashHex+":i","-Ueeprom:w:"+eepromHex+":i"])
        
        
        
    else:
        print "No ID write"
        subprocess.call(["/Users/sundeqing/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino9/bin/avrdude", "-C/Users/sundeqing/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino9/etc/avrdude.conf", "-v","-patmega32u4","-cavr109","-P"+leonardoDevice,"-b57600","-D","-Uflash:w:"+flashHex+":i"])
        
    #open port to read it for a few seconds
    
    print "waiting..."
    sleep(2)
    print "Open port to check output"
    leonardoSerial = serial.Serial(leonardoDevice,baudrate=9600,timeout=0.01,rtscts=1)
    serialStartTime = time.time()
    while (time.time()-serialStartTime)<3:
        try:
            lineCommand = leonardoSerial.readline().strip()
        except serial.SerialException:
            break;
        if (len(lineCommand)>0):
            print lineCommand
    leonardoSerial.close()
    
    
        


