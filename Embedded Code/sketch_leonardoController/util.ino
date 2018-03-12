
#define toHex(i) (((i) <= 9)?('0' +(i)):((i)+'@'-9))

static char *ucharToHex2(unsigned char data, char *s) {
  unsigned int d;
  d = data >> 4;
  *s++ = toHex(d);
  d = data & 0x0f;
  *s++ = toHex(d);
  *s = '\0';
  return s;
}

static char *ucharToHex2_no_end(unsigned char data, char *s) {
  unsigned int d;
  d = data >> 4;
  *s++ = toHex(d);
  d = data & 0x0f;
  *s++ = toHex(d);
  /**s = '\0';*/
  return s;
}

static char *uintToHex4_no_end(unsigned int data, char *s) {
  char d = data >> 8;
  s = ucharToHex2_no_end(d, s);
  d = data & 0xff;
  return ucharToHex2_no_end(d, s);
}

static char *uintToHex4(unsigned int data, char *s) {
  char d = data >> 8;
  s = ucharToHex2(d, s);
  d = data & 0xff;
  return ucharToHex2(d, s);
}

unsigned char hexToUchar(char s) {
  if (s >= '0' && s <= '9') {
    return (s - '0');
  }
  if (s >= 'A' && s <= 'F')  {
    return (s - 'A' + 10);
  }
  if (s >= 'a' && s <= 'f') {
    return (s - 'a' + 10);
  }
  return 0xff;
}

unsigned char hexToUchar2(char *s) {
  return (hexToUchar(*s) << 4) + hexToUchar(*(s + 1));
}

unsigned int hexToInt16(char *s) {
  return (hexToUchar2(s) << 8) + hexToUchar2(s + 2);
}


