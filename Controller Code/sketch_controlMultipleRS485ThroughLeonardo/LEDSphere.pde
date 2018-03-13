
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

  LEDSphere (int _id, float _xpos, float _ypos) {
    id=_id;
    xpos=_xpos;
    ypos=_ypos;
    fillcolor=color(0);
    needUpdateParameter=3;

    centerThreshold=1500;
  }

  void draw() {
    stroke(lost?64:255);
    fill(lost?0:fillcolor);
    ellipse(xpos, ypos, 100, 100);
    fill(255);
    text(id+" "+acceX+"\t"+acceY, xpos-50, ypos+70);
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
    fillcolorDim=color(red(fillcolor)/1, green(fillcolor)/1, blue(fillcolor)/1);
  }
}

