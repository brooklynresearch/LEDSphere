#define device_ADDR 19

#include <EEPROM.h>


void setup()
{
  unsigned char i;
  Serial.begin(9600);
  delay(1000);
  for (i=0;i<3;i++){
    if (EEPROM.read(i)!=device_ADDR) break;
  }
  if (i>=3){
    Serial.println("No need to write");
  }
  else{
    for (i=0;i<3;i++){
      EEPROM.write(i, device_ADDR);
    }
    Serial.println("Write OK");
  }
}

void loop()
{
}




