/*
Color Organ Arduino Serial

Gets amplitude information from a color organ calculator object, 
then sends the amplitudes via serial to an Arduino, which controls
attached lights to make a sound-reactive light display.

Copyright (C) 2013 Douglas A. Telfer

This source code is released simultaneously under the GNU GPL v2 
and the Mozilla Public License, v. 2.0; derived works may use 
either license, a compatible license, or both licenses as suits 
the needs of the derived work.

Additional licensing terms may be available; contact the author
with your proposal.

*** GNU General Public License, version 2 notice:

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

*** Mozilla Public License, v. 2.0 notice:

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/
*/

import processing.serial.*;

// Sound Input and processing objects
Serial myPort;
ColorOrganCalculator coc;

// Color state
float[] amplitudes;
float[] lastAmplitudes;
byte[]  amps;
int posOffset = 0;
byte rr;
byte gg;
byte bb;

// Communications
boolean inputReady=false;
long lastUpdate;
char lastResponse;
char deviceState;

long[] colorIndex = { 
  0xff0000, 0xff0000, 0xff0000, 0xffff00, 0x00ff00, 0x00ff00, 
  0x00ff00, 0x0000ff, 0x0000ff, 0x8000ff, 0xff00ff, 0xff00ff
}; // Standard HTML 24-bit RGB hex color notation.

int bandLimit = 12;
int startingQ = 55;
int octaveDivisions = 2;

boolean sendOffset = true;

// ********** BEGIN ***********
void setup() {
  frameRate(40);
  // Init all the sound objects
  coc = new ColorOrganCalculator(colorIndex, bandLimit, startingQ, octaveDivisions, bandLimit);
  coc.init();

  String[] serials = Serial.list();
  String portName = serials[serials.length - 1];
  for (int i = 0; i < serials.length; i++) {
    if (serials[i].contains("/dev/tty.usbmodem")) {
      portName = serials[i];      
    }
  }
  myPort = new Serial(this, portName, 115200);

  amplitudes = new float[bandLimit];
  lastAmplitudes = new float[bandLimit];
  amps = new byte[bandLimit];
  lastResponse = 0;
  deviceState = 0;

  // Enter command mode
  myPort.clear();
  myPort.write((byte)'m');
  waitUntilByte();
  
  // Set the offset flag
  if (sendOffset) {
    myPort.write((byte)'O');
  }
  else {
    myPort.write((byte)'o');
  }
  waitUntilByte();

  // Set up the colors
  myPort.write((byte)'c'); 
  waitUntilByte();
  println();
  println("colorIndexLen="+(byte)colorIndex.length);

  myPort.write((byte)colorIndex.length); 
  for (int i = 0; i < colorIndex.length; ++i) {
    myPort.write((byte)((colorIndex[i])>>>16));
    myPort.write((byte)((colorIndex[i]&0x00FF00)>>>8));
    myPort.write((byte)((colorIndex[i]&0x0000FF)));
  }
  waitUntilByte();
  myPort.write((byte)0); 
  waitUntilByte();

  while (myPort.available () > 0) {
    getResponse();
  }
  println();
  println("--Init Done");
  myPort.write((byte)'a'); 
  lastUpdate = millis();
}

void draw() {
  coc.analyzeInput();
  System.arraycopy(amplitudes, 0, lastAmplitudes, 0, amplitudes.length);
  amplitudes = coc.getCurrentLevels();
  posOffset = coc.beatNumber;

  updateScreen();
}

void updateScreen() {
  // Wait until the controller sends back a byte to indicate that it is ready, then
  //   send the current amplitudes.
  if (myPort.available() > 0) {
    while (myPort.available () > 0) {
      getResponse();
    }

    switch (deviceState) {
    case 'm':
      myPort.write((byte)'a');
    case 'a':
      for (int i = 0; i < bandLimit; ++i) {
        amps[i] = unsignedByte(amplitudes[i]*255);
      } //println(amplitudes); println(amps);

      myPort.write((byte)amps.length);  //println(amps.length);
      myPort.write((byte)posOffset); //println(posOffset);
      myPort.write(amps); //println(amps);

      coc.clearPSU();

      println(" time: " + (millis() - lastUpdate));
      lastUpdate = millis();
      break;
    }
  } // else { println("MISS!");}
}

public void stop() {
  // always close Minim audio classes when you are done with them
  coc.stop();
  myPort.stop();
  super.stop();
}

// This is used primarily when taking audio from an external input. Since
//   I automatically reset levels based on recent input volume, even a 
//   small amount of noise from the external source will eventually light 
//   up some of the lights, which can ruin the effect of quiet passages 
//   in the music. The somewhat crude solution is to set a noise threshold 
//   when no music is playing. Sound must exceed the volume of the noise in 
//   order to be recognized. This check is done on a per-band basis, so a 
//   lot of noise in one band (e.g. a 60Hz hum) won't interfere with the 
//   sensitivity of other bands.
//
//   Anyways, to set the noise threshold, hold down 'n' when no music is
//   playing to sample the noise.
void keyPressed() {
  if ( key == 'n' ) {
    coc.startSettingNoiseLevel();
  }
}

void keyReleased() {
  if ( key == 'n' ) {
    coc.stopSettingNoiseLevel();
  }
}

char waitUntilByte() {
  return waitUntilByte(5000);
}

char waitUntilByte(int timeoutMillis) {
  int delays = 0;
  while (myPort.available () == 0) {
    delay(1);
    ++delays;

    if (delays > timeoutMillis) {
      println("Tired of waiting");
      myPort.write((byte)0);
      delays = 0;
    }
  }
  return getResponse();
}

char getResponse() {
  lastResponse = (char)myPort.read();
  if (lastResponse == 'e') {
    deviceState = 'm';
  }
  else {
    deviceState = lastResponse;
  }
  print(lastResponse);

  return lastResponse;
}

byte unsignedByte( int val ) { 
  return (byte)( val > 127 ? val - 256 : val );
}
byte unsignedByte( float val ) { 
  return (byte)( (int)val > 127 ? (int)val - 256 : (int)val );
}

