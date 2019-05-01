int colorIdle = color(225, 100, 100);
int colorMaxEffect = color(255, 255, 255);
int tiltColor = color(225, 100, 100);

int maxEffectValue = 255;
int tiltMaxValue = 255;
int tiltTransistionTimeMS = 100;

class EffectObjects {
  ArrayList<RippleEffectObject> ripples = new ArrayList<RippleEffectObject>();
  int ripplesLimit = 64;
  ArrayList<WaveEffectObject> waves = new ArrayList<WaveEffectObject>();
  int wavesLimit = 5;
  ArrayList<BreathEffectObject> breaths = new ArrayList<BreathEffectObject>();
  int breathsLimit = 1;

  EffectObjects() {
  }


  void update() {
    int i;

    for (RS485LeonardoController oneBoard : controlBoards) {
      for (LEDSphere oneSphere : oneBoard.spheres) {
        oneSphere.effectValue=0;
      }
    }

    i=0;
    while (i < ripples.size()) {
      if (ripples.get(i).update()) {
        i++;
      } else {
        ripples.remove(i);
      }
    }

    i=0;
    while (i < waves.size()) {
      if (waves.get(i).update()) {
        i++;
      } else {
        waves.remove(i);
      }
    }

    i=0;
    while (i < breaths.size()) {
      if (breaths.get(i).update()) {
        i++;
      } else {
        breaths.remove(i);
      }
    }

    //color mapping
    for (RS485LeonardoController oneBoard : controlBoards) {
      for (LEDSphere oneSphere : oneBoard.spheres) {


        if (oneSphere.effectValue==0) {
          oneSphere.fillcolor=colorIdle;
        } else {
          oneSphere.fillcolor=lerpColor(colorIdle, colorMaxEffect, (float)oneSphere.effectValue/maxEffectValue);
        }

        //do tilt color
        int tiltAccumulate = oneSphere.tiltAccumulate;
        if (oneSphere.acceEvent==1 || tiltAccumulate>0) {
          boolean incTilt = (oneSphere.acceEvent==1);
          int tiltChange = ((millis()-oneSphere.eventChangeMillis)*tiltMaxValue/tiltTransistionTimeMS);
          if (incTilt) {
            tiltAccumulate = oneSphere.tiltAccumulateOnLastChange + tiltChange;
          } else {
            tiltAccumulate = oneSphere.tiltAccumulateOnLastChange - tiltChange;
          }
          tiltAccumulate = constrain(tiltAccumulate, 0, tiltMaxValue);
          oneSphere.tiltAccumulate=tiltAccumulate;
          oneSphere.fillcolor=lerpColor(oneSphere.fillcolor, tiltColor, (float)tiltAccumulate/tiltMaxValue);
        }

        oneSphere.fillcolorDim=color(red(oneSphere.fillcolor)/dimScale, green(oneSphere.fillcolor)/dimScale, blue(oneSphere.fillcolor)/dimScale);
      }
    }
  }

  void draw() {
    noFill();
    strokeWeight(2);
    for (RippleEffectObject oneRipple : ripples) {
      oneRipple.draw();
    }
    for (WaveEffectObject wave : waves) {
      wave.draw();
    }
    for (BreathEffectObject breath : breaths) {
      breath.draw();
    }
  }

  void addRipple(float _x, float _y, boolean _onGround, boolean sendOSC) {
    //also send ripple
    if (enableOSC && sendOSC) {
      OscMessage myMessage = new OscMessage("/ripple");
      myMessage.add(_x);
      myMessage.add(_y);
      myMessage.add(_onGround?1:0);
      oscP5.send(myMessage, myRemoteLocation1);
      oscP5.send(myMessage, myRemoteLocation2);
    }
    if (ripples.size()<ripplesLimit) {
      ripples.add(new RippleEffectObject(_x, _y, _onGround));
    }
  }

  void addWave(float _x, float _angle, boolean _onGround) {
    if (waves.size()<wavesLimit) {
      waves.add(new WaveEffectObject(_x, _angle, _onGround));
    }
  }

  void addBreath(boolean _onGround) {
    if (breaths.size()<breathsLimit) {
      breaths.add(new BreathEffectObject(_onGround));
    }
  }
}

class RippleEffectObject {
  int startTime;
  float startX, startY; 
  boolean onGround;
  int lifeInMS = 4000;
  float pixelPerMS = .8;
  float effectDist = 200;
  float effectStrength = 255;

  float diameter = 0;
  float otherSphereDistace[][] = new float[controlBoardCount][];

  RippleEffectObject(float _x, float _y, boolean _onGround) {
    startTime = millis();
    startX=_x;
    startY=_y;
    onGround=_onGround;

    for (int i=0; i<controlBoards.length; i++) {  //calculate distance
      RS485LeonardoController oneBoard = controlBoards[i];
      if (oneBoard.onGround != onGround) continue;
      otherSphereDistace[i]=new float[oneBoard.spheres.length];
      for (int j=0; j<oneBoard.spheres.length; j++) {
        otherSphereDistace[i][j] = dist(startX, startY, oneBoard.spheres[j].xpos, oneBoard.spheres[j].ypos);
      }
    }
  }
  boolean update() {
    int age = millis()-startTime;
    diameter = age*pixelPerMS;
    float radius = diameter/2;
    if (age>=lifeInMS) return false;
    //update spheres
    for (int i=0; i<controlBoards.length; i++) {  //draw board
      RS485LeonardoController oneBoard = controlBoards[i];
      if (oneBoard.onGround != onGround) continue;
      for (int j=0; j<oneBoard.spheres.length; j++) {
        float sphereDist = otherSphereDistace[i][j];
        float rippleDist = abs(sphereDist-radius);
        if (rippleDist<=effectDist) {
          oneBoard.spheres[j].effectValue+=map(rippleDist, 0, effectDist, effectStrength, 0);
        }
      }
    }

    return true;
  }

  void draw() {
    if (onGround) {
      stroke(198, 100, 100);
    } else {
      stroke(100, 100, 198);
    }
    ellipse(startX, startY, diameter, diameter);
    //println(startX, startY, diameter, diameter);
  }
}


class WaveEffectObject {
  int startTime;
  float startX, angle, currentX; 
  boolean onGround;
  int lifeInMS = 2000;
  float pixelPerMSonX = .8;
  float effectDist = 200;
  float effectStrength = 255;

  float otherSphereDistaceBeginning[][] = new float[controlBoardCount][];

  WaveEffectObject(float _x, float _angle, boolean _onGround) {
    startTime = millis();
    startX=_x;
    angle=_angle;
    onGround=_onGround;

    currentX=startX;

    for (int i=0; i<controlBoards.length; i++) {  //calculate distance
      RS485LeonardoController oneBoard = controlBoards[i];
      if (oneBoard.onGround != onGround) continue;
      otherSphereDistaceBeginning[i]=new float[oneBoard.spheres.length];
      for (int j=0; j<oneBoard.spheres.length; j++) {
        float xProjection = oneBoard.spheres[j].ypos*tan(HALF_PI-angle);
        float xDiff = oneBoard.spheres[j].xpos-xProjection-startX;
        otherSphereDistaceBeginning[i][j] = xDiff*sin(angle);
      }
    }
  }
  boolean update() {
    int age = millis()-startTime;
    float travelDistX = age * pixelPerMSonX;
    float travelDist = travelDistX*sin(angle);
    currentX = startX + travelDistX;

    if (age>=lifeInMS) return false;
    //update spheres
    for (int i=0; i<controlBoards.length; i++) {  
      RS485LeonardoController oneBoard = controlBoards[i];
      if (oneBoard.onGround != onGround) continue;
      for (int j=0; j<oneBoard.spheres.length; j++) {
        float waveDist = otherSphereDistaceBeginning[i][j]-travelDist;
        float waveDistAbs = abs(waveDist);
        if (waveDistAbs<=effectDist) {
          oneBoard.spheres[j].effectValue+=map(waveDistAbs, 0, effectDist, effectStrength, 0);
        }
      }
    }

    return true;
  }

  void draw() {
    if (onGround) {
      stroke(198, 100, 100);
    } else {
      stroke(100, 100, 198);
    }
    line (currentX, 0, currentX-height*tan(angle+HALF_PI), height);
    //ellipse(startX, startY, diameter, diameter);
    //println(startX, startY, diameter, diameter);
  }
}


class BreathEffectObject {
  int startTime;
  int lifeInMS = 2000;
  float effectStrength = 50;
  boolean onGround;

  BreathEffectObject(boolean _onGround) {
    startTime = millis();
    onGround=_onGround;
  }
  boolean update() {
    int age = millis()-startTime;

    float strength = effectStrength*(1-(abs(age-lifeInMS/2.0))/(lifeInMS/2.0));

    if (age>=lifeInMS) return false;
    //update spheres
    for (int i=0; i<controlBoards.length; i++) {  
      RS485LeonardoController oneBoard = controlBoards[i];
      if (oneBoard.onGround != onGround) continue;
      for (int j=0; j<oneBoard.spheres.length; j++) {
        oneBoard.spheres[j].effectValue+=strength;
      }
    }

    return true;
  }

  void draw() {
  }
}