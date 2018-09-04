
import processing.serial.*;

Serial myPort;       

int controlBoardCount = 28;
RS485LeonardoController controlBoards[] = new RS485LeonardoController[controlBoardCount];

PImage controlBoardImg;

int sendColor = color(0, 0, 0);

void setup() {
  size(820, 750);
  frameRate(60);
  controlBoardImg = loadImage("control_pcb.png");

  for (int i=0; i<controlBoardCount/2; i++) {


    int x=70;
    int y=50+(i/2)*100;

    if ((i&2) != 0) x+=50;

    int spacingX = 100;
    int sphereOffsetX = 140;
    if ((i%2)==1) {
      spacingX = -100;
      sphereOffsetX = -120;
      x+=0+600;
    }

    controlBoards[i]=new RS485LeonardoController(x, y+20, i, true, spacingX, sphereOffsetX);
    int topUnitID = i+(controlBoardCount/2);
    controlBoards[topUnitID]=new RS485LeonardoController(x+20, y-10, topUnitID, false, spacingX, sphereOffsetX);
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

  text(int(frameRate), 20, 650);

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