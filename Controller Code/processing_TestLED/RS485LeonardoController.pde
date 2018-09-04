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

  }

  void update() {
    int timeNow=millis();

/*

    if ((frameCount%30==0)) {  //refresh LED
      outBuffer="";
      for (int i=0; i<totalSphereCount; i++) {
        LEDSphere oneSphere=spheres[i];
        outBuffer=outBuffer+String.format("L%02X%02X%02X%02X\r", oneSphere.id, oneSphere.fillcolorDim >> 16 & 0xFF, oneSphere.fillcolorDim >> 8 & 0xFF, oneSphere.fillcolorDim >> 0 & 0xFF);
      }
    }*/



    
  }

  void draw() {

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

          }
          catch(Exception e) {
            //println("parseInt ERR");
            //e.printStackTrace();
          }
        }
      }
    }


    gotData=true;
  }

}