//#define AUTO_RESET_LEONARDO

#include <EEPROM.h>
#include <avr/wdt.h>

unsigned char boardID = -1;

char RS485inputString[64] = {'\0'};       // a String to hold incoming data
unsigned char RS485inputStringIndex = 0;
boolean RS485stringComplete = false;  // whether the string is complete

char USBinputString[256] = {'\0'};       // a String to hold incoming data
unsigned char USBinputStringIndex = 0;
boolean USBstringComplete = false;  // whether the string is complete

#define START_ID  1
#define END_ID  7

char dataTextBuffer[(END_ID - START_ID + 1) * 10 + 2];

unsigned char currentAccessingID = END_ID + 1;

void setup() {
  boardID = EEPROM.read(0);

  Serial.begin(115200);
  Serial1.begin(115200);
  delay(500);
  pinMode(2, OUTPUT); //485DIR
  digitalWrite(2, LOW);

  pinMode(3, OUTPUT); //TEST
  pinMode(4, OUTPUT); //TEST
  pinMode(5, OUTPUT); //TEST
  pinMode(6, OUTPUT); //TEST

  memset(dataTextBuffer, 0, sizeof(dataTextBuffer));
  dataTextBuffer[(END_ID - START_ID + 1) * 10] = '\n';

#ifdef AUTO_RESET_LEONARDO
  wdt_enable(WDTO_8S);
#endif

}

void loop() {
  unsigned long currentMicros = micros();
  unsigned long currentMillis = millis();
  static unsigned long previousSendMicros = 0;
  static unsigned long previousHeatBeatMillis = 0;

  bool serialOpened = Serial.dtr() || Serial.rts();

#ifdef AUTO_RESET_LEONARDO
  bool wdtIsEnabled = ((WDTCSR & (1 << WDE)) != 0);
  static bool wdtWasEnabled = true;
  static unsigned long wdtDisabledMillis;
  if (wdtWasEnabled != wdtIsEnabled) {
    wdtWasEnabled = wdtIsEnabled;
    if (!wdtIsEnabled) wdtDisabledMillis = currentMillis;
  } else {
    if (!wdtIsEnabled) {
      if ((signed long)(currentMillis - wdtDisabledMillis) > 1000) {
        wdt_enable(WDTO_8S);  //CDC seems disable WDT
      }
    }
  }
#endif

  if ((signed long)(currentMillis - previousHeatBeatMillis) > 2000) {
    previousHeatBeatMillis = currentMillis;
    Serial.print("ID:");
    Serial.print(boardID);
    Serial.print('\n');
  }

  if (RS485stringComplete) {

    uint8_t id = hexToUchar2(&RS485inputString[1]);
    uint8_t RS485stringLength = strlen(RS485inputString);
    // Serial.println(RS485stringLength);
    if (RS485inputString[0] == 'E' && RS485stringLength == 13) {
      previousSendMicros = currentMicros - 2000;

      unsigned char dataIndex = id - START_ID;
      memcpy(&dataTextBuffer[dataIndex * 10], &RS485inputString[3], 10);
    }

    RS485inputStringIndex = 0;
    RS485inputString[0] = '\0';

    RS485stringComplete = false;
  }

  if ((signed int)(currentMicros - previousSendMicros) >= 1200) { //send next request command
    currentAccessingID++;
    if (currentAccessingID > END_ID) {
      if (currentAccessingID == (END_ID + 1)) {
        if (USBstringComplete) {  //through put
          //replace all \r to \n
          char *bufPtr = USBinputString;
          for (unsigned char i = 0; i < USBinputStringIndex; i++) {
            if (*bufPtr == '\r') *bufPtr = '\n';
            bufPtr++;
          }

          digitalWrite(2, HIGH);
          Serial1.write(USBinputString);
          Serial1.flush();
          digitalWrite(2, LOW);

          USBinputStringIndex = 0;
          USBinputString[0] = '\0';
          USBstringComplete = false;
        }

      } else {
        currentAccessingID = START_ID;
        //give report
        Serial.print(dataTextBuffer);
        memset(dataTextBuffer, ' ', (END_ID - START_ID + 1) * 10);
      }
    }

    if (currentAccessingID <= END_ID) {
      char buf[8];
      char* bufPtr = buf;
      *bufPtr++ = 'E';
      bufPtr = ucharToHex2_no_end(currentAccessingID, bufPtr);
      *bufPtr++ = '\n';
      *bufPtr++ = '\0';

      digitalWrite(2, HIGH);
      Serial1.write(buf);
      Serial1.flush();
      digitalWrite(2, LOW);
      previousSendMicros = micros();
    }
  }

  while (Serial.available()) {
    // get the new byte:
    char inChar = (char)Serial.read();
    if (inChar == '\n') {
      USBstringComplete = true;
#ifdef AUTO_RESET_LEONARDO
      wdt_reset();
#endif
      USBinputString[USBinputStringIndex] = '\0';
      //USBinputStringIndex++;
    } else {
      if (USBinputStringIndex < 254) {
        USBinputString[USBinputStringIndex] = inChar;
        USBinputStringIndex++;
      }
    }
  }

  bool resetPreviousSendMicros = false;
  while (Serial1.available()) {
    // get the new byte:
    char inChar = (char)Serial1.read();
    if (inChar == '\n') {
      RS485stringComplete = true;
      RS485inputString[RS485inputStringIndex] = '\0';
      RS485inputStringIndex++;
    } else {
      if (RS485inputStringIndex < 62) {
        RS485inputString[RS485inputStringIndex] = inChar;
        RS485inputStringIndex++;
      }
    }
    resetPreviousSendMicros = true;
  }
  if (resetPreviousSendMicros) {
    previousSendMicros = micros();
  }
}
