void draw_graph(int[] channelData, int x, int y, int w, int h, int minVal, int maxVal, color c, float stroke_width, int startPosition) {
  pushStyle();  
  stroke(c);
  strokeWeight(stroke_width);
  noFill();
  beginShape();
  int dataLength = channelData.length;
  for (int i=0; i<dataLength; i++) {
    float x_pos=map(i, 0, dataLength-1, x, x+w-1);
    float y_pos=map(channelData[startPosition], minVal, maxVal, y+h-1, y);
    vertex(x_pos, y_pos);
    startPosition++;
    if (startPosition>=dataLength) startPosition=0;
  }
  endShape();
  popStyle();
}



void draw_horizontalAcceleratrion(int x, int y, int w, int h, int fullScale, int xValue, int yValue) {
  pushStyle();  

  stroke(255, 255, 0);
  strokeWeight(3);
  int halfW = w/2, halfH=h/2;
  int horiCenterX = x+halfW, horiCenterY=y+halfH;
  line(horiCenterX, horiCenterY, horiCenterX+halfW*xValue/fullScale, horiCenterY+halfH*yValue/fullScale);

  popStyle();
}

class AxisData { 
  int dataAxis[];
  int value;
  int dataWritePtr;
  int axisEvenlopRate;
  int axisArrayLength;

  int axisEvenlopTop, axisEvenlopBtm;
  int axisDataEvenlopTopHis[];
  int axisDataEvenlopBtmHis[];
  AxisData (int _arrayLength, int _axisEvenlopRate) {  
    axisEvenlopRate=_axisEvenlopRate;
    axisArrayLength=_arrayLength;

    value=0;
    axisEvenlopTop=0;
    axisEvenlopBtm=0;

    dataWritePtr=0;

    dataAxis=new int[axisArrayLength];
    axisDataEvenlopTopHis=new int[axisArrayLength];
    axisDataEvenlopBtmHis=new int[axisArrayLength];
  }

  void addNewValue(int newValue) {
    value=newValue;
    dataAxis[dataWritePtr]=value;
    //calculateEvenlop
    axisEvenlopTop-=axisEvenlopRate;
    if (axisEvenlopTop<value) axisEvenlopTop=value;
    axisEvenlopBtm+=axisEvenlopRate;
    if (axisEvenlopBtm>value) axisEvenlopBtm=value;

    axisDataEvenlopTopHis[dataWritePtr]=axisEvenlopTop;
    axisDataEvenlopBtmHis[dataWritePtr]=axisEvenlopBtm;

    dataWritePtr++;
    if (dataWritePtr>=axisArrayLength) dataWritePtr=0;
  }

  void drawData(int x, int y, int w, int h, int minVal, int maxVal, color c, float stroke_width) {
    draw_graph(dataAxis, x, y, w, h, minVal, maxVal, c, stroke_width, dataWritePtr);
  }

  void drawEvenlop(int x, int y, int w, int h, int minVal, int maxVal, color c1, color c2, float stroke_width) {
    draw_graph(axisDataEvenlopTopHis, x, y, w, h, minVal, maxVal, c1, stroke_width, dataWritePtr);
    draw_graph(axisDataEvenlopBtmHis, x, y, w, h, minVal, maxVal, c2, stroke_width, dataWritePtr);
  }
} 


class HScrollbar {
  int swidth, sheight;    // width and height of bar
  float xpos, ypos;       // x and y position of bar
  float spos, newspos;    // x position of slider
  float sposMin, sposMax; // max and min values of slider
  int loose;              // how loose/heavy
  boolean over;           // is the mouse over the slider?
  boolean locked;
  float ratio;
  float mapMin, mapMax;
  String label;

  HScrollbar (float xp, float yp, int sw, int sh, int l, String _label, float mMin, float mMax) {
    swidth = sw;
    sheight = sh;
    int widthtoheight = sw - sh;
    ratio = (float)sw / (float)widthtoheight;
    xpos = xp;
    ypos = yp-sheight/2;
    spos = xpos + swidth/2 - sheight/2;
    newspos = spos;
    sposMin = xpos;
    sposMax = xpos + swidth - sheight;
    loose = l;
    mapMin = mMin; 
    mapMax = mMax;
    label = _label;
  }

  boolean update() {
    boolean changed = false;
    if (overEvent()) {
      over = true;
    } else {
      over = false;
    }
    if (mousePressed && over) {
      locked = true;
    }
    if (!mousePressed) {
      locked = false;
    }
    if (locked) {
      newspos = constrain(mouseX-sheight/2, sposMin, sposMax);
    }
    if (abs(newspos - spos) > 1) {
      spos = spos + (newspos-spos)/loose;
      changed=true;
    }
    return changed;
  }

  float constrain(float val, float minv, float maxv) {
    return min(max(val, minv), maxv);
  }

  boolean overEvent() {
    if (mouseX > xpos && mouseX < xpos+swidth &&
      mouseY > ypos && mouseY < ypos+sheight) {
      return true;
    } else {
      return false;
    }
  }

  void display() {
    noStroke();
    fill(204);
    rect(xpos, ypos, swidth, sheight);
    if (over || locked) {
      fill(0, 0, 0);
    } else {
      fill(102, 102, 102);
    }
    rect(spos, ypos, sheight, sheight);
    fill(255);
    text(((int)mapMin),xpos-28,ypos+12);
    text(((int)mapMax),xpos+swidth+3,ypos+12);
    text(label+": "+((int)getMapValue()),xpos+swidth+3+30,ypos+12);
  }

  float getPos() {
    // Convert spos to be values between
    // 0 and the total width of the scrollbar
    return spos * ratio;
  }

  float getMapValue() {
    return map(spos, sposMin, sposMax, mapMin, mapMax);
  }

  void setMapValue(float value) {
    spos = map(value, mapMin, mapMax, sposMin, sposMax);
    spos = constrain(spos, sposMin, sposMax);
    newspos = spos;
  }
}