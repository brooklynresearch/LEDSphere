
import processing.serial.*;

Serial myPort;       

int controlBoardCount = 20;
RS485LeonardoController controlBoards[] = new RS485LeonardoController[controlBoardCount];

PImage controlBoardImg;



void setup() {
  size(1200, 1000);
  frameRate(60);
  controlBoardImg = loadImage("control_pcb.png");

  for (int i=0; i<controlBoardCount/2; i++) {
    int x=70;
    int y=50+i*100;
    controlBoards[i]=new RS485LeonardoController(x, y+20, i, true);
    int topUnitID = i+(controlBoardCount/2);
    controlBoards[topUnitID]=new RS485LeonardoController(x+20, y-10, topUnitID, false);
   
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

  {
    for (int i=0; i<controlBoards.length; i++) {  //draw board
      controlBoards[i].update();
      controlBoards[i].draw();
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

  if (key == 'r') {  //reset calibration
    for (int i=0; i<controlBoards.length; i++) {
      controlBoards[i].resetCalibration();
    }
  }
  if (key == 'c') {
    for (int i=0; i<controlBoards.length; i++) {
      controlBoards[i].setCalibration();
    }
  }
}