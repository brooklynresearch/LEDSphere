int dimScale = 16;

int stableColor   = color(255, 255, 255);  
int tiltColor     = color(0, 0, 192); 
int unstableColor = color(0, 192, 0);  

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
      rect(xpos-20, ypos-20, 40, 40);  //increase performance
      //ellipse(xpos, ypos, 40, 40);
    } else {
      rect(xpos-18, ypos-18, 36, 36);
      //ellipse(xpos, ypos, 36, 36);
    }

    if (!lost) {
      float angle = atan2(acceY, acceX);
      float strength = sqrt(acceY*acceY+acceX*acceX);
      float halfPiStrength = 5000;
      float angleHalf = strength*HALF_PI/halfPiStrength;//!!!
      //float fullLength = onGround?40:36;
      //float lengthStrength = strength*fullLength/halfPiStrength;

      if (strength>256) {
        noFill();
        strokeWeight(6);
        stroke(128);
        //line(xpos, ypos,xpos+lengthStrength*cos(angle), ypos+lengthStrength*sin(angle));
        arc(xpos, ypos, 34, 34, angle-angleHalf, angle+angleHalf);
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
      fillcolor=stableColor;
      break;
    case 1:
      fillcolor=tiltColor;
      break;
    case 2:
      fillcolor=unstableColor;
      break;
    }
    fillcolorDim=color(red(fillcolor)/dimScale, green(fillcolor)/dimScale, blue(fillcolor)/dimScale);


    lastUpdated=frameCount;
  }
}