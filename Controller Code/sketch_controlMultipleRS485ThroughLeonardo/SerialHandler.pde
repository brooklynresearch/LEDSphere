
import java.util.Arrays;

String[] previousSerialPorts = {};
ArrayList<HotPlugSerial> hotplugSerials = new ArrayList<HotPlugSerial>();

ArrayList<String> SerialHandler_validPorts(String[] allPorts) {
  ArrayList<String> validPorts = new ArrayList<String>();

  String os = System.getProperty("os.name", "win").toLowerCase();
  if (os.indexOf("win") != -1)
  {
    //blacklisted port
    String[] blacklistedPort={"COM3"};
    for (String port : allPorts) {
      int i;
      for (i=0; i<blacklistedPort.length; i++) {
        if (port.equals(blacklistedPort[i])) {
          break;
        }
      }
      if (i>=blacklistedPort.length) {
        validPorts.add(port);
      }
    }
    //println("this is windows");
  } else if (os.indexOf("mac") != -1)
  {
    for (String port : allPorts) {
      if (port.startsWith("/dev/tty") && port.startsWith(".usbmodem", 8)) {
        validPorts.add(port);
      }
    }
  } 
  return validPorts;
}

void SerialHandler_checkSerialPort() {
  String[] allPorts;
  try {
    allPorts = Serial.list();
  }
  catch(NullPointerException e) {
    return;
  }
  if (!Arrays.equals(allPorts, previousSerialPorts)) {
    //println("changed");
    ArrayList<String> oldPorts = SerialHandler_validPorts(previousSerialPorts);
    ArrayList<String> newPorts = SerialHandler_validPorts(allPorts);

    int i=0, j=0;

    while (i<oldPorts.size()) {
      String oneOldPort=oldPorts.get(i);
      boolean matched = false;
      for (j=0; j<newPorts.size(); j++) {
        String oneNewPort=newPorts.get(j);
        if (oneOldPort.equals(oneNewPort)) {
          oldPorts.remove(i);
          newPorts.remove(j);
          matched=true;
          break;
        }
      }
      if (!matched) i++;
    }
    //now oldPorts are removed ports, newPorts are added ports
    for (i=0; i<oldPorts.size(); i++) {
      String oneRemovedPort=oldPorts.get(i);
      println("Serial unplugged: "+oneRemovedPort);
    }
    for (i=0; i<newPorts.size(); i++) {
      String oneAddedPort=newPorts.get(i);
      println("Serial plugged: "+oneAddedPort);
      HotPlugSerial newSerial=new HotPlugSerial(this, oneAddedPort);
      hotplugSerials.add(newSerial);
      //println("!!!! now size "+hotplugSerials.size());
    }

    /*if (oldPorts.size()>0 || newPorts.size()>0) {
     println(oldPorts);
     println(newPorts);
     }*/

    previousSerialPorts=allPorts;
  }
}

class HotPlugSerial { 
  Serial serial;
  String serialName;
  int id=-1;
  int lastHeartBeatTime = 0;
  int startTime = 0;
  boolean started = false;
  PApplet parent;

  HotPlugSerial (PApplet _parent, String _serialName) { 
    serialName=_serialName;
    serial=null;
    startTime=millis();
    lastHeartBeatTime=millis();
    parent=_parent;
  } 
  void processInput(String input) {
    boolean isHeartBeat=false;
    //println(input);
    if (input.startsWith("ID")) {
      isHeartBeat=true;
      String[] parameters = split(input, ':');
      if (parameters.length<2) return;
      int idInHeartbeat = int(parameters[1]);
      if (id != idInHeartbeat) {
        if (id<0) {
          id=idInHeartbeat;
          controlBoards[id].boardConnected=true;  
          controlBoards[id].hotplugSerial=serial;
        } else {
          println("ERROR: id change from "+ id+" to "+idInHeartbeat);
        }
      } else {
        controlBoards[id].heartBeatTime=millis();
      }
      lastHeartBeatTime=millis();
    } else {
      if (id>=0 && id<10){
        controlBoards[id].processInput(input);
      }
    }
    if (!isHeartBeat && id>=0 && id<10) controlBoards[id].serialDataTime=millis();
  }
  boolean update() { 
    if (serial==null) {
      if (!started && (millis()-startTime)>1000) {  //give it some time
        try {
          started=true;
          serial = new Serial(parent, serialName, 115200);

          serial.bufferUntil('\n');
          lastHeartBeatTime=millis();
          //println("!!! add serial?");
        } 
        catch (RuntimeException e) {
          println(e.getMessage());
        }
      }
    }

    //check heartBeat, active not always working
    if (millis()-lastHeartBeatTime>3500) {  //heartbeat lost
      if (serial!=null) serial.stop();
      if (id >=0 &&id<controlBoards.length) {
        controlBoards[id].boardConnected=false;
        controlBoards[id].hotplugSerial=null;
      }
      return true;
    }

    return false;
  }
} 