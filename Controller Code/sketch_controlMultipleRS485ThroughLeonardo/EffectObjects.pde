int colorIdle = color(255, 255, 255);
int colorMaxEffect = color(255, 0, 0);
int maxEffectValue = 255;

class EffectObjects {
  ArrayList<RippleEffectObject> ripples = new ArrayList<RippleEffectObject>();
  int ripplesLimit = 10;
  EffectObjects() {
  }


  void update() {
    int i=0;

    for (RS485LeonardoController oneBoard : controlBoards) {
      for (LEDSphere oneSphere : oneBoard.spheres) {
        oneSphere.effectValue=0;
      }
    }

    while (i < ripples.size()) {
      if (ripples.get(i).update()) {
        i++;
      } else {
        ripples.remove(i);
      }
    }

    for (RS485LeonardoController oneBoard : controlBoards) {
      for (LEDSphere oneSphere : oneBoard.spheres) {
        if (oneSphere.effectValue==0) {
          oneSphere.fillcolor=colorIdle;
        } else {
          oneSphere.fillcolor=lerpColor(colorIdle, colorMaxEffect, (float)oneSphere.effectValue/maxEffectValue);
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
  }

  void addRipple(float _x, float _y, boolean _onGround) {
    if (ripples.size()<ripplesLimit) {
      ripples.add(new RippleEffectObject(_x, _y, _onGround));
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