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


  size(1536, 1024);
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
  stroke(64);//grid
  line(0, 256, 1024, 256);
  line(0, 256*2, 1024, 256*2);
  line(0, 256*3, 1024, 256*3);
  line(1024, 0, 1024, 1024);

  stroke(32);//center line
  line(0, 128, 1024, 128);
  line(0, 128*3, 1024, 128*3);
  line(0, 128*5, 1024, 128*5);

  fill(255);

  text("X axis", 10, 20);
  text("Y axis", 10, 20+256);
  text("Z axis", 10, 20+512);

  draw_graph(dataX, 0, 0, 1024, 256, -16384, 16384, 0xFFFF0000, 2, xWritePtr);
  draw_graph(dataY, 0, 256, 1024, 256, -16384, 16384, 0xFF00FF00, 2, yWritePtr);
  draw_graph(dataZ, 0, 512, 1024, 256, -16384, 16384, 0xFF0000FF, 2, zWritePtr);
}

void serialEvent(Serial p) {
  String inString = p.readString().trim();
  char firstChar = inString.charAt(0);
  if (firstChar=='S') {
    if (inString.length() == 15) {
      try {
        String xStr = inString.substring(3, 7);
        String yStr = inString.substring(7, 11);
        String zStr = inString.substring(11, 15);
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
  } else {


    println(inString);
  }
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