
class LEDSphere {
  int id;
  float xpos, ypos;       // x and y position of bar
  color fillcolor,fillcolorDim;
  int acceX, acceY, acceEvent;
  int timeLost,timeoutLimit;
  boolean lost;
  boolean rippler;
  boolean rippleFirstWave;
  boolean rippleSecondWave;
  int needUpdateParameter;
  //int envelopeRate = 32;
  int envelopeRate = 50;
  //int envelopeThreshold = 768;
  int envelopeThreshold = 700;
  //int centerThreshold = 384;
  int centerThreshold = 3840;
  int rColor;
  int gColor;
  int bColor;
  int rate;
  int rRate;
  int gRate;
  int bRate;
  //int MAX_RED = 190;
  int MAX_RED = 255;
  int MIN_RED = 64;
  //int MAX_GRN = 225;
  //int MAX_GRN = 160;k
  int MAX_GRN = 255;
  //int MIN_GRN = 40;
  int MIN_GRN = 64;
  //int MAX_BLU = 245;
  //int MAX_BLU = 160;
  int MAX_BLU = 255;
  //int MIN_BLU = 40;
  int MIN_BLU = 64;
  int tiltedTimer;
  int tiltedFrameRate;
  int rippleIndex;
  int rippleIndexFirst;
  int rippleIndexSecond;
  //int rippleWave[] = {255,245,218,176,128,79,37,10,0,10,37,79,128,176,218,245};
  int rippleWave[] = {255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255 };
  int [][] rippleColorWave = {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},
                              {0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}};
  int fadeOutIndex = 0;
  int fadeOut[] = {1, 2, 3, 4, 7, 12, 15, 15, 15, 15, 15, 15, 32, 32, 32, 32};
  int [][] fadeColorOut = {{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},
                              {0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}};

  LEDSphere (int _id, float _xpos, float _ypos) {
    id=_id;
    xpos=_xpos;
    ypos=_ypos;
    fillcolor=color(0);
    lost=false;
    timeoutLimit=100;
    needUpdateParameter=3;
    tiltedTimer = 0;
    tiltedFrameRate = 1;
    rate = 10;
    rRate = 10;
    gRate = 10;
    bRate = 10;
    rippler = false;
    rippleFirstWave = false;
    rippleSecondWave = false;
    rippleIndex = 0;
    rColor = 64;
    gColor = 64;
    bColor = 64;
    
    for(int i=0; i<16; i++){
      //rippleColorWave[i][0] = int(rippleWave[i] * 0.75);
      //rippleColorWave[i][1] = int(rippleWave[i] * 0.88);
      //rippleColorWave[i][2] = int(rippleWave[i] * 0.96);
      rippleColorWave[i][0] = int(rippleWave[i]);
      fadeColorOut[i][0] = int(fadeOut[i]);
      rippleColorWave[i][1] = int(rippleWave[i] * 0.62);
      //fadeColorOut[i][1] = int(fadeOut[i] * 0.62);
      fadeColorOut[i][1] = int(fadeOut[i]);
      rippleColorWave[i][2] = int(rippleWave[i] * 0.62);
      //fadeColorOut[i][2] = int(fadeOut[i] * 0.62
      fadeColorOut[i][2] = int(fadeOut[i]);
    }
    //centerThreshold = 1500;
    centerThreshold= 2000;
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
    acceEvent=_acceEvent;
    switch(_acceEvent) {
    case 0:
      
      if(rippleFirstWave){
        rColor = rippleColorWave[rippleIndexFirst][0] - 50;
        bColor = rippleColorWave[rippleIndexFirst][1] - 30;
        gColor = rippleColorWave[rippleIndexFirst][2] - 30;
        if(rColor<=0){rColor = 0;}
        if(gColor<=0){gColor = 0;}
        if(bColor<=0){bColor = 0;}
        fillcolor=color(rColor, gColor, gColor);
        rippleIndex = (rippleIndex + 1)%16;
      } else if (rippleSecondWave){
        rColor = rippleColorWave[rippleIndexSecond][0] - 75;
        bColor = rippleColorWave[rippleIndexSecond][1] - 50;
        gColor = rippleColorWave[rippleIndexSecond][2] - 50;
        if(rColor<=0){rColor = 0;}
        if(gColor<=0){gColor = 0;}
        if(bColor<=0){bColor = 0;}
        fillcolor=color(rColor, gColor, gColor);
        rippleIndex = (rippleIndex + 1)%16;
      } else {
        rippleIndex = 0;
        rippleIndexFirst = 2;
        rippleIndexSecond = 4;
        
        if(rColor <= (MIN_RED - rRate)){
          rRate = 0;
          rColor = MIN_RED;
        } else {
          rRate = -fadeColorOut[fadeOutIndex][0];
        }
        
        if(gColor <= (MIN_GRN - gRate)){
          gRate = 0;
          gColor = MIN_GRN;
        } else {
          gRate = -fadeColorOut[fadeOutIndex][1];
        }  
        
        if(bColor <= (MIN_BLU - bRate)){
          bRate = 0;
          bColor = MIN_BLU;
        } else {
          bRate = -fadeColorOut[fadeOutIndex][2];
        }
        
        rColor += rRate;
        gColor += gRate;
        bColor += bRate;
        fadeOutIndex = (fadeOutIndex + 1)%16;
        //fillcolor = color(190, 225, 245);
        //fillcolor = color(128, 75, 75);
        //fillcolor = color(200, 120, 120);
        //fillcolor = color(255, 155, 155);
        fillcolor = color(rColor, gColor, bColor);  //stable
      }
      break;
    case 1:
      fadeOutIndex = 0;
      if(millis() - tiltedTimer > tiltedFrameRate){
        rColor += rRate;
        bColor += bRate;
        gColor += gRate;
        
        if(rColor >= (MAX_RED - rRate)){
          rRate = 0;
          rColor = MAX_RED;
        } else {
          rRate = 20;
        }
        
        if(gColor >= (MAX_GRN - gRate)){
          gRate = 0;
          gColor = MAX_GRN;
        } else {
          gRate = 12;
        }  
        
        if(bColor >= (MAX_BLU - bRate)){
          bRate = 0;
          bColor = MAX_BLU;
        } else {
          bRate = 12;
        }
        
        
        tiltedTimer = millis();
      }
      fillcolor=color(rColor, gColor, bColor);
      //fillcolor=color(0, 0, 192);   //tilt
      break;
    case 2:
      fadeOutIndex = 0;
      rColor = rippleColorWave[rippleIndex][0];
      bColor = rippleColorWave[rippleIndex][1];
      gColor = rippleColorWave[rippleIndex][2];
      fillcolor=color(rColor, gColor, gColor);
      rippleIndex = (rippleIndex + 1)%16;
      //println(rippleWave[rippleIndex]);
      //fillcolor=color(0, 192, 0);  //unstable
      break;
    case 3:
      fadeOutIndex = 0;
      rColor = MAX_RED;
      gColor = MAX_GRN;
      bColor = MAX_BLU;
      fillcolor=color(rColor, gColor, bColor);
      break;
    }
    fillcolorDim=fillcolor;
    //fillcolorDim=color(red(fillcolor)/1,green(fillcolor)/1,blue(fillcolor)/1);
  }
}