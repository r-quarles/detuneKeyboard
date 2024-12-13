// Detuning Keyboard
// The Sonic Experience FA24
// Rae Quarles

//// V 1.8
// Draw 12 keys with sliders, output PRESSED, or DRAGGED and y amount for each key
// Use functions to calculate frequency based on tonic, button/interval number, and detuning amound in cents
// Send OSC msg with button #, frequency, gate (on/off), and release time

// FREQUENCY VISUALIZATION
  // Slider bars span a 100 cent range, -/+ 50c relative to each chromatic note, so each slider continuously daisy-chains
  // "Default" position set to 12 Tone Equal Temperment, thus that all key-buttons are centered about the x axis
  // Other tunings change y axis position of key-buttons to align with each notes offset based on cents
    // For example, the 7th interval above C=261.63 in 12TET is 493.89Hz vs 493.89Hz in Pyth tuning
    // This is a difference of 9.79c, so in Pyth tuning the y value of the key-button will be 9.79c above the default position
    // This allows for quick comparison of each alternative tuning to 12TET, and construction of mixed-tuning scales\
    // DETUNE CENTS ARE WRITTEN ON KEYS 

//// TO USE: USE 1/2/3/4 TO SELECT TUNING ; USE r FOR SHORT RELEASE, s FOR LONG RELEASE
// Play with the same note in different tunings, the same note pressed normally and then dragged to detune slightly, 
// or different timbres between intervals depending on temperment

import oscP5.*; 
import netP5.*;

// OSC Variables
OscP5 oscP5;
NetAddress myAddress;

// VARS
int buttonCount = 15;      // Total number of buttons to create
float[] circleX;           // X positions of each button's circle
float[] circleY;           // Default Y Positions of each button's circle
float[] currentY;          // Current Y positions of each button's circle
float[] lastY;             // Last Y values of of mouseclick for each button
int[] circleColor;         // Color for each button when pressed and released
int[] textColor;           // Color for each button's text when pressed and released
String[] intervalLabel;    //Name of the interval were on (determined in draw())
float diameter = 70;       // Width (Diameter) of each circle
int[] sliderColor;         // Color of the slider behind each button
int[] gate;                // Gate for each button, 1 = gate, 0 = stop

float tonic = 32.703;      //Holds the tonic (starting freq) (Lowest C)
float divisions = 12;      //Divisions for EDO
float oct = 4;             //Octave multiplier (default 4 - middle octave)
float[] freq;              //Holds the frequencies for each key that we'll send via OSC
float[] refFreq;           //Holds the reference frequencies in 12TET so we can place the button
float[] centsDif;          //Holds the number of cents difference between each keys ref and real freq
float[] detuneDist;        //Holds the amount of cents to detune
int tuning = 0;            //The tuning mode: 0 - Equal; 1 - Just; 2 - Pythagorean
float release = 0;         //Holds the sustain amount after release we'll send via OSC

void setup() {
  size(1600, 1000);              // Set the canvas size
  background(0);                 // Fill the background with black
  noStroke();
  
  // Initialize OSC
  oscP5 = new OscP5(this, 12000);  // Listen on port 12000
  myAddress = new NetAddress("127.0.0.1", 57120); // Set address to send OSC messages to

  // Initialize arrays based on the button count
  circleX = new float[buttonCount];
  currentY = new float[buttonCount];
  circleY = new float[buttonCount];
  lastY = new float[buttonCount];
  gate = new int[buttonCount];
  circleColor = new int[buttonCount];
  sliderColor = new int[buttonCount];
  textColor = new int[buttonCount];
  intervalLabel = new String[buttonCount];
  freq = new float[buttonCount];
  refFreq = new float[buttonCount];
  centsDif = new float[buttonCount];
  detuneDist = new float[buttonCount];


  // Calculate spacing and initial positions for each button
  float spacing = width / (buttonCount + 3); // Space each button evenly, with 2 button "slots" to the left
  for (int i = 0; i < buttonCount; i++) {
    circleX[i] = spacing * (i + 3);          // Set the x position for each button, (two spots over -> +1 (to increment up by 1) +2 (to start 2 spaces over)
    
    
    if (i % 2 == 0) {  //If its an even key (white)
      circleY[i] = 3 * height / 4;               // Default y position for each button (3/4 down)
      circleColor[i] = color(255);               // Set initial color to white
      sliderColor[i] = color(84, 78, 88);        // Set slider to l grey
      textColor[i] = color(0);                   // Set text to black
    } if (i % 2 != 0) {  //If key is odd/black
      circleY[i] = (3 * height / 4) - diameter*2;// Default y position for each black button (1/2 length of the slider up)
      circleColor[i] = color(15);                // Set initial color to dark grey
      sliderColor[i] = color(42, 39, 44);        // Set slider to dk grey
      textColor[i] = color(255);                 // Set text to white
    }
    
    currentY[i] = circleY[i];                // Initialize currentY to default y position on start up so it defaults to 12TET
    lastY[i] = 0;                            // Initialize lastY for each button
    gate[i] = 0;                             // Set gate state to "stop" initially
  }
  // Calculate default/reference freq in 12TET for each key
  for (int i = 0; i < buttonCount; i++) {
    equalTuning(i);        // Calculate each button's freq (no detune)
    refFreq[i] = freq[i];  // Assign each buttons ref freq to the found frequency from function
  }
  
  println("Use Keys 1/2/3 to select between Equal/Just/Pythagorean Tuning");
  println("Use 's' for long sustain, use 'r' for short sustain");
}

void draw() {
  background(0);                    // Clear the screen to black each frame
  
  // Draw each button and its slider
  for (int i = 0; i < buttonCount; i++) {
    if (i != 5 && i!= 13) {  //If its a key that falls on a semitone: 
      fill(sliderColor[i]);              // Set color for the slider
      rect(circleX[i] - (diameter / 2), circleY[i] - (diameter * 2), diameter, diameter * 4, 28); // Draw slider bar
      fill(circleColor[i]);           // Set color for the button
      ellipse(circleX[i], currentY[i], diameter, diameter); // Draw draggable button 
      textSize(30);
      textAlign(CENTER);
      fill(textColor[i]);  //Set color for text
      text(Float.toString(Math.round(centsDif[i]*-10.)/10.), circleX[i], currentY[i] + (diameter/6));  //Draw the detune cents on the keys
      
      //Label the keys for usability
      textSize(22);
      fill(196, 195, 208);
      
      if (mousePressed == false) {  //If the buttons not being pressed show the interval
        if (i == 0) {
          intervalLabel[i] = "Tonic";
        } if (i == 1) {
          intervalLabel[i] = "m 2nd";
        } if (i == 2) {
          intervalLabel[i] = "M 2nd";
        } if (i == 3) {
          intervalLabel[i] = "m 3rd";
        } if (i == 4) {
          intervalLabel[i] = "M 3rd";
        } if (i == 6) {
          intervalLabel[i] = "Perf 4th";
        } if (i == 7) {
          intervalLabel[i] = "Aug 4th";
        } if (i == 8) {
          intervalLabel[i] = "Perf 5th";
        } if (i == 9) {
          intervalLabel[i] = "m 6th";
        } if (i == 10) {
          intervalLabel[i] = "M 6th";
        } if (i == 11) {
          intervalLabel[i] = "m 7th";
        } if (i == 12) {
          intervalLabel[i] = "M 7th";
        } if (i == 14) {
          intervalLabel[i] = "Octave";
        }
      } if (mousePressed == true  && (dist(circleX[i], currentY[i], mouseX, mouseY) < diameter / 2)) {  //If the button is being pressed tho:
          intervalLabel[i] = Float.toString(Math.round(centsDif[i]*-10.)/10.);
      }
      text(intervalLabel[i], circleX[i], circleY[i] - (2.*diameter) - 5.);  //Draw the text label for intervals above each slider
    }
  }
}

void keyPressed() {
  
  // Keys for tuning selection 1/2/3 for EDO/JUST/PYTH
  if (key == '1') {
    tuning = 0;
    for (int i = 0; i< buttonCount; i++) {
      equalTuning(i);  //Assign each buttons frequency to the cooresponding 12TET ref freq
      centsCalc(i);  //Send centsCalc which button and it will calculate the cents between that buttons new freq and the ref freq in EDO
    }
    println("Equal Temperament");
  } 
  
  if (key == '2') {
    tuning = 1;
    for (int i = 0; i< buttonCount; i++) {
      justTuning(i);        //Calculate freq[] based on just intonation
      centsCalc(i);  //Send centsCalc which button and it will calculate the cents between that buttons new freq and the ref freq in EDO
    }
    println("Just Temperament");
  } 
  
  if (key == '3') {
    tuning = 2;
    for (int i = 0; i< buttonCount; i++) {
      pythTuning(i);        //Calculate freq[] based on pyth intonation
      centsCalc(i);  //Send centsCalc which button and it will calculate the cents between that buttons new freq and the ref freq in EDO
    }
    println("Pythagorean Temperament");
  }
  
  if (key == '4') {
    tuning = 3;
    for (int i = 0; i< buttonCount; i++) {
      qcommaTuning(i);        //Calculate freq[] based on qcomma intonation
      centsCalc(i);  //Send centsCalc which button and it will calculate the cents between that buttons new freq and the ref freq in EDO
    }
    println("Quarter-Comma Meantone Temperament");
  }
  
  
  for (int i = 0; i< buttonCount; i++) {  //Move each button based on cents difference from reference in 12TET
    currentY[i] = circleY[i] + map(centsDif[i], -50, 50, -2*diameter, 2*diameter);  //Move current y to reflect cents +/- (mapped so slider top is +50 and bottom is -50)
  }
      
// Keys for sustain control  
  if (key == 's') {
    release = 8.0;
    println("Long Sustain");
  } if (key == 'r') {
    release = 1.3;
    println("Short Sustain");
  }
}
  

void mousePressed() {
  // Check if the mouse press is within any of the buttons
  for (int i = 0; i < buttonCount; i++) {
    if (i != 5 && i != 13) {
      if (dist(circleX[i], currentY[i], mouseX, mouseY) < diameter / 2) { // Check if click is inside the circle
        lastY[i] = mouseY;            // Remember the y value where we first clicked
        //(NO LONGER SNAPPING TO CIRCLEY currentY[i] = circleY[i];     // Set currentY to strting y position for the button because we haven't dragged it yet
        gate[i] = 1;                  // Set gate to "1" to indicate button is active
        
        if (i % 2 == 0) { //Even/white keys
          circleColor[i] = color(233);  // Change color to indicate button is pressed
        } if (i % 2 != 0) { //Odd/black keys
          circleColor[i] = color(33);
        }
        
        // Send OSC message on press with gate = 1
        sendOSCMessage(i, 1); // 1 for pressed
      }
    }
  }
}

void mouseDragged() {
  // Check if any button is being dragged
  for (int i = 0; i < buttonCount; i++) {
    if (gate[i] == 1) {   // Only update position if button gate is open
      // Limit dragging to stay within the slider bounds
      float upperBound = circleY[i] - diameter * 1.5; // Top of the slider
      float lowerBound = circleY[i] + diameter * 1.5; // Bottom of the slider
      
      if (mouseY >= upperBound && mouseY <= lowerBound) {  
        currentY[i] = mouseY;  // Update y position to follow mouse within bounds
      } else if (mouseY < upperBound) {  // If dragged above the upper bound
        currentY[i] = upperBound;        // Set to upper bound
      } else if (mouseY > lowerBound) {  // If dragged below the lower bound
        currentY[i] = lowerBound;        // Set to lower bound
      }

      // Calculate the detuning based on the distance from the default position
      detuneDist[i] = map((currentY[i] - circleY[i]) * -1, -diameter * 1.5, diameter * 1.5, -50, 50);
      freq[i] = refFreq[i] * (float) Math.pow(2, detuneDist[i] / (divisions * 100));
      centsCalc(i);  //Calculate cents for display
      centsDif[i] = (centsDif[i]*-1);  //Swap the sign (idk why this is happening, bandaid)
      // Send OSC message of the button #, distance from center (0-50), and open gate
      sendOSCMessage(i, 1);
    }
  }
}

void mouseReleased() {
  // Reset each button when mouse is released
  for (int i = 0; i < buttonCount; i++) {
    if (gate[i] == 1) {                  // Only reset if button was active (gate was open)
      //currentY[i] = circleY[i];        // Reset y position to default
      gate[i] = 0;                       // Set gate state to "closed"
      
      if (i % 2 == 0) {  //If its an even key (white)
        circleColor[i] = color(255);             // Set initial color to white
      } if (i % 2 != 0) {  //If key is odd/black
        circleColor[i] = color(15);              // Set initial color to dark grey
      }
      
      // Send OSC message on release with gate = 0
      sendOSCMessage(i, 0); // 0 for released
    }
  }
}

// A function to send OSC messages
void sendOSCMessage(int buttonIndex, int gate) {

  OscMessage msg = new OscMessage("/key");
  msg.add(buttonIndex);        // Interval from tonic to octave (0-7)
  msg.add(freq[buttonIndex]);  // Frequency calculated of that particular button
  msg.add(gate);               // Gate state (1 for pressed, -1 for released)
  msg.add(release);            // Release in s
  
  // Check if values are valid before sendingr
  if (msg.get(0) != null && msg.get(1) != null && msg.get(2) != null && msg.get(3) != null) {  // If the four part msg is all null:
      oscP5.send(msg, myAddress); // Send message
      println("OSC Message: /key " + buttonIndex + ", " + freq[buttonIndex] + ", " + gate + ", " + release); // Print the OSC message
  } else {
      println("Error: OSC message contains null values!");
  } 
}

// A function that calculates equal tuning with variable divisions of the octave
void equalTuning(int buttonIndex) {  //detuneCents is the scaledDistance from the sliders
  float[] toneIntervals = new float[] {0., 1., 2., 3., 4., 0., 5., 6., 7., 8., 9., 10., 11., 0., 12.};  //New float array of tone/semitone intervals for diatonic major scale!
  //divisions = 12.;  // Default 12 divisons of the octave, change and take as arg in later version?
  freq[buttonIndex] = tonic * (float) (Math.pow(2, toneIntervals[buttonIndex] / divisions) *oct);  //Frequency is the tonic * 2 ^ (whatever button # aligns w tone array) / divisions as specified 
}  //End brace for equal tuning

void justTuning(int buttonIndex) {
  float[] ratios = new float[] {1., 16./15., 10./9., 6./5., 5./4., 0., 4./3., 45./32., 3./2., 8./5., 5./3., 9./5., 15./8., 0., 2.};  //New float array of just intervals for diatonic major scale
  freq[buttonIndex] = tonic * (ratios[buttonIndex]*oct);  //Frequency is the tonic * cooresponding intervals * octave multiplier
}

void pythTuning(int buttonIndex) {
  float[] ratios = new float[] {1., 256./243., 9./8., 32./27., 81./64., 0., 4./3., 729./512., 3./2., 128./81., 27./16., 16./9., 243./128., 0., 2.};  //New float array of pythagorean intervals for diatonic major scale
  freq[buttonIndex] = tonic * (ratios[buttonIndex]*oct);  //Frequency is the tonic * cooresponding intervals * octave multiplier
}

void qcommaTuning(int buttonIndex) {
  float[] ratios = new float[] {1., 1.06998, 1.11803, 1.19627, 1.24999, 0., 1.33747, 1.39753, 1.49534, 1.59999, 1.67184, 1.78884, 1.86918, 0., 1.99998};
  freq[buttonIndex] = tonic * (ratios[buttonIndex]*oct);  //Frequency is the tonic * cooresponding intervals * octave multiplier
}

// Cents Calculator to move circleY position of each key-button to the location of the new tuning
void centsCalc(int buttonIndex) {  // newFreq is the frequency we are placing on a key-button, eqTempFreq is the reference "default" freq
 centsDif[buttonIndex] = 100*divisions * (float) (Math.log(freq[buttonIndex]/refFreq[buttonIndex])/Math.log(2)); //Find cents difference based on divisions chosen; centsPerOct*log2(newFreq/refFreq)
}
