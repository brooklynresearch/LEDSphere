
import processing.serial.*;

Serial myPort;       

//int boardsID[]={1, 2, 3};
LEDSphere spheres[] = new LEDSphere[2];

int boardCheckingIndex = 0;

interface CheckStates {
  int
    IDLE=0, 
    INQUIRED=1, 
    RESPONSED=2, 
    TIMEOUT=3;
}

int boardCheckInquireTime = 0;

int boardCheckStates = CheckStates.IDLE;

void setup() {

  for (int i=0; i<spheres.length; i++) {
    spheres[i] = new LEDSphere(i+1, 150+300*i, 150);
  }

  String validPort="";
  String[] allPorts=Serial.list();
  for (String port : allPorts ) {
    if (port.startsWith("/dev/tty") && (port.startsWith(".usbmodem", 8) || port.startsWith(".usbserial", 8))) {
      validPort=port;
    }
  }
  println(validPort);

  if (validPort.length()>0) {
    myPort = new Serial(this, validPort, 115200);
    myPort.bufferUntil('\n');
  }

  size(600, 300);
  frameRate(60);
}


void draw() {
  background(0);

  LEDSphere oneSphere=spheres[boardCheckingIndex];
  int id= oneSphere.id;
  switch (boardCheckStates) {
  case CheckStates.IDLE:
    String checkOutput = String.format("E%02X\n", id);  //weird new line needed?
    //println(checkOutput);
    myPort.write(checkOutput);
    boardCheckStates=CheckStates.INQUIRED;
    boardCheckInquireTime=millis();
    break;
  case CheckStates.INQUIRED:
    if ((millis()-boardCheckInquireTime)>20) {
      boardCheckStates=CheckStates.TIMEOUT;
      oneSphere.lost=true;
      oneSphere.timeLost=millis();
      //println("TIMEOUT first");
    }
    break;

  case CheckStates.RESPONSED:
    oneSphere.lost=false;
    oneSphere.timeoutLimit=100;
    //println("RESPONSED");
  case CheckStates.TIMEOUT:
    if (boardCheckStates==CheckStates.TIMEOUT) {
      //println("TIMEOUT "+oneSphere.id);
      oneSphere.timeLost = millis();
      oneSphere.timeoutLimit=oneSphere.timeoutLimit*100+(int)random(100);
      if (oneSphere.timeoutLimit>30000) oneSphere.timeoutLimit =30000;
    }
    boardCheckStates = CheckStates.IDLE;
    //while (1) {
    boardCheckingIndex++;
    if (boardCheckingIndex>=spheres.length) boardCheckingIndex=0;
    //}
    break;
  default:
    break;
  }


  for (int i=0; i<spheres.length; i++) {
    spheres[i].draw();
  }
}

void serialEvent(Serial p) {
  String inString = p.readString().trim();
  //println(inString);
  try {
    char firstChar = inString.charAt(0);
    if (firstChar=='S') {
      if (inString.length() == 15) {
        String idStr = inString.substring(1, 3);

        String xStr = inString.substring(3, 7);
        String yStr = inString.substring(7, 11);
        String zStr = inString.substring(11, 15);
        int id=Integer.parseInt(idStr, 16);
        int x=Integer.parseInt(xStr, 16);
        if (x>32767) x=x-65536;
        int y=Integer.parseInt(yStr, 16);
        if (y>32767) y=y-65536;      
        int z=Integer.parseInt(zStr, 16);
        if (z>32767) z=z-65536;
      }
    } else if (firstChar=='E') {
      if (inString.length() == 13) {
        String idStr = inString.substring(1, 3);
        String eventStr = inString.substring(3, 5);
        String xStr = inString.substring(5, 9);
        String yStr = inString.substring(9, 13);
        int id=Integer.parseInt(idStr, 16);
        int x=Integer.parseInt(xStr, 16);
        if (x>32767) x=x-65536;
        int y=Integer.parseInt(yStr, 16);
        if (y>32767) y=y-65536;      
        int eventID=Integer.parseInt(eventStr, 16);

        LEDSphere oneSphere=spheres[boardCheckingIndex];

        if (oneSphere.id == id) {
          oneSphere.updateData(x, y, eventID); 
          //println(eventID);
        } else {
          //println("ID mismatch");
        }
        if (boardCheckStates == CheckStates.INQUIRED) {
          boardCheckStates = CheckStates.RESPONSED;
          if (oneSphere.needUpdateParameter>0) {
            String paraOutput = String.format("P%02X%04X%04X%04X\n", id, oneSphere.envelopeRate, oneSphere.envelopeThreshold, oneSphere.centerThreshold);
            myPort.write(paraOutput);
            //println(paraOutput);
            oneSphere.needUpdateParameter--;
          } else {
            String ledOutput = String.format("L%02X%02X%02X%02X\n", id, oneSphere.fillcolorDim >> 16 & 0xFF, oneSphere.fillcolorDim >> 8 & 0xFF, oneSphere.fillcolorDim >> 0 & 0xFF);
            myPort.write(ledOutput);
          }
        }
      }
    } else {
      println(inString);
    }
  }
  catch(Exception e) {
    e.printStackTrace();
  }
}