#!/bin/bash

avrdudePath='/Applications/Arduino.app/Contents/Java/hardware/tools/avr'
serialPort='/dev/cu.usbserial-A700ONTI' 

python generate_eeprom_content.py $1

#program and lock bootloader
$avrdudePath/bin/avrdude -C$avrdudePath/etc/avrdude.conf -patmega328p -carduino -P$serialPort -b115200 -D -Uflash:w:sketch_485Board20180831.hex:i -Ueeprom:w:ledsphere_id_eeprom.hex:i 
