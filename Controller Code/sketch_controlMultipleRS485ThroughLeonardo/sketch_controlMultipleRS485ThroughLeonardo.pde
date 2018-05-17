
import processing.serial.*;

Serial myPort;       

int controlBoardCount = 10;
RS485LeonardoController controlBoards[] = new RS485LeonardoController[controlBoardCount];

PImage controlBoardImg;



void setup() {
  size(1200, 800);
  frameRate(30);
  controlBoardImg = loadImage("control_pcb.png");

  for (int i=0; i<controlBoards.length; i++) {
    int x=50;
    int y=50+i*70;
    controlBoards[i]=new RS485LeonardoController(x, y, i);
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
      controlBoards[i].draw();
    }
  }


  /*
  if ((frameCount%30==0)) {
   int halfSecond = frameCount/30;
   if (halfSecond<5) {  //send settings
   outBuffer="";
   for (int i=0; i<totalSphereCount; i++) {
   LEDSphere oneSphere=spheres[i];
   outBuffer=outBuffer+String.format("P%02X%04X%04X%04X\r", oneSphere.id, oneSphere.envelopeRate, oneSphere.envelopeThreshold, oneSphere.centerThreshold);
   }
   } else {  //refresh LED
   outBuffer="";
   for (int i=0; i<totalSphereCount; i++) {
   LEDSphere oneSphere=spheres[i];
   outBuffer=outBuffer+String.format("L%02X%02X%02X%02X\r", oneSphere.id, oneSphere.fillcolorDim >> 16 & 0xFF, oneSphere.fillcolorDim >> 8 & 0xFF, oneSphere.fillcolorDim >> 0 & 0xFF);
   }
   }
   }
   
   for (int i=0; i<spheres.length; i++) {
   spheres[i].draw();
   }
   
   
   if (gotData) {
   String sendBuf = "";
   for (int i=0; i<totalSphereCount; i++) {
   LEDSphere oneSphere=spheres[i];
   if (oneSphere.changedEvent) {
   sendBuf=sendBuf+String.format("L%02X%02X%02X%02X\r", i+startID, oneSphere.fillcolorDim >> 16 & 0xFF, oneSphere.fillcolorDim >> 8 & 0xFF, oneSphere.fillcolorDim >> 0 & 0xFF);
   oneSphere.changedEvent = false;
   } else {
   if (outBuffer.length()>0) {
   sendBuf=outBuffer;
   outBuffer="";
   }
   }
   }
   sendBuf=sendBuf+'\n';
   if (sendBuf.length()>1) {
   //println("SEND");
   //print(sendBuf);
   myPort.write(sendBuf);
   }
   
   gotData=false;
   }*/
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



  /*
  String inString = p.readString();
   inString = inString.substring(0, inString.length() - 1);
   
   try {
   if (inString.length() == totalSphereCount*10) {
   for (int i=0; i<totalSphereCount; i++) {
   String oneData = inString.substring(i*10, (i+1)*10);
   if (oneData.charAt(0)==' ') {
   //there is no data
   } else {
   String eventStr = oneData.substring(0, 2);
   String xStr = oneData.substring(2, 6);
   String yStr = oneData.substring(6, 10);
   int x=Integer.parseInt(xStr, 16);
   if (x>32767) x=x-65536;
   int y=Integer.parseInt(yStr, 16);
   if (y>32767) y=y-65536;      
   int eventID=Integer.parseInt(eventStr, 16);
   
   spheres[i].updateData(x, y, eventID);
   }
   }
   }
   }
   catch(Exception e) {
   e.printStackTrace();
   }
   
   gotData=true;*/
}

void keyPressed() {
  if (key == 'd') {
    //print some debug info
    println("hotplugSerials has "+hotplugSerials.size()+" elements");
  }
}