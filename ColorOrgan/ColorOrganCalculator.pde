/*
Color Organ Calculator

Produces amplitude information from configurable frequency bands
from a live sound stream via the minim library (applying some
shaping with the goal of producing an interesting light display).

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

import ddf.minim.analysis.*;
import ddf.minim.*;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.FileNotFoundException;

class ColorOrganCalculator {
  protected Minim minim;
  protected AudioInput myInput;
  protected AudioOutput myOutput;
  protected BeatDetect beat;
  protected FFT fftL;
  protected FFT fftR;

  public int bufferSize;
  public int minBeatPeriod;

  // Frequency analysis
  public float decay;
  public float decayPeriod;
  public float thresBot;
  public float thresTop;
  protected float[] peaks;
  protected float[] peakSinceUpdate;
  protected float[] noiseLvl;
  public float minPeak; // Used to stop lights flickering at start due to inaudible noise
  public boolean trackNoiseLvl = false;
  protected float maxPeak;
  protected int maxPeakIdx;
  protected int bandNumber;
  protected int beatRadix;
  public int beatNumber;
  protected int lastUpdate;

  public long[] colorIndex; // Standard HTML 24-bit RGB hex color notation.
  public int bandLimit = 12;
  public int startingQ = 55;
  public int octaveDivisions = 2;

  public ColorOrganCalculator() {
    this(new long[] {0xff0000, 0xff0000, 0xff0000, 0xffff00, 0x00ff00, 0x00ff00,
                     0x00ff00, 0x0000ff, 0x0000ff, 0x8000ff, 0xff00ff, 0xff00ff},
         12, 55, 2, 0);
  }

  public ColorOrganCalculator(long[] colorIndex,
                              int bandLimit,
                              int startingQ,
                              int octaveDivisions,
                              int beatRadix) {
    this.colorIndex = colorIndex;
    this.bandLimit = bandLimit;
    this.startingQ = startingQ;
    this.octaveDivisions = octaveDivisions;
    this.beatRadix = beatRadix;

    bufferSize = 2048;
    minBeatPeriod = 300; // if new "beat" is < 300 ms after last beat, ignore it.

    decay = 0.99f;
    decayPeriod = 60.0/1000.0; // 60 updates per 1000ms
    thresBot = 0.3;
    thresTop = 0.9;
    minPeak = 0.1; // Used to stop lights flickering at start due to inaudible noise
    trackNoiseLvl = false;
    maxPeak = 0;
    maxPeakIdx = 0;
    beatNumber = 0;
  }

  public String sketchPath (String fileName) {
      return fileName;
  }

  public InputStream createInput (String fileName) {
      try {
          return new FileInputStream(fileName);
      } catch (FileNotFoundException e) {
          e.printStackTrace();
      }
      return null;
  }

  public void init() {
    // Init all the sound objects
    minim = new Minim(this);
    myInput = minim.getLineIn(Minim.STEREO, bufferSize);
    fftL = new FFT(myInput.bufferSize(), myInput.sampleRate());
    fftL.logAverages(startingQ, octaveDivisions);
    fftL.window(FFT.HAMMING);
    fftR = new FFT(myInput.bufferSize(), myInput.sampleRate());
    fftR.logAverages(startingQ, octaveDivisions);
    fftR.window(FFT.HAMMING);
    beat = new BeatDetect(myInput.bufferSize(), myInput.sampleRate());
    beat.setSensitivity(minBeatPeriod);

    bandNumber = min(bandLimit, fftL.avgSize());
    peaks = new float[bandNumber];
    peakSinceUpdate = new float[bandNumber];
    noiseLvl = new float[bandNumber];
    for (int i = 0; i < bandNumber; ++i) peaks[i] = minPeak;
    lastUpdate = millis();
  }

  public void analyzeInput() {
    beat.detect(myInput.mix);
    fftL.forward(myInput.left);
    fftR.forward(myInput.right);
  }

  public float[] getCurrentLevels() {
    checkPeaks();

    return getAmplitudes();
  }

  public int[] getCurrentColors() {
    return getColors(getCurrentLevels());
  }

  void checkPeaks() {
    boolean newPeak = false;
    boolean newMaxPeak = false;

    // Grab the new level data. Check to see if it represents a new peak.
    //   Also check to see if there is a new max peak.
    //   If there are no new peaks, decay the levels of the current peaks.
    //     (this acts as a primitive auto-level control, and helps emphasize
    //      changes in volume)
    for (int i=0; i < bandNumber; i++) {
      if (fftL.getAvg(i) + fftR.getAvg(i) > peaks[i]) {
        peaks[i] = fftL.getAvg(i) + fftR.getAvg(i);
        // Shape peaks to pink noise curve
        peaks[i] *= pow(10.0, (3.0/20) * (i/octaveDivisions));

        if (peaks[i] > maxPeak) {
          newMaxPeak = true;
          maxPeak = peaks[i];
          maxPeakIdx = i;
        }
      }
      if (!newPeak) {
        peaks[i] *= pow(decay, (millis() - lastUpdate) * decayPeriod);
        if (peaks[i] < minPeak) peaks[i] = minPeak;
      }
    }
    if (!newMaxPeak) {
      maxPeak *= pow(decay, (millis() - lastUpdate) * decayPeriod);
      if (maxPeak < minPeak) maxPeak = minPeak;
    }

    // Raise the other peaks based on the max peak. This allows a few
    //   fequency bands to dominate the display when those frequencies also
    //   dominate the sound spectrum. The power function makes more distant
    //   frequency bands less affected by this shaping. The value of 0.9
    //   (and heck, the function) was the result of crude experimentation.
    //   There are probably better methods for this, but it seems to do
    //   about what I want.
    for (int i = 0; i < bandNumber; i++) {
      float peakTop = maxPeak*(pow(0.9, abs(i-maxPeakIdx)));
      if (peaks[i] < peakTop) peaks[i] = peakTop;
    }

    if (trackNoiseLvl) setNoiseFloor();

    // I'm not sure I'm totally sold on this. It seems a little busy.
    if (beat.isKick()) beatNumber++;
    if (beatNumber >= beatRadix) beatNumber = 0;

    lastUpdate = millis();
  }

  public float[] getAmplitudes() {
    float[] amplitudes = new float[bandNumber];

    for (int i=0; i < bandNumber; i++) {
      float amp = fftL.getAvg(i) + fftR.getAvg(i);

      // Check noise threshold. If above, normalize amp to [0-1].
      if (amp > noiseLvl[i]) amp = (amp)/peaks[i] * pow(10.0, (3.0/20) * (i/octaveDivisions));
      else amp = 0;

      // Shape the band levels. Peg values above or below the upper and lower
      //   bounds. Remap the middle so that it covers the full range. Less space
      //   between the bounds makes things blinkier.
      if (amp < thresBot) amp = 0;
      else if (amp > thresTop) amp = 1;
      else amp = amp/(thresTop - thresBot) - thresBot;
      if (amp < 0) amp = 0;
      else if (amp > 1) amp = 1;

      // Hold on the biggest amplitudes we've seen since the last update. This
      //   is so that we don't lose transients if it takes too long to communicate
      //   with the lights. I'm not sure how much of a difference this makes
      //   though.
      if (amp > peakSinceUpdate[i]) peakSinceUpdate[i]=amp;
      else amp=peakSinceUpdate[i];

      amplitudes[i] = amp;
    }

    return amplitudes;
  }

  public int[] getColors(float[] amplitudes) {
    int[] colors = new int[amplitudes.length*3];

    for (int i=0; i < amplitudes.length; i++) {
      long col = colorIndex[i%colorIndex.length];

      // Set the colors from the amplitudes
      colors[i*3+0] = (byte)( ((col&0xff0000) >> 16)*amplitudes[i] );
      colors[i*3+1] = (byte)( ((col&0x00ff00) >> 8 )*amplitudes[i] );
      colors[i*3+2] = (byte)( ((col&0x0000ff)      )*amplitudes[i] );
    }

    return colors;
  }

  public void clearPSU() {
    for (int i = 0; i<bandNumber; ++i) {
      peakSinceUpdate[i] = 0;
    }
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
  public void startSettingNoiseLevel() {
    if (!trackNoiseLvl) {
      for (int i=0; i < fftL.avgSize(); i++) {
        noiseLvl[i] = 0;
      }
      trackNoiseLvl = true;
    }
  }

  public void stopSettingNoiseLevel() {
    trackNoiseLvl = false;
  }

  void setNoiseFloor() {
    for (int i=0; i < bandNumber; i++) {
      if (fftL.getAvg(i)+fftR.getAvg(i) > noiseLvl[i]) {
        noiseLvl[i] = fftL.getAvg(i)+fftR.getAvg(i);
      }
    }
  }

  public void stop() {
    myInput.close();
    myOutput.close();
    minim.stop();
  }
}
