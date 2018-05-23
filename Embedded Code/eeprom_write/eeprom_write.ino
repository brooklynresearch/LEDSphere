#define device_ADDR 1

#include <EEPROM.h>

#include <avr/power.h>
#include "Simple_NeoPixel.h"
#define LED_PIN        A3
Simple_NeoPixel pixels = Simple_NeoPixel(LED_PIN, NEO_GRB + NEO_KHZ800);


void setup()
{
  unsigned char i;
  Serial.begin(9600);
  delay(1000);
  for (i = 0; i < 3; i++) {
    if (EEPROM.read(i) != device_ADDR) break;
  }
  if (i >= 3) {
    Serial.println("No need to write");
  }
  else {
    for (i = 0; i < 3; i++) {
      EEPROM.write(i, device_ADDR);
    }
    Serial.println("Write OK");
  }

  pixels.begin(); // This initializes the NeoPixel library.
}

void loop() {
  pixels.clear();
  for (int i = 0; i < NUMPIXELS; i++) {
    pixels.setPixelColor(i, 8, 8, 8);
  }

  pixels.show(); // This sends the updated pixel color to the hardware.

  delay(1);
}




