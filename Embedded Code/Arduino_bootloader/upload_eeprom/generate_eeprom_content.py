#!/usr/bin/python
import sys
from ihex import IHex
# https://github.com/kierdavis/IHex

id_value=0xFF;
#stall_value=0x100;
if (len(sys.argv)>=2):
    id_arg = int(sys.argv[1]);
    if (id_arg>=0 and id_arg<255):
        id_value=id_arg;
#if (len(sys.argv)>=3):
#    stall_arg = int(sys.argv[2]);
#    if (stall_arg>=0 and stall_arg<255):
#        stall_value=stall_arg;


#L = [id_value,id_value,id_value,stall_value,stall_value,stall_value];
L = [id_value,id_value,id_value];
str=''.join(chr(i) for i in L);
ihex = IHex();
ihex.insert_data(0,str);
ihex.write_file('ledsphere_id_eeprom.hex');
