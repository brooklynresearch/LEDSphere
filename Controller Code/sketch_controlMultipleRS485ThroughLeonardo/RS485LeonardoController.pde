class RS485LeonardoController {
  int x;
  int y;
  int id;
  boolean boardConnected;
  boolean boardEverConnected;
  Serial hotplugSerial;

  int heartBeatTime=-1000;
  int serialDataTime=-1000;

  String outBuffer = "";

  int startID = 1;
  int endID = 7;
  int totalSphereCount = endID-startID+1;
  LEDSphere spheres[] = new LEDSphere[totalSphereCount];

  boolean gotData = false;

  boolean onGround = false;

  RS485LeonardoController (int _x, int _y, int _id, boolean _onGround, int xSpacing, int sphereOffset) {  
    x=_x;
    y=_y;
    id=_id;
    onGround=_onGround;
    boardConnected=false;
    hotplugSerial=null;

    int sphereOffsetX = onGround?-20+0:20-20;  //offset controller also
    int sphereOffsetY = onGround?20-20:-20+10;  //offset controller also

    for (int i=0; i<totalSphereCount; i++) {
      spheres[i] = new LEDSphere(i+startID, x+sphereOffset+xSpacing*i+sphereOffsetX, y+0+sphereOffsetY, onGround);
    }
    for (int i=0; i<totalSphereCount; i++) {
      LEDSphere oneSphere=spheres[i];
      outBuffer=outBuffer+String.format("P%02X%04X%04X%04X\r", oneSphere.id, oneSphere.envelopeRate, oneSphere.envelopeThreshold, oneSphere.centerThreshold);
    }
  }

  void update() {
    int timeNow=millis();

    if ((frameCount%30==0)) {
      int halfSecond = frameCount/30;
      if (halfSecond<5) {  //send settings
        outBuffer="";
        for (int i=0; i<totalSphereCount; i++) {
          LEDSphere oneSphere=spheres[i];
          outBuffer=outBuffer+String.format("P%02X%04X%04X%04X\r", oneSphere.id, oneSphere.envelopeRate, oneSphere.envelopeThreshold, oneSphere.centerThreshold);
        }
      }
    }

    if ((frameCount%30==0)) {  //refresh LED
      outBuffer="";
      for (int i=0; i<totalSphereCount; i++) {
        LEDSphere oneSphere=spheres[i];
        outBuffer=outBuffer+String.format("L%02X%02X%02X%02X\r", oneSphere.id, oneSphere.fillcolorDim >> 16 & 0xFF, oneSphere.fillcolorDim >> 8 & 0xFF, oneSphere.fillcolorDim >> 0 & 0xFF);
      }
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
        sendData(sendBuf);
      }

      gotData=false;
    }
  }

  void draw() {

    for (int i=0; i<spheres.length; i++) {
      spheres[i].draw();
    }

    //draw icon
    //ellipse(x, y, 200, 200);
    if (!boardConnected) {
      tint(255, 64);
    }
    //tint(255, 200);
    image(controlBoardImg, x-controlBoardImg.width/2, y-controlBoardImg.height/2);
    noTint();

    if (millis()-heartBeatTime<100) {  //heartbeat square
      noStroke();
      fill(255, 255, 0);
      rect(x+controlBoardImg.width/2+2, y-controlBoardImg.height/2+2, 8, 4);
    }
    if (millis()-serialDataTime<100) {  //serial square
      noStroke();
      fill(0, 255, 0);
      rect(x+controlBoardImg.width/2+2, y-controlBoardImg.height/2+6, 8, 4);
    }
    if (boardConnected) {
      fill(255);
    } else {
      fill(31);
    }
    text(id, x+controlBoardImg.width/2+2, y-controlBoardImg.height/2+22);

    if (boardConnected) boardEverConnected=true;
    else if (boardEverConnected) {
      noStroke();
      fill(255, 0, 0);
      rect(x+controlBoardImg.width/2+2, y-controlBoardImg.height/2+10, 8, 8);
    }
  }

  void sendData(String data) {
    if (hotplugSerial!=null) {
      hotplugSerial.write(data);
    }
  }

  void processInput(String input) {

    if (input.length() == totalSphereCount*10) {
      for (int i=0; i<totalSphereCount; i++) {
        String oneData = input.substring(i*10, (i+1)*10);
        if (oneData.charAt(0)==' ') {
          //there is no data
        } else {
          String eventStr = oneData.substring(0, 2);
          String xStr = oneData.substring(2, 6);
          String yStr = oneData.substring(6, 10);
          int x, y, eventID;
          try {
            x=Integer.parseInt(xStr, 16);
            y=Integer.parseInt(yStr, 16);
            eventID=Integer.parseInt(eventStr, 16);
            if (x>32767) x=x-65536;
            if (y>32767) y=y-65536;      

            spheres[i].updateData(x, y, eventID);
          }
          catch(Exception e) {
            println("parseInt ERR");
            //e.printStackTrace();
          }
        }
      }
    }


    gotData=true;
  }

  void resetCalibration() {
    String sendBuf = "";
    for (int i=0; i<totalSphereCount; i++) {
      sendBuf=sendBuf+String.format("O%02X%04X%04X\r", i+startID, 0, 0);
    }
    sendData(sendBuf);
  }

  void setCalibration() {
    String sendBuf = "";
    for (int i=0; i<totalSphereCount; i++) {
      LEDSphere oneSphere=spheres[i];
      if (!oneSphere.lost) {
        int currentX=oneSphere.acceX;
        int currentY=oneSphere.acceY;
        if (currentX<0) currentX+=0x10000;
        if (currentY<0) currentY+=0x10000;
        sendBuf=sendBuf+String.format("O%02X%04X%04X\r", i+startID, currentX, currentY);
      }
    }
    sendData(sendBuf);
  }
}