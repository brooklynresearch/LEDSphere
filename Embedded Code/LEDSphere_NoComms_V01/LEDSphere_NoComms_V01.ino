/*
 * LED Sphere - Without Communcations 
 * Author: Ezer Longinus
 * Date: Dec 2017
 * Version: 1.0
 * 
 * Version 1.0: This code controls a single NeoPixel LED Ring through the readings of the accelerometer.
 * 
 */

 #define VERSION "1.0"

#include <Adafruit_NeoPixel.h>
#include <Wire.h>
#include <SPI.h>
#include <Adafruit_LIS3DH.h>
#include <Adafruit_Sensor.h>

#ifdef __AVR__
  #include <avr/power.h>
#endif
 
//----------- ACCELEROMETER ----------------------//
Adafruit_LIS3DH lis = Adafruit_LIS3DH();

//Setting global values for when a "trigger/tilt" occurs
float TRIGGER_MIN_X, TRIGGER_MAX_X, TRIGGER_MIN_Y, TRIGGER_MAX_Y;
//Setting global values for when the accelerometer has settled back to it's default position.
float DEFAULT_MIN_X, DEFAULT_MAX_X, DEFAULT_MIN_Y, DEFAULT_MAX_Y;

//Defines how many readings we average from the accelerometer
#define ACC_READINGS    10

float averageX, averageY;

//This modifier is to determine how far from the inital reading will 
//we need to go before determining we have triggered an event.
#define TRIGGER_MODIFIER  3.0
//This modifier is to determine how close to the initial reading will
//we need to go before entering back into the default state.
#define DEFAULT_MODIFIER  0.2
//-----------------------------------------------//


//----------- NEO-PIXEL RING --------------------//
#define PIN             6
#define NUM_LEDS        12
#define BRIGHTNESS      255

Adafruit_NeoPixel ring = Adafruit_NeoPixel(NUM_LEDS, PIN, NEO_GRBW + NEO_KHZ800);
//-----------------------------------------------//


//----------- COLOR GLOBALS --------------------//
uint32_t prevColor = 0;
uint32_t currentColor = 0;

//Color Init.
uint8_t currentRed = 255;
uint8_t currentGrn = 255;
uint8_t currentBlu = 255;
uint8_t currentWht = 128;

int colorModifier = 1;
//-----------------------------------------------//


//----------- TIMING GLOBALS --------------------//
//Track the current time for LED timing
uint32_t currentTime = 0;

//Track the 
uint32_t switchTime = 0;
uint16_t switchThresh = 500;

//How fast are we updating the LED colors
uint8_t breathFrameRate =   10;
uint8_t interuptFrameRate = 200;
#define MAX_INTERUPT_FRAMES 255

uint16_t totalFrames = 360;
uint16_t currentFrame = 0;
//-----------------------------------------------//


//---------- ANIMATION STATES -------------------//
boolean breathState = true;
boolean armInteruptState = false;
boolean interuptState = false;
//-----------------------------------------------//


void setup() {
  Serial.begin(9600);
    
  ring.setBrightness(BRIGHTNESS);
  ring.begin();
  ring.show(); // Initialize all pixels to 'off'

  currentTime = millis();

  if (! lis.begin(0x18)) {   // change this to 0x19 for alternative i2c address
    Serial.println("Couldnt start");
    while (1);
  }
  
  lis.setRange(LIS3DH_RANGE_2_G);   // 2, 4, 8 or 16 G!

  getAccelAverages();

  //Set Min and Max Values for the trigger and default values
  getMinMaxValues();


  Serial.println("===================================");
  Serial.println("LED SPHERE TEST - NO COMMS");
  Serial.print("VERSION: ");Serial.println(VERSION);
  Serial.println("LIS3DH found!");
  Serial.print("Range = "); Serial.print(2 << lis.getRange());  
  Serial.println("G");
  Serial.print("X: ");Serial.print(TRIGGER_MIN_X);Serial.print("\t");Serial.print(TRIGGER_MAX_X);Serial.print("\t");Serial.print(DEFAULT_MIN_X);Serial.print("\t");Serial.println(DEFAULT_MAX_X);
  Serial.print("Y: ");Serial.print(TRIGGER_MIN_Y);Serial.print("\t");Serial.print(TRIGGER_MAX_Y);Serial.print("\t");Serial.print(DEFAULT_MIN_Y);Serial.print("\t");Serial.println(DEFAULT_MAX_Y);  
  Serial.println("===================================");
}

void loop() {

  getAccelAverages();


  //DEFAULT STATE
  if((millis() - currentTime > breathFrameRate)&&(breathState)){
    currentFrame = 0;
    if(currentRed >= 255){
      colorModifier = -1;
    } else if(currentRed <= 0){
      colorModifier = 1;
    }
    currentRed += colorModifier;
    currentBlu += colorModifier;
    currentColor = ring.Color(currentRed, currentGrn, currentBlu, currentWht);
    setColor(currentColor);
    currentTime = millis();
  }

  //SPHERE "IS TILTING" STATE
  if((millis() - switchTime > switchThresh)&&
    ((averageX < TRIGGER_MIN_X)||(averageX > TRIGGER_MAX_X)||
     (averageY < TRIGGER_MIN_Y)||(averageY > TRIGGER_MAX_Y))){
        setColor(ring.Color(0,255,0,0)); 
        armInteruptState = true;
        breathState = false;   
    } else if((armInteruptState)&&
      ((averageX > DEFAULT_MIN_X)&&(averageX < DEFAULT_MAX_X)&&
      (averageY > DEFAULT_MIN_Y)&&(averageY < DEFAULT_MAX_Y))) {
      
      currentRed = 0; currentGrn = 255; currentBlu = 0; currentWht = 0;
      
      interuptState = true;
      armInteruptState = false;
      switchTime = millis();
    }

  //RETURN SPHERE TO DEFAULT STATE ANIMATION
  if(interuptState){
      if((micros() - currentTime > interuptFrameRate)&&(currentFrame < MAX_INTERUPT_FRAMES)){
        currentFrame++;
        if(currentRed >= 255){
          colorModifier = 0;
        } else {
          colorModifier = 1;
        }
        currentRed += colorModifier;
        currentBlu += colorModifier;
        currentWht += colorModifier;
        currentColor = ring.Color(currentRed,currentGrn,currentBlu,(currentWht/2));
        setColor(currentColor);
        currentTime = micros();
      } else if(currentFrame >= MAX_INTERUPT_FRAMES) {
        currentRed = 255; currentGrn = 255; currentBlu = 255; currentWht = 128;
        interuptState = false;
        breathState = true;
      }
  }
}

void getMinMaxValues(){
  TRIGGER_MIN_X = averageX - TRIGGER_MODIFIER;
  TRIGGER_MAX_X = averageX + TRIGGER_MODIFIER;
  TRIGGER_MIN_Y = averageY - TRIGGER_MODIFIER;
  TRIGGER_MAX_Y = averageY + TRIGGER_MODIFIER;
  DEFAULT_MIN_X = averageX - DEFAULT_MODIFIER;
  DEFAULT_MAX_X = averageX + DEFAULT_MODIFIER;
  DEFAULT_MIN_Y = averageY - DEFAULT_MODIFIER;
  DEFAULT_MAX_Y = averageY + DEFAULT_MODIFIER;
}

void getAccelAverages(){
  sensors_event_t event; 
  lis.getEvent(&event);  
  
  for(int i=0; i<ACC_READINGS; i++){
    averageX += event.acceleration.x;
    averageY += event.acceleration.y;
  } 
  averageX /= ACC_READINGS;
  averageY /= ACC_READINGS;
}

void setColor(uint32_t c){
  for(uint16_t i=0; i<ring.numPixels(); i++){
    ring.setPixelColor(i,c);
  }
  ring.show();
}

// Returns the Red component of a 32-bit color
uint8_t Red(uint32_t color)
{
    return (color >> 24) & 0xFF;
}

// Returns the Green component of a 32-bit color
uint8_t Green(uint32_t color)
{
    return (color >> 16) & 0xFF;
}

// Returns the Blue component of a 32-bit color
uint8_t Blue(uint32_t color)
{
    return (color >> 8) & 0xFF;
}

// Returns the White component of a 32-bit color
uint8_t White(uint32_t color)
{
    return color & 0xFF;
}





