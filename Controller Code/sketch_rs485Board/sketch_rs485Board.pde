import processing.serial.*;

Serial myPort;                       // The serial port

int dataX[]=new int[512];
int dataY[]=new int[512];
int dataZ[]=new int[512];
int xWritePtr = 0;
int yWritePtr = 0;
int zWritePtr = 0;


void setup() {

  String validPort="";
  String[] allPorts=Serial.list();
  for (String port : allPorts ) {
    if (port.startsWith("/dev/tty") && (port.startsWith(".usbmodem", 8) || port.startsWith(".usbserial", 8))) {
      validPort=port;
    }
  }

  myPort = new Serial(this, validPort, 115200);
  myPort.bufferUntil('\n');


  size(512, 256);
  frameRate(30);
}

void drawGraph(int[] data, int startPt) {
  int nextPt=startPt+1;
  if (nextPt>=512) nextPt=0;
  for (int i=0; i<511; i++) {
    int value1=data[startPt];
    int value2=data[nextPt];
    line(i, 128+value1/128, i+1, 128+value2/128);
    startPt=nextPt;
    nextPt++;
    if (nextPt>=512) nextPt=0;
  }
}

void draw() {
  background(0);
  stroke(255, 0, 0);
  drawGraph(dataX, xWritePtr);
  stroke(0, 255, 0);
  drawGraph(dataY, yWritePtr);
  stroke( 0, 0, 255);
  drawGraph(dataZ, zWritePtr);
}

void serialEvent(Serial p) {
  String inString = p.readString().trim();
  if (inString.length() == 12) {
    try {
      String xStr = inString.substring(0, 4);
      String yStr = inString.substring(4, 8);
      String zStr = inString.substring(8, 12);
      int x=Integer.parseInt(xStr, 16);
      if (x>32767) x=x-65536;
      int y=Integer.parseInt(yStr, 16);
      if (y>32767) y=y-65536;      
      int z=Integer.parseInt(zStr, 16);
      if (z>32767) z=z-65536;

      dataX[xWritePtr]=x;
      xWritePtr++;
      if (xWritePtr>=512) xWritePtr=0;
      dataY[yWritePtr]=y;
      yWritePtr++;
      if (yWritePtr>=512) yWritePtr=0;
      dataZ[yWritePtr]=z;
      zWritePtr++;
      if (zWritePtr>=512) zWritePtr=0;
    }
    catch(Exception e) {
    }
  }
  //println(inString);
}

void mousePressed() {
    myPort.write("S01FF\n");
    println("request");
}

void keyPressed() {
  if (key == '1') {
    myPort.write("L01080000\n");
  }
  if (key == '2') {
    myPort.write("L01000800\n");
  }
  if (key == '3') {
    myPort.write("L01000008\n");
  }
}