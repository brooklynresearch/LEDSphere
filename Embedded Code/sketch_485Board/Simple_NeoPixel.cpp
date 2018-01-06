#include "Simple_NeoPixel.h"

// Constructor when length, pin and type are known at compile-time:
Simple_NeoPixel::Simple_NeoPixel(uint8_t p, neoPixelType t) :
  endTime(0), begun(false)
{
  numLEDs = NUMPIXELS;
  updateType(t);
  setPin(p);
}

Simple_NeoPixel::~Simple_NeoPixel() {
  if (pin >= 0) pinMode(pin, INPUT);
}

void Simple_NeoPixel::begin(void) {
  if (pin >= 0) {
    pinMode(pin, OUTPUT);
    digitalWrite(pin, LOW);
  }
  begun = true;
}

void Simple_NeoPixel::updateType(neoPixelType t) {
  boolean oldThreeBytesPerPixel = (wOffset == rOffset); // false if RGBW

  wOffset = (t >> 6) & 0b11; // See notes in header file
  rOffset = (t >> 4) & 0b11; // regarding R/G/B/W offsets
  gOffset = (t >> 2) & 0b11;
  bOffset =  t       & 0b11;

  boolean newThreeBytesPerPixel = (wOffset == rOffset);
  numBytes = numLEDs * ((wOffset == rOffset) ? 3 : 4);
}
void Simple_NeoPixel::show(void) {
  // Data latch = 50+ microsecond pause in the output stream.  Rather than
  // put a delay at the end of the function, the ending time is noted and
  // the function will simply hold off (if needed) on issuing the
  // subsequent round of data until the latch time has elapsed.  This
  // allows the mainline code to start generating the next frame of data
  // rather than stalling for the latch.
  while (!canShow());
  // endTime is a private member (rather than global var) so that mutliple
  // instances on different pins can be quickly issued in succession (each
  // instance doesn't delay the next).

  // In order to make this code runtime-configurable to work with any pin,
  // SBI/CBI instructions are eschewed in favor of full PORT writes via the
  // OUT or ST instructions.  It relies on two facts: that peripheral
  // functions (such as PWM) take precedence on output pins, so our PORT-
  // wide writes won't interfere, and that interrupts are globally disabled
  // while data is being issued to the LEDs, so no other code will be
  // accessing the PORT.  The code takes an initial 'snapshot' of the PORT
  // state, computes 'pin high' and 'pin low' values, and writes these back
  // to the PORT register as needed.

  noInterrupts(); // Need 100% focus on instruction timing


#ifdef __AVR__
  // AVR MCUs -- ATmega & ATtiny (no XMEGA) ---------------------------------

  volatile uint16_t
  i   = numBytes; // Loop counter
  volatile uint8_t
  *ptr = pixels,   // Pointer to next byte
   b   = *ptr++,   // Current byte value
   hi,             // PORT w/output bit set high
   lo;             // PORT w/output bit set low

  // Hand-tuned assembly code issues data to the LED drivers at a specific
  // rate.  There's separate code for different CPU speeds (8, 12, 16 MHz)
  // for both the WS2811 (400 KHz) and WS2812 (800 KHz) drivers.  The
  // datastream timing for the LED drivers allows a little wiggle room each
  // way (listed in the datasheets), so the conditions for compiling each
  // case are set up for a range of frequencies rather than just the exact
  // 8, 12 or 16 MHz values, permitting use with some close-but-not-spot-on
  // devices (e.g. 16.5 MHz DigiSpark).  The ranges were arrived at based
  // on the datasheet figures and have not been extensively tested outside
  // the canonical 8/12/16 MHz speeds; there's no guarantee these will work
  // close to the extremes (or possibly they could be pushed further).
  // Keep in mind only one CPU speed case actually gets compiled; the
  // resulting program isn't as massive as it might look from source here.

  
  // 16 MHz(ish) AVR --------------------------------------------------------
#if (F_CPU >= 15400000UL) && (F_CPU <= 19000000L)



    // WS2811 and WS2812 have different hi/lo duty cycles; this is
    // similar but NOT an exact copy of the prior 400-on-8 code.

    // 20 inst. clocks per bit: HHHHHxxxxxxxxLLLLLLL
    // ST instructions:         ^   ^        ^       (T=0,5,13)

    volatile uint8_t next, bit;

    hi   = *port |  pinMask;
    lo   = *port & ~pinMask;
    next = lo;
    bit  = 8;

    asm volatile(
      "head20:"                   "\n\t" // Clk  Pseudocode    (T =  0)
      "st   %a[port],  %[hi]"    "\n\t" // 2    PORT = hi     (T =  2)
      "sbrc %[byte],  7"         "\n\t" // 1-2  if(b & 128)
      "mov  %[next], %[hi]"     "\n\t" // 0-1   next = hi    (T =  4)
      "dec  %[bit]"              "\n\t" // 1    bit--         (T =  5)
      "st   %a[port],  %[next]"  "\n\t" // 2    PORT = next   (T =  7)
      "mov  %[next] ,  %[lo]"    "\n\t" // 1    next = lo     (T =  8)
      "breq nextbyte20"          "\n\t" // 1-2  if(bit == 0) (from dec above)
      "rol  %[byte]"             "\n\t" // 1    b <<= 1       (T = 10)
      "rjmp .+0"                 "\n\t" // 2    nop nop       (T = 12)
      "nop"                      "\n\t" // 1    nop           (T = 13)
      "st   %a[port],  %[lo]"    "\n\t" // 2    PORT = lo     (T = 15)
      "nop"                      "\n\t" // 1    nop           (T = 16)
      "rjmp .+0"                 "\n\t" // 2    nop nop       (T = 18)
      "rjmp head20"              "\n\t" // 2    -> head20 (next bit out)
      "nextbyte20:"               "\n\t" //                    (T = 10)
      "ldi  %[bit]  ,  8"        "\n\t" // 1    bit = 8       (T = 11)
      "ld   %[byte] ,  %a[ptr]+" "\n\t" // 2    b = *ptr++    (T = 13)
      "st   %a[port], %[lo]"     "\n\t" // 2    PORT = lo     (T = 15)
      "nop"                      "\n\t" // 1    nop           (T = 16)
      "sbiw %[count], 1"         "\n\t" // 2    i--           (T = 18)
      "brne head20"             "\n"   // 2    if(i != 0) -> (next byte)
      : [port]  "+e" (port),
      [byte]  "+r" (b),
      [bit]   "+r" (bit),
      [next]  "+r" (next),
      [count] "+w" (i)
      : [ptr]    "e" (ptr),
      [hi]     "r" (hi),
      [lo]     "r" (lo));
#else
#error "CPU SPEED NOT SUPPORTED"
#endif // end F_CPU ifdefs on __AVR__

  // END AVR ----------------------------------------------------------------
#endif // ESP8266


  // END ARCHITECTURE SELECT ------------------------------------------------


  interrupts();
  endTime = micros(); // Save EOD time for latch on next call
}

// Set the output pin number
void Simple_NeoPixel::setPin(uint8_t p) {
  if (begun && (pin >= 0)) pinMode(pin, INPUT);
  if (p >= 0) {
    pin = p;
    if (begun) {
      pinMode(p, OUTPUT);
      digitalWrite(p, LOW);
    }
#ifdef __AVR__
    port    = portOutputRegister(digitalPinToPort(p));
    pinMask = digitalPinToBitMask(p);
#endif
  }
}

// Set pixel color from separate R,G,B components:
void Simple_NeoPixel::setPixelColor(
  uint16_t n, uint8_t r, uint8_t g, uint8_t b) {

  if (n < numLEDs) {
    uint8_t *p;
    if (wOffset == rOffset) { // Is an RGB-type strip
      p = &pixels[n * 3];    // 3 bytes per pixel
    } else {                 // Is a WRGB-type strip
      p = &pixels[n * 4];    // 4 bytes per pixel
      p[wOffset] = 0;        // But only R,G,B passed -- set W to 0
    }
    p[rOffset] = r;          // R,G,B always stored
    p[gOffset] = g;
    p[bOffset] = b;
  }
}

void Simple_NeoPixel::setPixelColor(
  uint16_t n, uint8_t r, uint8_t g, uint8_t b, uint8_t w) {

  if (n < numLEDs) {
    uint8_t *p;
    if (wOffset == rOffset) { // Is an RGB-type strip
      p = &pixels[n * 3];    // 3 bytes per pixel (ignore W)
    } else {                 // Is a WRGB-type strip
      p = &pixels[n * 4];    // 4 bytes per pixel
      p[wOffset] = w;        // Store W
    }
    p[rOffset] = r;          // Store R,G,B
    p[gOffset] = g;
    p[bOffset] = b;
  }
}

// Set pixel color from 'packed' 32-bit RGB color:
void Simple_NeoPixel::setPixelColor(uint16_t n, uint32_t c) {
  if (n < numLEDs) {
    uint8_t *p,
            r = (uint8_t)(c >> 16),
            g = (uint8_t)(c >>  8),
            b = (uint8_t)c;
    if (wOffset == rOffset) {
      p = &pixels[n * 3];
    } else {
      p = &pixels[n * 4];
      uint8_t w = (uint8_t)(c >> 24);
      p[wOffset] = w;
    }
    p[rOffset] = r;
    p[gOffset] = g;
    p[bOffset] = b;
  }
}

// Convert separate R,G,B into packed 32-bit RGB color.
// Packed format is always RGB, regardless of LED strand color order.
uint32_t Simple_NeoPixel::Color(uint8_t r, uint8_t g, uint8_t b) {
  return ((uint32_t)r << 16) | ((uint32_t)g <<  8) | b;
}

// Convert separate R,G,B,W into packed 32-bit WRGB color.
// Packed format is always WRGB, regardless of LED strand color order.
uint32_t Simple_NeoPixel::Color(uint8_t r, uint8_t g, uint8_t b, uint8_t w) {
  return ((uint32_t)w << 24) | ((uint32_t)r << 16) | ((uint32_t)g <<  8) | b;
}

// Query color from previously-set pixel (returns packed 32-bit RGB value)
uint32_t Simple_NeoPixel::getPixelColor(uint16_t n) const {
  if (n >= numLEDs) return 0; // Out of bounds, return no color.

  uint8_t *p;

  if (wOffset == rOffset) { // Is RGB-type device
    p = &pixels[n * 3];

    // No brightness adjustment has been made -- return 'raw' color
    return ((uint32_t)p[rOffset] << 16) |
           ((uint32_t)p[gOffset] <<  8) |
           (uint32_t)p[bOffset];

  } else {                 // Is RGBW-type device
    p = &pixels[n * 4];

    return ((uint32_t)p[wOffset] << 24) |
           ((uint32_t)p[rOffset] << 16) |
           ((uint32_t)p[gOffset] <<  8) |
           (uint32_t)p[bOffset];

  }
}

// Returns pointer to pixels[] array.  Pixel data is stored in device-
// native format and is not translated here.  Application will need to be
// aware of specific pixel data format and handle colors appropriately.
uint8_t *Simple_NeoPixel::getPixels(void) const {
  return pixels;
}

uint16_t Simple_NeoPixel::numPixels(void) const {
  return numLEDs;
}

void Simple_NeoPixel::clear() {
  memset(pixels, 0, numBytes);
}
