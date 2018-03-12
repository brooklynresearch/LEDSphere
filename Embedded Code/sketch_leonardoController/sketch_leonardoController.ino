char RS485inputString[64] = {'\0'};       // a String to hold incoming data
unsigned char RS485inputStringIndex = 0;
boolean RS485stringComplete = false;  // whether the string is complete

unsigned char startID = 0;
unsigned char endID = 9;

void setup() {

  Serial.begin(115200);
  Serial1.begin(115200);
  delay(500);
  Serial.print("RS485 Address: ");
  pinMode(2, OUTPUT); //485DIR
  digitalWrite(2, LOW);

  pinMode(3, OUTPUT); //TEST
  pinMode(4, OUTPUT); //TEST
  pinMode(5, OUTPUT); //TEST
  pinMode(6, OUTPUT); //TEST
}

void loop() {
  unsigned long currentMillis = millis();
  static unsigned long previousSendMillis = 0;

  if (RS485stringComplete) {

    uint8_t id = hexToUchar2(&RS485inputString[1]);
    uint8_t RS485stringLength = strlen(RS485inputString);
    // Serial.println(RS485stringLength);
    if (RS485inputString[0] == 'E' && RS485stringLength == 13) {
      digitalWrite(4,HIGH);
      previousSendMillis = currentMillis - 100;
      digitalWrite(4,LOW);
    }

    RS485inputStringIndex = 0;
    RS485inputString[0] = '\0';

    RS485stringComplete = false;
  }

  if ((signed int)(currentMillis - previousSendMillis) >= 2) { //send next request command 

    char buf[8];
    char* bufPtr = buf;
    *bufPtr++ = 'E';
    bufPtr = ucharToHex2_no_end(9, bufPtr);
    *bufPtr++ = '\n';
    *bufPtr++ = '\0';

    digitalWrite(2, HIGH);
    Serial1.write(buf);
    Serial1.flush();
    digitalWrite(2, LOW);
    previousSendMillis = millis()+1;
  }



  bool resetPreviousSendMillis = false;
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
    resetPreviousSendMillis = true;
  }
  if (resetPreviousSendMillis) {
    digitalWrite(5,HIGH);
    previousSendMillis = millis()+1;
    digitalWrite(5,LOW);
  }
}
