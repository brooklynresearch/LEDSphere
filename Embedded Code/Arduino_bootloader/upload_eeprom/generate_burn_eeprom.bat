
@SET TOOL="C:\Users\SunDeqing\Documents\arduino-1.0.6\hardware/tools/avr/bin/avrdude"
@SET CONFIG="C:\Users\SunDeqing\Documents\arduino-1.0.6\hardware/tools/avr/etc/avrdude.conf"
@SET COMPORT=COM25
@SET BAUDRATE=115200

if "%3"=="" (
    echo "USING COM25"
) else (
    @SET COMPORT=%3
)

if "%4"=="" (
    echo "USING 115200"
) else (
    @SET BAUDRATE=%4
)

python generate_eeprom_content.py %1 %2


%TOOL% -C%CONFIG% -patmega328p -carduino -P\\.\%COMPORT% -b%BAUDRATE% -D -Ueeprom:w:penis_id_eeprom.hex:i 
