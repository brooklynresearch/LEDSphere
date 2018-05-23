

@REM Fill in your cpu type and full path to the programming tool
@SET CPU=ATmega328p
@SET TOOL="C:\Program Files\Atmel\AVR Tools\STK500\stk500"
@SET FUSES=D4FF
@SET EXT_FUSES=FD
@SET LOCK_BIT=CF
@SET CUSTOMERCODE="optiboot.hex"


%TOOL% -cUSB -d%CPU% -s -E%EXT_FUSES% -f%FUSES% -F%FUSES% -G%EXT_FUSES% -l%LOCK_BIT% -L%LOCK_BIT% -e -pf -vf -if%CUSTOMERCODE%



