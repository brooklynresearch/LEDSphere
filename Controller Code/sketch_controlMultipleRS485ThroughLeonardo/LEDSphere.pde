int dimScale = 16;
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
  boolean onGround = false;

  int lastUpdated;

  LEDSphere (int _id, float _xpos, float _ypos, boolean _onGround) {
    id=_id;
    onGround=_onGround;
    xpos=_xpos;
    ypos=_ypos;
    fillcolor=color(0);
    needUpdateParameter=3;
  }

  void update() {
  }

  void draw() {
    if (frameCount-lastUpdated>60) {
      lost=true;
    } else {
      lost=false;
    }

    stroke(lost?64:255);
    fill(lost?0:fillcolor);
    if (onGround) {
      ellipse(xpos, ypos, 40, 40);
    } else {
      ellipse(xpos, ypos, 36, 36);
    }
    if (!lost) {
      float angle = atan2(acceY, acceX);
      float strength = sqrt(acceY*acceY+acceX*acceX);
      float halfPiStrength = 5000;
      float angleHalf = strength*HALF_PI/halfPiStrength;

      if (strength>256) {
        noFill();
        strokeWeight(6);
        stroke(128);
        arc(xpos, ypos, 44, 44, angle-angleHalf, angle+angleHalf);
        strokeWeight(1);
      }
    }

    if ((mouseX>=xpos-20) && (mouseX<=xpos+20) && (mouseY>=ypos-20) && (mouseY<=ypos+20)) {
      fill(255);
      text(id+" "+acceX+"\t"+acceY, xpos-20, ypos+32);
    }
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