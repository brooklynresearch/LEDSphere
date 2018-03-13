
import processing.serial.*;

Serial myPort;       

int  startID = 0;
int endID = 9;
int totalSphereCount = endID-startID+1;

LEDSphere spheres[] = new LEDSphere[totalSphereCount];

boolean gotData = false;

void setup() {

  for (int i=0; i<totalSphereCount; i++) {
    spheres[i] = new LEDSphere(i+startID, 150+100*i, 150);
  }

  String validPort="";
  String[] allPorts=Serial.list();
  for (String port : allPorts ) {
    if (port.startsWith("/dev/tty") && (port.startsWith(".usbmodem", 8) || port.startsWith(".usbserial", 8))) {
      validPort=port;
    }
  }
  println(validPort);

  if (validPort.length()>0) {
    myPort = new Serial(this, validPort, 115200);
    myPort.bufferUntil('\n');
  }

  size(1200, 300);
  frameRate(60);
}


void draw() {
  background(0);

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
      }
    }
    sendBuf=sendBuf+'\n';
    if (sendBuf.length()>1) {
      print(sendBuf);
      myPort.write(sendBuf);
    }
    
    gotData=false;
  }
}

void serialEvent(Serial p) {
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
          spheres[i+startID].updateData(x, y, eventID);
        }
      }
    }
  }
  catch(Exception e) {
    e.printStackTrace();
  }

  gotData=true;
}

