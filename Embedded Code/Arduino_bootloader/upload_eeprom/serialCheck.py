#!/usr/bin/python

import serial
import serial.tools.list_ports
from time import sleep

comlist = serial.tools.list_ports.comports()
ft232Device = None
for element in comlist:
    if (element.vid == 0x0403 and element.pid == 0x6001):
        ft232Device = element.device

if (ft232Device!=None):
    keepSerialOn = True;
    while keepSerialOn:
        ft232Serial = serial.Serial(ft232Device,baudrate=115200,timeout=0.01,rtscts=1)
        while True:
            try:
                lineCommand = ft232Serial.readline().strip()
            except serial.SerialException:
                break;
            if (len(lineCommand)>0):
                print lineCommand
        ft232Serial.close()
        sleep(0.1)
    
    

