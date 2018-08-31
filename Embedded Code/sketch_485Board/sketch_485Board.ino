#include <SPI.h>
#include <EEPROM.h>
#include <avr/power.h>
#include "Simple_LIS3DH.h"
#include "Simple_NeoPixel.h"

#define LED_PIN        A3

#define LIS3DH_REG_WHOAMI        0x0F

Simple_NeoPixel pixels = Simple_NeoPixel(LED_PIN, NEO_GRB + NEO_KHZ800);
//Simple_NeoPixel pixels = Simple_NeoPixel(LED_PIN, NEO_GRBW + NEO_KHZ800);
Simple_LIS3DH lis = Simple_LIS3DH(10);

char inputString[128] = {'\0'};       // a String to hold incoming data
unsigned char inputStringIndex = 0;
boolean stringComplete = false;  // whether the string is complete

bool powerUPLedFinished = false;

bool streamRawData = false;
unsigned long streamRawDataBeginTime = 0;
signed long streamTime = 10 * 1000;

unsigned char boardID = 0;


#define ACC_EVENT_STABLE_CENTER  0
#define ACC_EVENT_STABLE_TILTED  1
#define ACC_EVENT_UNSTABLE       2

unsigned char accelerometerEvent = ACC_EVENT_STABLE_CENTER;

int envelopeRate = 32;
int envelopeThreshold = 768;
int centerThreshold = 384;
int offsetX = 0;
int offsetY = 0;

uint8_t fadeColorR, fadeColorG, fadeColorB;
uint8_t startColorR, startColorG, startColorB;
unsigned long fadeBeginTime = 0;
unsigned long fadeDuration = 0;
bool fading = false;

uint8_t currentColorR = 0, currentColorG = 0, currentColorB = 0;

void setup() {

  pinMode(4, OUTPUT); //485DIR
  digitalWrite(4, LOW);

  Serial.begin(115200);

  boardID = EEPROM.read(0);

  Serial.print("RS485 Address: ");
  Serial.println(boardID);

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

  pinMode(7, OUTPUT); //debug
  pinMode(8, OUTPUT); //debug
}



void loop() {
  unsigned long currentMillis = millis();

  if (!powerUPLedFinished) {
    static unsigned long LEDPreviousMillis = 0;
    static int stepCount = 0;
    if (currentMillis - LEDPreviousMillis >= 10) {
      pixels.clear();
      if (stepCount < 64) {
        uint8_t testBrightness = stepCount;
        for (int i = 0; i < NUMPIXELS; i += 2) {
          pixels.setPixelColor(i, testBrightness, testBrightness, testBrightness);
        }
      } else if (stepCount < 64 * 2) {
        uint8_t testBrightness1 = 127 - stepCount;
        uint8_t testBrightness2 = 63 - testBrightness1;
        for (int i = 0; i < NUMPIXELS; i += 2) {
          pixels.setPixelColor(i, testBrightness1, testBrightness1, testBrightness1);
          pixels.setPixelColor(i + 1, testBrightness2, testBrightness2, testBrightness2);
        }
      } else if (stepCount < 64 * 3) {
        uint8_t testBrightness3 = 191 - stepCount;
        for (int i = 0; i < NUMPIXELS; i += 2) {
          pixels.setPixelColor(i + 1, testBrightness3, testBrightness3, testBrightness3);
        }
      }  else {
        powerUPLedFinished = true;
      }
      pixels.show(); // This sends the updated pixel color to the hardware.
      stepCount++;
      LEDPreviousMillis = currentMillis;
    }
  }

  static unsigned long sensorPreviousMillis = 0;
  if (currentMillis - sensorPreviousMillis >= 20) {
    bool fifoError = false;

    uint8_t fifoStatus = lis.fifoGetStatus();
    fifoError = ((fifoStatus & 0x40) != 0);//OVRN_FIFO
    while ( (fifoStatus & 0b11111 ) > 0 ) {
      lis.read();      // get X Y and Z data at once
      lis.x -= offsetX;
      lis.y -= offsetY;

      accelerometerEvent = accelerometerEventProcess(lis.x, lis.y);
      // Then print out the raw data

      if (streamRawData) {
        char buf[20];
        char* bufPtr = buf;
        *bufPtr = 'S';
        *bufPtr++;
        bufPtr = ucharToHex2_no_end(boardID, bufPtr);
        bufPtr = uintToHex4_no_end(lis.x, bufPtr);
        bufPtr = uintToHex4_no_end(lis.y, bufPtr);
        bufPtr = uintToHex4(lis.z, bufPtr);
        *bufPtr++ = '\n';
        *bufPtr++ = '\0';
        digitalWrite(4, HIGH);
        Serial.print(buf);
      }
      fifoStatus = lis.fifoGetStatus();
    }
    /*if (accelerometerEvent == ACC_EVENT_UNSTABLE) setLEDcolor(64, 0, 0);
      else if (accelerometerEvent == ACC_EVENT_STABLE_CENTER) setLEDcolor(0, 64, 0);
      else if (accelerometerEvent == ACC_EVENT_STABLE_TILTED) setLEDcolor(0, 0, 64);*/
    Serial.flush();
    digitalWrite(4, LOW);


    if (fifoError) {
      Serial.println("FIFO ERR");
      lis.resetFifo();
    }

    sensorPreviousMillis = currentMillis;
  }

  if (fading && powerUPLedFinished) {
    unsigned int elaspedTime = millis () - fadeBeginTime;
    unsigned char r, g, b;
    if (elaspedTime >= fadeDuration) {
      fading = false;
      r = fadeColorR; g = fadeColorG; b = fadeColorB;
    } else {
      r = map(elaspedTime, 0, fadeDuration, startColorR, fadeColorR);
      g = map(elaspedTime, 0, fadeDuration, startColorG, fadeColorG);
      b = map(elaspedTime, 0, fadeDuration, startColorB, fadeColorB);
    }
    setRingColor(r, g, b);
  }


  if (streamRawData) {
    if ((signed long)(currentMillis - streamRawDataBeginTime) >= streamTime) {
      streamRawData = false;
    }
  }

  if (stringComplete) {
    uint8_t id = hexToUchar2(&inputString[1]);
    uint8_t stringLength = strlen(inputString);
    if (inputString[0] == 'S' && stringLength == 5  ) { //stream mode
      if (id == boardID) {
        streamRawDataBeginTime = millis();
        uint8_t inputTime = hexToUchar2(&inputString[3]);
        streamTime = ((unsigned int)inputTime) * inputTime * 100ul;
        streamRawData = true;
      }
    } else if (inputString[0] == 'L' && stringLength == 9 ) { //set light color
      if (id == boardID) {  //L01080808
        uint8_t r = hexToUchar2(&inputString[3]);
        uint8_t g = hexToUchar2(&inputString[5]);
        uint8_t b = hexToUchar2(&inputString[7]);
        if (powerUPLedFinished) {
          setRingColor(r, g, b);
        }
      }
    } else if (inputString[0] == 'F' && stringLength == 13 ) { //Fade light color
      if (id == boardID) {  //F010808080064
        fadeColorR = hexToUchar2(&inputString[3]);
        fadeColorG = hexToUchar2(&inputString[5]);
        fadeColorB = hexToUchar2(&inputString[7]);
        startColorR = currentColorR;
        startColorG = currentColorG;
        startColorB = currentColorB;
        fadeDuration = hexToInt16(&inputString[9]);
        fadeBeginTime = millis();
        fading = true;
      }
    } else if (inputString[0] == 'E' && stringLength == 3) {  //report back current value
      if (id == boardID) {
        char buf[16];
        char* bufPtr = buf;
        *bufPtr = 'E';
        *bufPtr++;
        bufPtr = ucharToHex2_no_end(boardID, bufPtr);
        bufPtr = ucharToHex2_no_end(accelerometerEvent, bufPtr);
        bufPtr = uintToHex4_no_end(lis.x, bufPtr);
        bufPtr = uintToHex4(lis.y, bufPtr);
        *bufPtr++ = '\n';
        *bufPtr++ = '\0';
        digitalWrite(4, HIGH);
        Serial.print(buf);
        Serial.flush();
        digitalWrite(4, LOW);
      }
    } else if (inputString[0] == 'P' && stringLength == (3 + 12)) { //set parameters
      if (id == boardID) {
        envelopeRate = hexToInt16(&inputString[3]);
        envelopeThreshold = hexToInt16(&inputString[7]);
        centerThreshold = hexToInt16(&inputString[11]);
      }
    } else if (inputString[0] == 'O' && stringLength == (3 + 8)) { //set offset
      if (id == boardID) {
        offsetX = hexToInt16(&inputString[3]);
        offsetY = hexToInt16(&inputString[7]);
      }
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

void setRingColor(uint8_t r, uint8_t g, uint8_t b) {
  currentColorR = r; currentColorG = g; currentColorB = b;
  for (int i = 0; i < NUMPIXELS; i++) {
    pixels.setPixelColor(i, r, g, b);
  }
  pixels.show();
}

unsigned char accelerometerEventProcess(int16_t x, int16_t y) {
  static unsigned char state = ACC_EVENT_UNSTABLE;
  static int axisEvenlopXTop = 0, axisEvenlopXBtm = 0;
  static int axisEvenlopYTop = 0, axisEvenlopYBtm = 0;
  static unsigned char stableCenterAccu = 0;
  static unsigned char stableTiltAccu = 0;


  axisEvenlopXTop -= envelopeRate;
  if (axisEvenlopXTop < x) axisEvenlopXTop = x;
  axisEvenlopXBtm += envelopeRate;
  if (axisEvenlopXBtm > x) axisEvenlopXBtm = x;
  axisEvenlopYTop -= envelopeRate;
  if (axisEvenlopYTop < y) axisEvenlopYTop = y;
  axisEvenlopYBtm += envelopeRate;
  if (axisEvenlopYBtm > y) axisEvenlopYBtm = y;
  int envelopMaxXY = max(axisEvenlopXTop - axisEvenlopXBtm, axisEvenlopYTop - axisEvenlopYBtm);

  switch (state) {
    case ACC_EVENT_STABLE_CENTER:
    case ACC_EVENT_STABLE_TILTED:
      if (envelopMaxXY > envelopeThreshold) {
        state = ACC_EVENT_UNSTABLE;
      }
      break;
    case ACC_EVENT_UNSTABLE:
      if (envelopMaxXY < (envelopeThreshold / 8)) {
        state = ACC_EVENT_STABLE_CENTER;
      }
      break;
  }
  int maxXY = max(abs(x), abs(y));
  if (maxXY > centerThreshold) {
    stableTiltAccu++;
    stableCenterAccu = 0;
  } else if (maxXY < centerThreshold / 2) {
    stableCenterAccu++;
    stableTiltAccu = 0;
  }

  if (state != ACC_EVENT_UNSTABLE) {
    if (stableCenterAccu >= 16) {
      stableCenterAccu = 0;
      stableTiltAccu = 0;
      state = ACC_EVENT_STABLE_CENTER;
    }
    if (stableTiltAccu >= 16) {
      stableCenterAccu = 0;
      stableTiltAccu = 0;
      state = ACC_EVENT_STABLE_TILTED;
    }
  } else {
    if (stableCenterAccu > 16)  stableCenterAccu = 16;
    if (stableTiltAccu > 16)  stableTiltAccu = 16;
  }
  return state;
}

