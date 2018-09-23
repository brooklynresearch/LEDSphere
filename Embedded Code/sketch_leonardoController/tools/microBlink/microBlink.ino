#include <avr/wdt.h>
int RXLED = 17;

void setup()
{
  pinMode(RXLED, OUTPUT);  // Set RX LED as an output
  // TX LED is set as an output behind the scenes

  Serial.begin(9600); //This pipes to the serial monitor
  Serial1.begin(9600); //This is the UART, pipes to sensors attached to board

  //wdt_enable(WDTO_8S);
}

void loop()
{
  Serial.println("Hello world");  // Print "Hello World" to the Serial Monitor
  Serial1.println("Hello!");  // Print "Hello!" over hardware UART

  digitalWrite(RXLED, LOW);   // set the LED on
  TXLED0; //TX LED is not tied to a normally controlled pin
  delay(100);              // wait for a second
  digitalWrite(RXLED, HIGH);    // set the LED off
  TXLED1;
  delay(100);              // wait for a second
}
