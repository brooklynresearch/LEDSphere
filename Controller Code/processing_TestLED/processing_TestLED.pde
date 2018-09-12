
import processing.serial.*;

Serial myPort;       

int controlBoardCount = 28;
RS485LeonardoController controlBoards[] = new RS485LeonardoController[controlBoardCount];

PImage controlBoardImg;

int sendColor = color(0, 0, 0);

void setup() {
  size(430, 280);
  frameRate(60);
  controlBoardImg = loadImage("control_pcb.png");

  for (int i=0; i<controlBoardCount/4; i++) {
    int x=50;
    int y=20+(i)*35;

    for (int j=0; j<4; j++) {
      int id = i+j*(controlBoardCount/4);
      controlBoards[id]=new RS485LeonardoController(x+j*100, y, id);
    }
  }
}


void draw() {
  //hotplug stuff
  {
    int i=0;
    while (i<hotplugSerials.size()) {
      HotPlugSerial onePort=hotplugSerials.get(i);
      if (onePort.update()) {
        println("Remove "+onePort.serialName+" due to inactivity");
        hotplugSerials.remove(i);
        continue;
      }
      i++;
    }
  }

  for (int i=0; i<hotplugSerials.size(); i++) {
  }

  SerialHandler_checkSerialPort();

  background(0);

  text(int(frameRate), 20, 260);

  {
    for (int i=0; i<controlBoards.length; i++) {  //draw board
      controlBoards[i].update();
      controlBoards[i].draw();
    }
  }

  int frameMod = frameCount%120;
  boolean sendData = (frameCount%10)==0;


  switch (frameMod) {
  case 100:
    println("White");
    sendColor = color(255, 255, 255);

    break;
  case 90:
    println("Blue");
    sendColor = color(0, 0, 25);

    break;
  case 80:
    println("Green");
    sendColor = color(0, 25, 0);

    break;
  case 70:
    println("Red");
    sendColor = color(25, 0, 0);

    break;
  }

  if (sendData) {
    for (int i=0; i<controlBoards.length; i++) {  //draw board
      RS485LeonardoController oneBoard = controlBoards[i];
      String outBuffer = "";
      for (int j=1; j<=10; j++) {
        outBuffer=outBuffer+String.format("L%02X%02X%02X%02X\r", j, sendColor >> 16 & 0xFF, sendColor >> 8 & 0xFF, sendColor >> 0 & 0xFF);
      }
      outBuffer=outBuffer+'\n';
      oneBoard.sendData(outBuffer);
      //println("send",i);
    }
  }
}

void serialEvent(Serial port) {
  int i;
  String inString = port.readString();
  inString = inString.substring(0, inString.length() - 1);
  for (i=0; i<hotplugSerials.size(); i++) {
    HotPlugSerial onePort=hotplugSerials.get(i);
    if (onePort.serial==port) {
      onePort.processInput(inString);
      break;
    }
  }
  if (i>=hotplugSerials.size()) {
    println("Data from unregisterd port: ");
    println(inString);
  }
}

void keyPressed() {
  if (key == 'd') {
    //print some debug info
    println("hotplugSerials has "+hotplugSerials.size()+" elements");
  }
}