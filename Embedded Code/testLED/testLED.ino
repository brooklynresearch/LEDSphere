
#include <EEPROM.h>

#include <avr/power.h>
#include "Simple_NeoPixel.h"
#define LED_PIN        A3
Simple_NeoPixel pixels = Simple_NeoPixel(LED_PIN, NEO_GRB + NEO_KHZ800);


void setup()
{
  unsigned char i;
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




