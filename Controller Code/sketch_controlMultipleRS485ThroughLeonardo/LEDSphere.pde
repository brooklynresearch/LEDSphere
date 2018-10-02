int dimScale = 16;  //larger number made light dimmer
boolean debug_Neverlost = false;

int stableEdgeColor   = color(255, 255, 255);  
int tiltEdgeColor     = color(0, 0, 192); 
int unstableEdgeColor = color(0, 192, 0);  

int sphereTopDrawOffsetX = 20;
int sphereTopDrawOffsetY = -40;
int sphereBottomDrawOffsetX = -20;
int sphereBottomDrawOffsetY = 0;

class LEDSphere {
  int id;
  float xpos, ypos;       // x and y position of bar
  float drawXPos, drawYPos;

  color fillcolor, fillcolorDim;
  int acceX, acceY, acceEvent;
  boolean lost;
  int needUpdateParameter;
  int envelopeRate = 32;
  int envelopeThreshold =768;
  int centerThreshold = 384;

  boolean changedEvent = false;
  int eventChangeMillis = 0;
  int tiltAccumulate = 0;
  int tiltAccumulateOnLastChange = 0;
  boolean onGround = false;

  int effectValue = 0;  //this is used by effect

  int lastUpdated;

  LEDSphere (int _id, float _xpos, float _ypos, boolean _onGround) {
    id=_id;
    onGround=_onGround;
    xpos=_xpos;
    ypos=_ypos;
    fillcolor=color(0);
    needUpdateParameter=3;

    if (!onGround) {
      drawXPos=xpos+sphereTopDrawOffsetX;
      drawYPos=ypos+sphereTopDrawOffsetY;
    } else {
      drawXPos=xpos+sphereBottomDrawOffsetX;
      drawYPos=ypos+sphereBottomDrawOffsetY;
    }
  }

  void update() {
  }

  void draw() {
    if (frameCount-lastUpdated>60 && (!debug_Neverlost)) {
      lost=true;
    } else {
      lost=false;
    }

    if (lost) {
      stroke(64);
    } else {
      switch(acceEvent) {
      case 0:
        stroke(stableEdgeColor);
        break;
      case 1:
        stroke(tiltEdgeColor);
        break;
      case 2:
        stroke(unstableEdgeColor);
        break;
      default:
        stroke(stableEdgeColor);
        break;
      }
    }


    fill(lost?0:fillcolor);
    strokeWeight(1);
    if (onGround) {
      rect(drawXPos-20, drawYPos-20, 40, 40);  //increase performance
    } else {
      rect(drawXPos-18, drawYPos-18, 36, 36);
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
        arc(drawXPos, drawYPos, 34, 34, angle-angleHalf, angle+angleHalf);
        strokeWeight(1);
      }
    }

    if ((mouseX>=drawXPos-20) && (mouseX<=drawXPos+20) && (mouseY>=drawYPos-20) && (mouseY<=drawYPos+20)) {
      fill(255);
      text(id+" "+acceX+"\t"+acceY, drawXPos-20+3, drawYPos+32);
    }
  }

  void updateData(int _acceX, int _acceY, int _acceEvent) {
    acceX=_acceX;
    acceY=_acceY;
    if (acceEvent!=_acceEvent) {
      changedEvent = true;
      eventChangeMillis=millis();
      tiltAccumulateOnLastChange=tiltAccumulate;
    }
    acceEvent=_acceEvent;

    lastUpdated=frameCount;
  }
}