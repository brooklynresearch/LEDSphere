#include <SPI.h>
#include <avr/power.h>
#include "Simple_LIS3DH.h"
#include "Simple_NeoPixel.h"

#define LED_PIN        A3

#define LIS3DH_REG_WHOAMI        0x0F

Simple_NeoPixel pixels = Simple_NeoPixel(LED_PIN, NEO_GRB + NEO_KHZ800);
Simple_LIS3DH lis = Simple_LIS3DH(10);

char inputString[64] = {'\0'};       // a String to hold incoming data
unsigned char inputStringIndex = 0;
boolean stringComplete = false;  // whether the string is complete

bool powerUPLedFinished = false;

bool streamRawData = false;
unsigned long streamRawDataBeginTime = 0;
signed long streamTime = 10 * 1000;

unsigned char boardID = 1;

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

  lis.setupFifo();
}



void loop() {
  unsigned long currentMillis = millis();

  if (!powerUPLedFinished) {
    static unsigned long LEDPreviousMillis = 0;
    static int stepCount = 0;
    if (currentMillis - LEDPreviousMillis >= 200) {
      pixels.clear();
      if (stepCount < 6) {
        for (int i = 0; i < NUMPIXELS; i++) {
          uint8_t modValue = (i + stepCount) % 3;
          uint8_t testBrightness = 15;
          pixels.setPixelColor(i, pixels.Color((modValue == 0) ? testBrightness : 0, (modValue == 1) ? testBrightness : 0, (modValue == 2) ? testBrightness : 0));
        }
      }
      pixels.show(); // This sends the updated pixel color to the hardware.
      stepCount++;
      if (stepCount > 6) powerUPLedFinished = true;;
      LEDPreviousMillis = currentMillis;
    }
  }

  static unsigned long sensorPreviousMillis = 0;
  if (currentMillis - sensorPreviousMillis >= 20) {
    bool fifoError = false;

    uint8_t fifoStatus = lis.fifoGetStatus();
    fifoError = ((fifoStatus & 0x60) != 0);//OVRN_FIFO or EMPTY
    while ( (fifoStatus & 0x20 ) == 0 ) {
      lis.read();      // get X Y and Z data at once
      // Then print out the raw data

      if (streamRawData) {
        char buf[16];
        char* bufPtr = buf;
        *bufPtr = 'S';
        *bufPtr++;
        bufPtr = ucharToHex2_no_end(boardID, bufPtr);
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
      lis.resetFifo();
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
    uint8_t stringLength = strlen(inputString);
    if (inputString[0] == 'S' && stringLength == 5  ) {
      if (id == boardID) {
        streamRawDataBeginTime = millis();
        uint8_t inputTime = hexToUchar2(&inputString[3]);
        streamTime = ((unsigned int)inputTime) * inputTime * 100ul;
        streamRawData = true;
      }
    } else if (inputString[0] == 'L' && stringLength == 9 ) {
      if (id == boardID) {  //L01080808
        uint8_t r = hexToUchar2(&inputString[3]);
        uint8_t g = hexToUchar2(&inputString[5]);
        uint8_t b = hexToUchar2(&inputString[7]);
        for (int i = 0; i < NUMPIXELS; i++) {
          pixels.setPixelColor(i, pixels.Color(r, g, b)); // Moderately bright green color.
        }
        pixels.show();
      }
    } else if (memcmp ( inputString, "STREAM", sizeof(6)) == 0 && stringLength == 8) {

    }


    inputStringIndex = 0;
    inputString[0] = '\0';

    stringComplete = false;
  }
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

