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
        //if ()
        //oneSphere.effectValue=0;
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
  int lifeInMS = 2000;
  float pixelPerMS = .8;
  float diameter = 0;
  RippleEffectObject(float _x, float _y, boolean _onGround) {
    startTime = millis();
    startX=_x;
    startY=_y;
    onGround=_onGround;
  }
  boolean update() {
    int age = millis()-startTime;
    diameter = age*pixelPerMS;
    if (age>=lifeInMS) return false;
    //update spheres

    return true;
  }

  void draw() {
    if (onGround) {
      stroke(198, 100, 100);
    } else {
      stroke(100, 198, 100);
    }
    ellipse(startX, startY, diameter, diameter);
    println(startX, startY, diameter, diameter);
  }
}