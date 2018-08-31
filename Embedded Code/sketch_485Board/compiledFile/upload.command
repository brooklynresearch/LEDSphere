#!/bin/bash
/Users/sundeqing/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino9/bin/avrdude -C/Users/sundeqing/Library/Arduino15/packages/arduino/tools/avrdude/6.3.0-arduino9/etc/avrdude.conf -v -patmega328p -carduino -P/dev/cu.usbserial-A700ONTI -b115200 -D -Uflash:w:sketch_485Board20180831.hex:i 
