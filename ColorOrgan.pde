
//import processing.serial.*;
import jssc.SerialPortList;
import jssc.SerialPort;
import jssc.SerialPortException;

// Sound Input and processing objects
SerialPort myPort;
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
byte[] drawState; // I'm assuming 15-bit light data
byte lowByte;
byte highByte;
char lastResponse;
char deviceState;

// Constants to configure
int ledCount = 50;  //How many LEDs in your string.
/*long[] colorIndex = { 
  0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff, 0x0000ff,
  0x00ff00, 0x00ff00, 0x00ff00, 0x00ff00, 0x00ff00, 0x00ff00
}; // Standard HTML 24-bit RGB hex color notation.*/
long[] colorIndex = { 
  0xff0000, 0xff0000, 0xff0000, 0xffff00, 0x00ff00, 0x00ff00, 
  0x00ff00, 0x0000ff, 0x0000ff, 0x8000ff, 0xff00ff, 0xff00ff
}; // Standard HTML 24-bit RGB hex color notation.
/*int[] colorIndex = { 
 0xff0000, 0xff8000, 0xffff00, 0x80ff00, 0x00ff00, 0x00ff80,
 0x00ffff, 0x0080ff, 0x0000ff, 0x8000ff, 0xff00ff, 0xff0080
 }; // Standard HTML 24-bit RGB hex color notation.*/
int bandLimit = 12;
int startingQ = 55;
int octaveDivisions = 2;

// ********** BEGIN ***********
void setup() {
  frameRate(40);
  // Init all the sound objects
  coc = new ColorOrganCalculator(colorIndex, bandLimit, startingQ, octaveDivisions);
  coc.init();

  // Init tracking data
  drawState = new byte[ledCount*2+2];
  drawState[ledCount*2] = 0; 
  drawState[ledCount*2 + 1] = 0; // Terminating bytes

  println(SerialPortList.getPortNames());
  // Init communications
  String portName = SerialPortList.getPortNames()[0];
  println(portName);
  myPort = new SerialPort(portName);
  try {
     myPort.openPort();
     myPort.setParams(SerialPort.BAUDRATE_115200,
                          SerialPort.DATABITS_8,
                          SerialPort.STOPBITS_1,
                          SerialPort.PARITY_NONE);
  
  amplitudes = new float[bandLimit];
  lastAmplitudes = new float[bandLimit];
  amps = new byte[bandLimit];
  lastResponse = 0;
  deviceState = 0;

  myPort.purgePort(SerialPort.PURGE_RXCLEAR);
  myPort.writeByte((byte)'m');
  waitUntilByte();

  myPort.writeByte((byte)'c'); 
  waitUntilByte();
  println();
  println("colorIndexLen="+(byte)colorIndex.length);
  
  myPort.writeByte((byte)colorIndex.length); 
  for (int i = 0; i < colorIndex.length; ++i) {
    myPort.writeByte((byte)((colorIndex[i])>>>16));
    myPort.writeByte((byte)((colorIndex[i]&0x00FF00)>>>8));
    myPort.writeByte((byte)((colorIndex[i]&0x0000FF)));
  }
  waitUntilByte();
  myPort.writeByte((byte)0); waitUntilByte();

  while (myPort.getInputBufferBytesCount() > 0) {
    getResponse();
  }
  println();
  println("--Init Done");
  myPort.writeByte((byte)'a'); 
  lastUpdate = millis();
  } catch (SerialPortException ex) { ; }
}

void draw() {
  coc.analyzeInput();
  System.arraycopy(amplitudes, 0, lastAmplitudes, 0, amplitudes.length);
  amplitudes = coc.getCurrentLevels();
  posOffset = coc.getPosOffset();

  updateScreen3();
}

/*void updateScreen() {
  // Wait until the controller sends back a byte to indicate that it is ready, then
  //   send the current state.
  for (int i=0; i < amplitudes.length; i++) {
    long col = colorIndex[i%colorIndex.length];
    rr = (byte)( ((col&0xff0000) >> 16)*amplitudes[i] );
    gg = (byte)( ((col&0x00ff00) >> 8)*amplitudes[i]  ); 
    bb = (byte)( ((col&0x0000ff)     )*amplitudes[i]  );

    // Set the communications byte array from the colors.
    lowByte = (byte)(rgbTo15bit(rr, gg, bb) >>> 8);
    highByte = (byte)(rgbTo15bit(rr, gg, bb) &0x00ff);

    // Place the bytes in the array. If there fewer bands than lights,
    //   repeat until we run out of lights.
    //   (There is almost certainly a better way to do this...)
    for (int j=0; ((i+posOffset)%amplitudes.length)*2+j+1 < ledCount*2; j+=amplitudes.length*2) {
      drawState[((i+posOffset)%amplitudes.length)*2+j] = lowByte;
      drawState[((i+posOffset)%amplitudes.length)*2+j+1] = highByte;
    }
  }

  if (myPort.available() > 0) {

    //myPort.clear();
    myPort.write(0); 
    myPort.write(0);
    myPort.write(drawState); 

    coc.clearPSU();

    lastUpdate = millis();
  }

  else println(millis() - lastUpdate);
}*/

/*void updateScreen2() {
  // Wait until the controller sends back a byte to indicate that it is ready, then
  //   send the current state.
  float maxAmp = -1.0;
  int maxAmpIndex = 0;
  byte maxLowByte = 0;
  byte maxHighByte = (byte)0x0080;

  for (int i=0; i < amplitudes.length; i++) {
    long col = colorIndex[i%colorIndex.length];
    rr = (byte)( ((col&0xff0000) >> 16)*amplitudes[i] );
    gg = (byte)( ((col&0x00ff00) >> 8)*amplitudes[i]  ); 
    bb = (byte)( ((col&0x0000ff)     )*amplitudes[i]  );

    // Set the communications byte array from the colors.
    lowByte = (byte)(rgbTo15bit(rr, gg, bb) >>> 8);
    highByte = (byte)(rgbTo15bit(rr, gg, bb) &0x00ff);

    // Place the bytes in the array. If there fewer bands than lights,
    //   repeat until we run out of lights.
    //   (There is almost certainly a better way to do this...)
    //for (int j=0; ((i+posOffset)%amplitudes.length)*2+j+1 < ledCount*2; j+=amplitudes.length*2) {
    // drawState[((i+posOffset)%amplitudes.length)*2+j] = lowByte;
     //drawState[((i+posOffset)%amplitudes.length)*2+j+1] = highByte;
     //}

    if (maxAmp < amplitudes[i] 
      || (maxAmp == amplitudes[i] && lastAmplitudes[maxAmpIndex] > lastAmplitudes[i])
      ) {
      maxAmp = amplitudes[i];
      maxAmpIndex = i;
      maxLowByte = lowByte;
      maxHighByte = highByte;
    }
  }
  //println("maxLB/MaxHB="+ maxLowByte + "/" + maxHighByte);

  for (int i=0; i < ledCount*2; i += 2) {
    drawState[i] = maxLowByte;
    drawState[i+1] = maxHighByte;
  }

  if (myPort.available() > 0) {
    myPort.clear();
    myPort.write(0); 
    myPort.write(0);
    myPort.write(drawState); 

    coc.clearPSU();

    lastUpdate = millis();
  }
  else println(millis() - lastUpdate);
}*/

void updateScreen3() {
  try {
  // Wait until the controller sends back a byte to indicate that it is ready, then
  //   send the current amplitudes.
  if (myPort.getInputBufferBytesCount() > 0) {
    while (myPort.getInputBufferBytesCount() > 0) {
      getResponse();
    }
    
    switch (deviceState) {
      case 'm':
        myPort.writeByte((byte)'a');
      case 'a':
        for (int i = 0; i < bandLimit; ++i) {
          amps[i] = unsignedByte(amplitudes[i]*255);
        } //println(amplitudes); println(amps);
    
        //myPort.clear();
        myPort.writeByte((byte)amps.length);  //println(amps.length);
        myPort.writeBytes(amps); //println(amps);
    
        coc.clearPSU();
    
        println(" time: " + (millis() - lastUpdate));
        lastUpdate = millis();
        break;
      
    }
  } // else { println("MISS!");}
  } catch (SerialPortException ex) { ; }
}

public void stop() {
  try {
  // always close Minim audio classes when you are done with them
  coc.stop();
  myPort.closePort();
  super.stop();
  } catch (SerialPortException ex) { ; }
}

int rgbTo15bit( byte rr, byte gg, byte bb ) {
  return ((rr&0xf8)<<7)|((gg&0xf8)<<2)|((bb&0xf8)>>>3)|0x8000;
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

/*int gotExpectedReply(String expectedResponse) {
  while (myPort.available () > 0) {
    response += getResponse(); 
  } if (response.length() > 0) println(response);
  
  if (response.length() < expectedResponse.length()) {
    if (millis() - lastUpdate > 5000) {
      println("Tired of waiting");
      return -1;
    } 
    else {
      return 0; //Not yet
    }
  } 
  else if (response.substring(response.length() - expectedResponse.length()).equals(expectedResponse)) {
      response = "";
      return 1; //Success!
    }
  else {
    response = "";
    return -1; //failure
  }
}*/

char waitUntilByte() {
  return waitUntilByte(5000);
}

char waitUntilByte(int timeoutMillis) {
  try {
  int delays = 0;
  while (myPort.getInputBufferBytesCount() == 0) {
    delay(1);
    ++delays;

    if (delays > timeoutMillis) {
      println("Tired of waiting");
      myPort.writeByte((byte)0);
      delays = 0;
    }
  }
} catch (SerialPortException ex) { ; }
  return getResponse();
}

char getResponse() {
  try {
  lastResponse = (char)myPort.readBytes(1)[0];
  if (lastResponse == 'e') {
    deviceState = 'm';
  }
 else {
   deviceState = lastResponse;
 }
 print(lastResponse);
 } catch (SerialPortException ex) { ; }
 return lastResponse;
}

byte unsignedByte( int val ) { 
  return (byte)( val > 127 ? val - 256 : val );
}
byte unsignedByte( float val ) { 
  return (byte)( (int)val > 127 ? (int)val - 256 : (int)val );
}

