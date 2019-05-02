import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation1;
NetAddress myRemoteLocation2;
import java.net.InetAddress;

boolean enableOSC=true;

String myIP = "unknown";
String partnerIP = "192.168.0.102";

long accuTime = 0;
import processing.serial.*;

Serial myPort;       

int controlBoardCount = 24;
RS485LeonardoController controlBoards[] = new RS485LeonardoController[controlBoardCount];
EffectObjects effectObjects = new EffectObjects();

PImage controlBoardImg;

void setup() {
  size(1780, 750);
  frameRate(60);
  controlBoardImg = loadImage("control_pcb.png");

  for (int i=0; i<controlBoardCount/2; i++) {


    int x=70;
    int y=70+(i/2)*100;

    if ((i&2) != 0) x+=50;

    int spacingX = 100;
    int sphereOffsetX = 140;
    if ((i%2)==1) {
      spacingX = -100;
      sphereOffsetX = -120;
      x+=960+600;
    }

    controlBoards[i]=new RS485LeonardoController(x, y, i, true, spacingX, sphereOffsetX);
    int topUnitID = i+(controlBoardCount/2);
    controlBoards[topUnitID]=new RS485LeonardoController(x, y, topUnitID, false, spacingX, sphereOffsetX);
  }

  if (enableOSC) {
    oscP5 = new OscP5(this, 7401);
    myRemoteLocation1 = new NetAddress(partnerIP, 7400);
    myRemoteLocation2 = new NetAddress(partnerIP, 7401);
  }

  try {
    InetAddress inet;
    inet = InetAddress.getLocalHost();
    myIP = inet.getHostAddress();
  }
  catch (Exception e) {
  }
}

void draw() {
  accuTime = 0;
  //long stampTime = System.nanoTime();

  if (frameCount%15==0) {
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

    SerialHandler_checkSerialPort();  //Serial.list() is slow, no need to run every frame
  }

  background(0);
  fill(255);
  text(int(frameRate), 20, 700);
  text("myIP: "+myIP+"  partnerIP: "+partnerIP, 20, 720);

  synchronized (effectObjects) {
    effectObjects.update();  //this give all spheres color
    effectObjects.draw();

    {
      for (int i=0; i<controlBoards.length; i++) {  //draw board
        controlBoards[i].update();
        controlBoards[i].draw();
      }
    }
  }

  //accuTime+=System.nanoTime()-stampTime;
  //println("Draw us", (accuTime)/1000);
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

  if (key == 't') {
    
  }

  if (key == 'w') {  //test
    effectObjects.addWave(100, HALF_PI, false);
    effectObjects.addWave(100, HALF_PI, true);
  }

  if (key == 'o') {  //test
    effectObjects.addRipple(500, 500, true, true);
  }

  if (key == 'b') {  //test
    effectObjects.addBreath(false);
  }
}

void oscEvent(OscMessage theOscMessage) {
  if (theOscMessage.checkAddrPattern("/ripple")==true) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("ffi")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      float xpos = theOscMessage.get(0).floatValue();
      float ypos = theOscMessage.get(1).floatValue();
      int onFloorValue = theOscMessage.get(2).intValue();  
      boolean onGround = (onFloorValue !=0);
      synchronized (effectObjects) {
        effectObjects.addRipple(xpos, ypos, !onGround, false);
      }
      //println("### OSC ripple", xpos, ypos, !onGround);
    }
  } else {
    println("### received an osc message with addrpattern "+theOscMessage.addrPattern()+" and typetag "+theOscMessage.typetag());
    theOscMessage.print();
  }
}