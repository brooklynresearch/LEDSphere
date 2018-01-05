#include <SPI.h>
#include <Adafruit_NeoPixel.h>
#include <avr/power.h>
#include "Simple_LIS3DH.h"

#define LED_PIN        A3
#define NUMPIXELS      12

#define LIS3DH_REG_WHOAMI        0x0F

Adafruit_NeoPixel pixels = Adafruit_NeoPixel(NUMPIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);
Simple_LIS3DH lis = Simple_LIS3DH(10);

void setup() {
  // put your setup code here, to run once:
  //SPI.begin();
  //pinMode(10, OUTPUT);
  Serial.begin(9600);

  pixels.begin(); // This initializes the NeoPixel library.

  if (! lis.begin()) {
    Serial.println("Couldnt start");
    while (1);
  }
  Serial.println("LIS3DH found!");

  lis.setRange(LIS3DH_RANGE_4_G);   // 2, 4, 8 or 16 G!

  Serial.print("Range = "); Serial.print(2 << lis.getRange());
  Serial.println("G");

}

int stepCount = 0;

void loop() {
  unsigned long currentMillis = millis();

  static unsigned long LEDPreviousMillis = 0;
  if (currentMillis - LEDPreviousMillis >= 200) {
    pixels.clear();
    for (int i = 0; i < NUMPIXELS; i++) {
      if (i == stepCount) {
        pixels.setPixelColor(i, pixels.Color(15, 0, 0)); // Moderately bright green color.
      }
    }
    pixels.show(); // This sends the updated pixel color to the hardware.
    stepCount++;
    if (stepCount >= 12) stepCount = 0;
    LEDPreviousMillis = currentMillis;
  }

  static unsigned long sensorPreviousMillis = 0;
  if (currentMillis - sensorPreviousMillis >= 200) {
    lis.read();      // get X Y and Z data at once
    // Then print out the raw data
    Serial.print("X:"); Serial.print(lis.x);
    Serial.print("\tY:"); Serial.print(lis.y);
    Serial.print("\tZ:"); Serial.print(lis.z);
    Serial.println();
    sensorPreviousMillis = currentMillis;
  }
}

