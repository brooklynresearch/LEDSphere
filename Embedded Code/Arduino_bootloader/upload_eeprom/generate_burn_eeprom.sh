#!/bin/bash
avrdudePath='/Users/sundeqing/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino9'
serialPort='/dev/cu.usbserial-A96LT7BB' 

python generate_eeprom_content.py $1

#program and lock bootloader
$avrdudePath/bin/avrdude -C$avrdudePath/etc/avrdude.conf -patmega328p -carduino -P$serialPort -b115200 -D -Ueeprom:w:ledsphere_id_eeprom.hex:i 
