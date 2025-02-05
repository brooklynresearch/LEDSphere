import processing.serial.*; //<>// //<>//

Serial myPort;                       // The serial port

int dataLen = 512;

int xWritePtr = 0;
int yWritePtr = 0;
int zWritePtr = 0;

int envelopeRate = 32;
int envelopeThreshold = 768;
int centerThreshold = 384;
int stableCenterAccu = 0;
int stableTiltAccu = 0;


AxisData dataX = new AxisData(dataLen, envelopeRate); 
AxisData dataY = new AxisData(dataLen, envelopeRate); 
AxisData dataZ = new AxisData(dataLen, envelopeRate); 
AxisData dataEvenlope = new AxisData(dataLen, 0); 

HScrollbar hsEnvelope, hsThreshold, hsCenter;  

boolean sensorStable = true;
boolean sensorCentered = true;

void setup() {

  String validPort="";
  String[] allPorts=Serial.list();
  for (String port : allPorts ) {
    if (port.startsWith("/dev/tty") && (port.startsWith(".usbmodem", 8) || port.startsWith(".usbserial", 8))) {
      validPort=port;
    }
  }

  if (validPort.length()>0) {
    myPort = new Serial(this, validPort, 115200);
    myPort.bufferUntil('\n');
  }

  hsEnvelope = new HScrollbar(1024+30, 512+20, 200, 16, 1, "Envelope", 16, 128);  //last 2 is range
  hsThreshold = new HScrollbar(1024+30, 512+60, 200, 16, 1, "Threshold", 128, 2048); 
  hsCenter = new HScrollbar(1024+30, 512+100, 200, 16, 1, "Center", 128, 2048); 
  hsEnvelope.setMapValue(envelopeRate);
  hsThreshold.setMapValue(envelopeThreshold);
  hsCenter.setMapValue(centerThreshold);

  size(1536, 1024);
  frameRate(30);
}

void draw() {

  background(0);
  stroke(64);//grid
  line(0, 256, 1024, 256);
  line(0, 256*2, 1024, 256*2);
  line(0, 256*3, 1024, 256*3);
  line(1024, 0, 1024, 1024);
  line(1024, 512, 1536, 512);

  stroke(32);//center line
  line(0, 128, 1024, 128);
  line(0, 128*3, 1024, 128*3);
  line(0, 128*5, 1024, 128*5);
  //line(0, 128*7, 1024, 128*7);

  fill(255);
  text("X axis: "+dataX.value, 10, 20);//label
  text("Y axis: "+dataY.value, 10, 20+256);
  text("Z axis", 10, 20+512);
  text("max differnce on XY envelope", 10, 20+768);
  text("horizontal acceleration", 1024+10, 20);

  dataX.drawEvenlop(0, 0, 1024, 256, -16384, 16384, 0xFFAA4000, 0xFFAA0040, 1);
  dataY.drawEvenlop(0, 256, 1024, 256, -16384, 16384, 0xFF40AA00, 0xFF00AA40, 1);

  dataX.drawData(0, 0, 1024, 256, -16384, 16384, 0xFFFF0000, 2);
  dataY.drawData(0, 256, 1024, 256, -16384, 16384, 0xFF00FF00, 2);
  dataZ.drawData(0, 512, 1024, 256, -16384, 16384, 0xFF0000FF, 2);
  dataEvenlope.drawData(0, 768, 1024, 256, -128, 8192/2, 0xFFFFFFFF, 2);


  {  //get lastest x,y value
    //add hysteresis to envelopeThreshold
    float newThreshold, newThresholdLinePos;
    if (sensorStable) {
      newThreshold = envelopeThreshold*1;
      if (dataEvenlope.value>(newThreshold)) {
        sensorStable = false;
        println("unstable "+millis());
      }
    } else {
      newThreshold = envelopeThreshold/8;
      if (dataEvenlope.value<(newThreshold)) {
        sensorStable = true;
        sensorCentered=true;
        println("Stable "+millis());
      }
    }
    newThresholdLinePos = map(newThreshold, -128, 8192/2, 1024, 768);
    stroke(32);//center line
    line(0, newThresholdLinePos, 1024, newThresholdLinePos);


    if (sensorStable) {
      int maxXY = max(abs(dataX.value), abs(dataY.value));
      if (maxXY>centerThreshold) {
        stableTiltAccu++;
        stableCenterAccu=0;
      } else if (maxXY<centerThreshold/2) {
        stableCenterAccu++;
        stableTiltAccu=0;
      }
      if (stableCenterAccu>16) {
        stableCenterAccu=0;
        stableTiltAccu=0;
        sensorCentered=true;
      }
      if (stableTiltAccu>16) {
        stableCenterAccu=0;
        stableTiltAccu=0;
        sensorCentered=false;
      }
    }
    draw_horizontalAcceleratrion(1024, 0, 512, 512, 16384, dataX, dataY, envelopeThreshold, sensorStable, sensorCentered);  //computer y is downward
  }

  if (hsEnvelope.update()) {
    envelopeRate=(int)hsEnvelope.getMapValue();
    dataX.axisEvenlopRate=envelopeRate;
    dataY.axisEvenlopRate=envelopeRate;
    dataZ.axisEvenlopRate=envelopeRate;
  }

  if (hsThreshold.update()) {
    envelopeThreshold=(int)hsThreshold.getMapValue();
  }
  if (hsCenter.update()) {
    centerThreshold=(int)hsCenter.getMapValue();
  }

  hsThreshold.display();
  hsEnvelope.display();
  hsCenter.display();
}

void serialEvent(Serial p) {
  String inString = p.readString().trim();
  try {
    char firstChar = inString.charAt(0);
    if (firstChar=='S') {
      if (inString.length() == 15) {

        String xStr = inString.substring(3, 7);
        String yStr = inString.substring(7, 11);
        String zStr = inString.substring(11, 15);
        int x=Integer.parseInt(xStr, 16);
        if (x>32767) x=x-65536;
        int y=Integer.parseInt(yStr, 16);
        if (y>32767) y=y-65536;      
        int z=Integer.parseInt(zStr, 16);
        if (z>32767) z=z-65536;

        dataX.addNewValue(x);
        dataY.addNewValue(y);
        dataZ.addNewValue(z);
        dataEvenlope.addNewValue(max(dataX.axisEvenlopTop-dataX.axisEvenlopBtm, dataY.axisEvenlopTop-dataY.axisEvenlopBtm));
      }
    } else {
      println(inString);
    }
  }
  catch(Exception e) {
  }
}

void keyPressed() {
  if (key == '1') {
    myPort.write("L02080000\n");
  }
  if (key == '2') {
    myPort.write("L02000800\n");
  }
  if (key == '3') {
    myPort.write("L02000008\n");
  }
  if (key == ' ') {
    myPort.write("S02FF\n");
    println("request");
  }
}