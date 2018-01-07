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