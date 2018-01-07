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