
class LEDSphere {
  int id;
  float xpos, ypos;       // x and y position of bar
  color fillcolor;
  int acceX, acceY, acceEvent;


  LEDSphere (int _id, float _xpos, float _ypos) {
    id=_id;
    xpos=_xpos;
    ypos=_ypos;
    fillcolor=color(0);
  }

  void draw() {
    stroke(255);
    fill(fillcolor);
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
      fillcolor=color(64, 64, 64);  //stable
      break;
    case 1:
      fillcolor=color(0, 0, 192);   //tilt
      break;
    case 2:
      fillcolor=color(0, 192, 0);  //unstable
      break;
    }
  }
}