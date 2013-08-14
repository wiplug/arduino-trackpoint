#include "Trackpoint.h"

// Allows control of the mouse cursor on the connected computer, via a
// TrackPoint.

// Sensitivity can be controlled with a potentiometer.

// An RGB LED shows loop speed. It is controlled by a decade counter (mostly
// for the author's practise).

// Depends on the PS/2 library available on (as of August 2013):

// <http://playground.arduino.cc/componentLib/Ps2mouse> 

// 2013, Felix E. Klee <felix.klee@inka.de>

const char tpClkPin = 8; // tp = TrackPoint
const char tpDataPin = 9;
const char tpResetPin = 12;

const char potiSliderAnalogPin = 0;

const char decadeCounterClrPin = 4; //4017 CLR pin (reset)
const char decadeCounterClkPin = 5; //4017 CLK pin
char decadeCounterPos;

Trackpoint trackpoint(8, // CLK
                      9, // +DATA
                      12); // RESET

void clrDecadeCounter() {
  digitalWrite(decadeCounterClrPin, HIGH);
  digitalWrite(decadeCounterClrPin, LOW);
  decadeCounterPos = 0;
}

void incrementDecadeCounter() {
  digitalWrite(decadeCounterClkPin, HIGH);
  digitalWrite(decadeCounterClkPin, LOW);
  decadeCounterPos++;
}

void cycleRgbLed() {
  if (decadeCounterPos >= 3) {
    clrDecadeCounter();
  } else {
    incrementDecadeCounter();
  }
}

// errors are ignored
void setTpRamLocation(unsigned char location, unsigned char value) {
  trackpoint.write(0xe2);
  trackpoint.read(); // ACK
  trackpoint.write(0x81);
  trackpoint.read(); // ACK
  trackpoint.write(location);
  trackpoint.read(); // ACK
  trackpoint.write(value);
  trackpoint.read(); // ACK
}

// undefined in case of error
unsigned char tpRamLocation(unsigned char location) {
  trackpoint.write(0xe2);
  trackpoint.read(); // ACK
  trackpoint.write(0x80);
  trackpoint.read(); // ACK
  trackpoint.write(location);
  trackpoint.read(); // ACK
  return trackpoint.read();
}

void setupTrackpoint() {
  Mouse.begin();

  trackpoint.reset();
  trackpoint.setRemoteMode();

  cycleRgbLed(); // -> green
}

void setup() {
  pinMode(decadeCounterClkPin, OUTPUT);
  pinMode(decadeCounterClrPin, OUTPUT);
  clrDecadeCounter();

  setupTrackpoint();

  Serial.begin(9600);
}

// between 0 and 1
float potiPos() {
  return analogRead(potiSliderAnalogPin) / 1023.;
}

// Reads TrackPoint data and sends data to computer.
void loop() {
  static float oldPotiPos = -1;
  float newPotiPos = potiPos();

  cycleRgbLed(); // to see if program is still looping, or if it hangs

  Trackpoint::DataReport d = trackpoint.readData();

  Mouse.move(d.x, -d.y, 0);

  if (abs(newPotiPos - oldPotiPos) > 0.05) { // ignores small fluctuations
    trackpoint.setSensitivityFactor(0xff * potiPos());
    oldPotiPos = newPotiPos;
  }
}