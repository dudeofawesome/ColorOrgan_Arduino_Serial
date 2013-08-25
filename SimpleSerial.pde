// Wrapper class for differing serial implementation
import processing.serial.*;
import jssc.SerialPortList;
import jssc.SerialPort;
import jssc.SerialPortException;

abstract class SimpleSerial {
  abstract int available();
  abstract void clear();
  abstract int read();
  abstract void write(byte);
  abstract void write(byte[]);
  abstract void write(int);
  abstract void write(String);
  abstract void stop();
}

class SimpleSerialSerial {
  protected daPort;
  
  public SimpleSerialSerial(PApplet parent, String iname, int irate) {
    daPort = new Serial(parent, iname, irate);
  }
}

class SimpleSerialJssc {
  protected daPort;
  
  public SimpleSerialSerial(PApplet parent, String iname, int irate) {
    daPort = new Serial(parent, iname, irate);
  }
}
