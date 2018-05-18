int dimScale = 1;
class LEDSphere {
  int id;
  float xpos, ypos;       // x and y position of bar
  color fillcolor, fillcolorDim;
  int acceX, acceY, acceEvent;
  boolean lost;
  int needUpdateParameter;
  int envelopeRate = 32;
  int envelopeThreshold =768;
  int centerThreshold = 384;

  boolean changedEvent = false;

  int lastUpdated;

  LEDSphere (int _id, float _xpos, float _ypos) {
    id=_id;
    xpos=_xpos;
    ypos=_ypos;
    fillcolor=color(0);
    needUpdateParameter=3;
  }
  
  void update(){
    
  }

  void draw() {
    if (frameCount-lastUpdated>60) {
      lost=true;
    } else {
      lost=false;
    }

    stroke(lost?64:255);
    fill(lost?0:fillcolor);
    ellipse(xpos, ypos, 50, 50);
    fill(255);
    text(id+" "+acceX+"\t"+acceY, xpos-30, ypos+40);
  }

  void updateData(int _acceX, int _acceY, int _acceEvent) {
    acceX=_acceX;
    acceY=_acceY;
    if (acceEvent!=_acceEvent)changedEvent = true;
    acceEvent=_acceEvent;
    switch(_acceEvent) {
    case 0:
      fillcolor=color(64, 64, 64);  //stable
      break;
    case 1:
      fillcolor=color(0, 0, 192);   //tilt
      break;
    case 2:
      fillcolor=color(0, 192, 0);  //unstable
      break;
    }
    fillcolorDim=color(red(fillcolor)/dimScale, green(fillcolor)/dimScale, blue(fillcolor)/dimScale);

    lastUpdated=frameCount;
  }
}