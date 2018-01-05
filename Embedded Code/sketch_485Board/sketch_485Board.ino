#include <SPI.h>
#include <Adafruit_NeoPixel.h>
#include <avr/power.h>
#include "Simple_LIS3DH.h"

#define LED_PIN        A3
#define NUMPIXELS      12

#define LIS3DH_REG_WHOAMI        0x0F

Adafruit_NeoPixel pixels = Adafruit_NeoPixel(NUMPIXELS, LED_PIN, NEO_GRB + NEO_KHZ800);
Simple_LIS3DH lis = Simple_LIS3DH(10);

char inputString[64];         // a String to hold incoming data
unsigned char inputStringIndex = 0;
boolean stringComplete = false;  // whether the string is complete


bool streamRawData = false;
unsigned long streamRawDataBeginTime = 0;
signed int streamTime = 10 * 1000;

void setup() {

  pinMode(4, OUTPUT); //485DIR
  digitalWrite(4, LOW);

  Serial.begin(115200);

  pixels.begin(); // This initializes the NeoPixel library.

  if (! lis.begin()) {
    Serial.println("Couldnt start");
    while (1);
  }
  Serial.println("LIS3DH found!");

  lis.setRange(LIS3DH_RANGE_4_G);   // 2, 4, 8 or 16 G!

  Serial.print("Range = "); Serial.print(2 << lis.getRange());
  Serial.println("G");

  //set fifo
  uint8_t dataToWrite = 0;  //Temporary variable

  //Build LIS3DH_FIFO_CTRL_REG
  dataToWrite = lis.readRegister8(LIS3DH_REG_FIFOCTRL); //Start with existing data
  dataToWrite &= 0x20;//clear all but bit 5
  dataToWrite |= ((0x01) << 6) | (20 & 0x1F); //apply mode & watermark threshold
  lis.writeRegister8(LIS3DH_REG_FIFOCTRL, dataToWrite);

  //Build CTRL_REG5
  dataToWrite = lis.readRegister8(LIS3DH_REG_CTRL5); //Start with existing data
  dataToWrite &= 0xBF;//clear bit 6 //FIFO enable
  dataToWrite |= (0x01) << 6;
  //Now, write the patched together data
  lis.writeRegister8(LIS3DH_REG_CTRL5, dataToWrite);

  //fifoClear
  while ( (lis.fifoGetStatus() & 0x20 ) == 0 ) {  // EMPTY flag
    lis.read();
  }

  //fifoStartRec( void )
  //Turn off...
  dataToWrite = lis.readRegister8(LIS3DH_REG_FIFOCTRL);
  dataToWrite &= 0x3F;//clear mode
  lis.writeRegister8(LIS3DH_REG_FIFOCTRL, dataToWrite);
  //  ... then back on again
  dataToWrite = lis.readRegister8(LIS3DH_REG_FIFOCTRL); //Start with existing data
  dataToWrite &= 0x3F;//clear mode
  dataToWrite |= (0x01 & 0x03) << 6; //apply mode
  //Now, write the patched together data
  lis.writeRegister8(LIS3DH_REG_FIFOCTRL, dataToWrite);
}



void loop() {
  unsigned long currentMillis = millis();

  /*static unsigned long LEDPreviousMillis = 0;
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
    }*/

  static unsigned long sensorPreviousMillis = 0;
  if (currentMillis - sensorPreviousMillis >= 10) {
    bool fifoError = false;

    uint8_t fifoStatus = lis.fifoGetStatus();
    fifoError = ((fifoStatus & 0x60) != 0);//OVRN_FIFO or EMPTY
    while ( (fifoStatus & 0x20 ) == 0 ) {
      lis.read();      // get X Y and Z data at once
      // Then print out the raw data

      if (streamRawData) {
        char buf[16];
        char* bufPtr = buf;
        bufPtr = uintToHex4_no_end(lis.x, bufPtr);
        bufPtr = uintToHex4_no_end(lis.y, bufPtr);
        bufPtr = uintToHex4(lis.z, bufPtr);
        digitalWrite(4, HIGH);
        Serial.println(buf);
      }
      fifoStatus = lis.fifoGetStatus();
    }
    Serial.flush();
    digitalWrite(4, LOW);

    if (fifoError) {
      Serial.println("FIFO ERR");
      uint8_t dataToWrite = lis.readRegister8(LIS3DH_REG_FIFOCTRL);
      dataToWrite &= 0x3F;//clear mode
      lis.writeRegister8(LIS3DH_REG_FIFOCTRL, dataToWrite);
      dataToWrite |= (0x01 & 0x03) << 6; //apply mode
      //Now, write the patched together data
      lis.writeRegister8(LIS3DH_REG_FIFOCTRL, dataToWrite);
    }

    sensorPreviousMillis = currentMillis;
  }




  if (streamRawData) {
    if ((signed long)(currentMillis - streamRawDataBeginTime) >= streamTime) {
      streamRawData = false;
    }
  }

  if (stringComplete) {
    uint8_t id = hexToUchar2(&inputString[1]);
    if (inputString[0] == 'S') {
      if (id == 1) {
        streamRawDataBeginTime = millis();
        streamTime = hexToUchar2(&inputString[3]) * 100;
        streamRawData = true;
      }
    } else if (inputString[0] == 'L') {
      if (id == 1) {  //L01080808
        uint8_t r = hexToUchar2(&inputString[3]);
        uint8_t g = hexToUchar2(&inputString[5]);
        uint8_t b = hexToUchar2(&inputString[7]);
        for (int i = 0; i < NUMPIXELS; i++) {
          pixels.setPixelColor(i, pixels.Color(r, g, b)); // Moderately bright green color.
        }
        pixels.show();
      }
    }


    inputStringIndex = 0;
    inputString[0] = '\0';

    stringComplete = false;
  }

}

void serialEvent() {
  while (Serial.available()) {
    // get the new byte:
    char inChar = (char)Serial.read();
    if (inChar == '\n' || inChar == '\r') {
      stringComplete = true;
      inputString[inputStringIndex] = '\0';
      inputStringIndex++;
    } else {
      if (inputStringIndex < 63) {
        inputString[inputStringIndex] = inChar;
        inputStringIndex++;
      }
    }
  }
}

