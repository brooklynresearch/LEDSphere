#!/bin/bash
avrdudePath='/Users/sundeqing/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino9'

#erase and set fuse, D4 fuse indicates an 1024bytes bootloader 
$avrdudePath/bin/avrdude -C$avrdudePath/etc/avrdude.conf -v -patmega328p -cstk500v2 -Pusb -e -Ulock:w:0x3F:m -Uefuse:w:0xFD:m -Uhfuse:w:0xD4:m -Ulfuse:w:0xFF:m
#program and lock bootloader
$avrdudePath/bin/avrdude -C$avrdudePath/etc/avrdude.conf -v -patmega328p -cstk500v2 -Pusb -Uflash:w:optiboot.hex:i -Ulock:w:0x0F:m 

