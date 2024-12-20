//V2 of java to js transition for finals
//It works but adding mouse control too

// VARS FOR GRAPHICS
let buttonCount = 15;      // Total number of buttons to create
let circleX = new Array(buttonCount).fill(false);           // X positions of each button's circle
let circleY = new Array(buttonCount).fill(false);           // Default Y Positions of each button's circle
let currentY = new Array(buttonCount).fill(false);          // Current Y positions of each button's circle
let lastY = new Array(buttonCount).fill(false);             // Last Y values of of mouseclick for each button
let circleColor = new Array(buttonCount).fill(false);         // Color for each button when pressed and released
let textColor = new Array(buttonCount).fill(false);           // Color for each button's text when pressed and released
let defaultCircleColor = [255, 15, 255, 15, 255, 0, 255, 15, 255, 15, 255, 15, 255, 0, 255];
let pressCircleColor = [233, 33, 233, 33, 233, 0, 233, 33, 233, 33, 233, 33, 233, 0, 233];
let topLabel = new Array(buttonCount).fill(false);    //Name of the interval were on (determined in draw())
let intervalLabel = ["Tonic", "m 2nd","M 2nd","m 3rd","M 3rd","Perf 4th","Aug 4th","Perf 5th","m 6th","M 6th","m 7th","M 7th","Octave"];  //Labels for when buttons arent pressed
let diameter;         // Width (Diameter) of each circle
let sliderColor = new Array(buttonCount).fill(false);         // Color of the slider behind each button

// VARS FOR SYNTHESIS
let osc = [];  //Array of oscillators
let gate = new Array(buttonCount).fill(false);                // Gate for each button, 1 = gate, 0 = stop
let tonic = 32.703;      //Holds the tonic (starting freq) (Lowest C)
let divisions = 12;      //Divisions for EDO
let oct = 4;             //Octave multiplier (default 4 - middle octave)
let freq = new Array(buttonCount).fill(false);              //Holds the frequencies for each key that we'll send via OSC
let refFreq = new Array(buttonCount).fill(false);           //Holds the reference frequencies in 12TET so we can place the button
let centsDif = new Array(buttonCount).fill(false);          //Holds the number of cents difference between each keys ref and real freq
let detuneDist = new Array(buttonCount).fill(false);        //Holds the amount of cents to detune

// VARS FOR CONTROLS
let tuning = 0;            //The tuning mode: 0 - Equal; 1 - Just; 2 - Pythagorean
let release = 0;         //Holds the sustain amount after release we'll send via OSC
let touchLatch = 0;    //Changes mode - touch = 0 or latch = 1

function setup() {
  createCanvas(windowWidth, windowHeight);              // Set the canvas size
  background(0);                 // Fill the background with black
  noStroke();
  
  // Calculate spacing and initial positions for each button
  let spacing = windowWidth / (buttonCount + 3); // Space each button evenly, with 2 button "slots" to the left
  diameter = windowWidth / 24;  //Width of each button so it scales
  for (let i = 0; i < buttonCount; i++) {
    circleX[i] = spacing * (i + 3);          // Set the x position for each button, (two spots over -> +1 (to increment up by 1) +2 (to start 2 spaces over)
    
    if (i % 2 == 0) {  //If its an even key (white)
      circleY[i] = 3 * windowHeight / 4;               // Default y position for each button (3/4 down)
      circleColor[i] = color(255);               // Set initial color to white
      sliderColor[i] = color(84, 78, 88);        // Set slider to l grey
      textColor[i] = color(0);                   // Set text to black
    } if (i % 2 != 0) {  //If key is odd/black
      circleY[i] = (3 * windowHeight / 4) - diameter*2;// Default y position for each black button (1/2 length of the slider up)
      circleColor[i] = color(15);                // Set initial color to dark grey
      sliderColor[i] = color(42, 39, 44);        // Set slider to dk grey
      textColor[i] = color(255);                 // Set text to white
    }
    
    currentY[i] = circleY[i];                // Initialize currentY to default y position on start up so it defaults to 12TET
    lastY[i] = 0;                            // Initialize lastY for each button
    gate[i] = 0;                             // Set gate state to "stop" initially
    topLabel[i] = intervalLabel[i];          // Int. top label to be interval
  }
  
  // Calculate default/reference freq in 12TET for each key
  for (let i = 0; i < buttonCount; i++) {
    equalTuning(i);        // Calculate each button's freq (no detune)
    refFreq[i] = freq[i];  // Assign each buttons ref freq to the found frequency from function
  }
  
  console.log("Use Keys 1/2/3 to select between Equal/Just/Pythagorean Tuning");
  console.log("Use 's' for long sustain, use 'r' for short sustain");
  console.log("Use '[' for touch mode, use ']' for latch mode");
}

function draw() {
  background(0);                    // Clear the screen to black each frame

  // Draw each button and its slider
  for (let i = 0; i < buttonCount; i++) {
    if (i != 5 && i!= 13) {  //If its a key that falls on a semitone: 
      fill(sliderColor[i]);              // Set color for the slider
      rect(circleX[i] - (diameter / 2), circleY[i] - (diameter * 2), diameter, diameter * 4, 28); // Draw slider bar
      fill(circleColor[i]);           // Set color for the button
      ellipse(circleX[i], currentY[i], diameter, diameter); // Draw draggable button 
      textSize(3*diameter/7);
      textAlign(CENTER);
      fill(textColor[i]);  //Set color for text
      text((Math.round(centsDif[i]*-10)/10), circleX[i], currentY[i] + (diameter/6));  //Draw the detune cents on the keys

      //Label the keys for usability
      textSize(2.2*diameter/7);
      fill(196, 195, 208);

      if (gate[i] === 1) {  //if the gate is open (currently playing), show the detune cents on top
        topLabel[i] = (Math.round(centsDif[i] * -10) / 10);   //Update to detune cents
      }

      text(String(topLabel[i]), circleX[i], circleY[i] - (2*diameter) - 5);  //Draw the text label for intervals above each slider
    }
  }
}

function windowResized() {
  resizeCanvas(windowWidth, windowHeight);
}

function keyPressed() {
  
  // Keys for tuning selection 1/2/3 for EDO/JUST/PYTH
  if (key === '1') {
    tuning = 0;
    for (let i = 0; i< buttonCount; i++) {
      equalTuning(i);  //Assign each buttons frequency to the cooresponding 12TET ref freq
      centsCalc(i);  //Send centsCalc which button and it will calculate the cents between that buttons new freq and the ref freq in EDO
    }
    updateKeys();    //Run funct to update key position
    console.log("Equal Temperament");
  } 
  
  if (key === '2') {
    tuning = 1;
    for (let i = 0; i< buttonCount; i++) {
      justTuning(i);        //Calculate freq[] based on just intonation
      centsCalc(i);  //Send centsCalc which button and it will calculate the cents between that buttons new freq and the ref freq in EDO
    }
    updateKeys();    //Run funct to update key position
    console.log("Just Temperament");
  } 
  
  if (key === '3') {
    tuning = 2;
    for (let i = 0; i< buttonCount; i++) {
      pythTuning(i);        //Calculate freq[] based on pyth intonation
      centsCalc(i);  //Send centsCalc which button and it will calculate the cents between that buttons new freq and the ref freq in EDO
    }
    updateKeys();    //Run funct to update key position
    console.log("Pythagorean Temperament");
  }
  
  if (key === '4') {
    tuning = 3;
    for (let i = 0; i< buttonCount; i++) {
      qcommaTuning(i);        //Calculate freq[] based on qcomma intonation
      centsCalc(i);  //Send centsCalc which button and it will calculate the cents between that buttons new freq and the ref freq in EDO
    }
    updateKeys();    //Run funct to update key position
    console.log("Quarter-Comma Meantone Temperament");
  }
      
// Keys for sustain control  
  if (key === 's') {
    release = 8.0;
    console.log("Long Sustain");
  } if (key === 'r') {
    release = 1.3;
    console.log("Short Sustain");
  }
  
// Keys for touch/latch control  
  if (key === '[') {
    touchLatch = 0;
    console.log("Latch Mode - Keys will stay in their dragged position");
  } if (key === ']') {
    touchLatch = 1;
    for (let i = 0; i< buttonCount; i++) {currentY[i] = circleY[i]; centsDif[i] = 0;}  //Reset to default freq for tuning
    console.log("Touch Mode - Keys will return to center line");
  }
}
  

function touchStarted() {
  // Check if the mouse press is within any of the buttons
  for (let t of touches) {    // Loop through all active touches
    for (let i = 0; i < buttonCount; i++) {
      if (i != 5 && i != 13) {  //Ignore the invisible keys
        if (isTouchingButton(t, i)) { // Check if touch is inside the circle
          pressButton(t.y, i);
        }
      }
    }
  }
}

function mousePressed() {
  // Check if the mouse press is within any of the buttons
  for (let i = 0; i < buttonCount; i++) {
    if (i != 5 && i != 13) {  //Ignore the invisible keys
      if (isClickingButton(i)) { // Check if click is inside the circle
        pressButton(mouseY, i);
      }
    }
  }
}

function touchMoved() {
  // Check if any button is being dragged
  for (let t of touches) {    // Loop through all active touches
    for (let i = 0; i < buttonCount; i++) {
      if (gate[i] == 1) {   // Only update position if button gate is open

        // Limit position to stay within the slider
        let upperBound = circleY[i] - diameter * 1.5; // Top of the slider
        let lowerBound = circleY[i] + diameter * 1.5; // Bottom of the slider
        
        if (t.y >= upperBound && t.y <= lowerBound) {  
        currentY[i] = t.y;  // Update y position to follow mouse within bounds
      } else if (t.y < upperBound) {  // If dragged above the upper bound
        currentY[i] = upperBound;        // Set to upper bound
      } else if (t.y > lowerBound) {  // If dragged below the lower bound
        currentY[i] = lowerBound;        // Set to lower bound
      }

        // Calculate the detuning based on the distance from the default position
        detuneDist[i] = map((currentY[i] - circleY[i]) * -1, -diameter * 1.5, diameter * 1.5, -50, 50);
        freq[i] = refFreq[i] * Math.pow(2, detuneDist[i] / (divisions * 100));
        centsCalc(i);  //Calculate cents for display
        centsDif[i] = (centsDif[i]*-1);  //Swap the sign (idk why this is happening, bandaid)
        
        //oscillators[i].freq(freq[i] + detuneDist[i]);  //update the frequency
      }
    }
  }
}

function mouseDragged() {
  // Check if any button is being dragged
  for (let i = 0; i < buttonCount; i++) {
    if (gate[i] == 1) {   // Only update position if button gate is open

      // Limit position to stay within the slider
      let upperBound = circleY[i] - diameter * 1.5; // Top of the slider
      let lowerBound = circleY[i] + diameter * 1.5; // Bottom of the slider
      
      if (mouseY >= upperBound && mouseY <= lowerBound) {  
        currentY[i] = mouseY;  // Update y position to follow mouse within bounds
      } else if (mouseY < upperBound) {  // If dragged above the upper bound
        currentY[i] = upperBound;        // Set to upper bound
      } else if (mouseY > lowerBound) {  // If dragged below the lower bound
        currentY[i] = lowerBound;        // Set to lower bound
      }

      // Calculate the detuning based on the distance from the default position
      detuneDist[i] = map((currentY[i] - circleY[i]) * -1, -diameter * 1.5, diameter * 1.5, -50, 50);
      freq[i] = refFreq[i] * Math.pow(2, detuneDist[i] / (divisions * 100));
      centsCalc(i);  //Calculate cents for display
      centsDif[i] = (centsDif[i]*-1);  //Swap the sign (idk why this is happening, bandaid)
    
      //oscillators[i].freq(freq[i] + detuneDist[i]);  //update the frequency
    }
  }
}

function touchEnded() {  // Reset each button when mouse is released
  for (let t of touches) {    // Loop through all active touches
    for (let i = 0; i < buttonCount; i++) {
      if (gate[i] == 1) {                  // Only reset if button was active (gate was open)
        resetButton(i);
      }
    }
  }
}

function mouseReleased() {  // Reset each button when mouse is released
  for (let i = 0; i < buttonCount; i++) {
    if (gate[i] == 1) {                  // Only reset if button was active (gate was open)
      resetButton(i);      
    }
  }
}

// A function to check if a touch in the array is pressing a button, then links that particular touch with the button it's pressing in the functions above
function isTouchingButton(touch, buttonIndex) {
  return dist(circleX[buttonIndex], currentY[buttonIndex], touch.x, touch.y) < (diameter / 2);
}

//Another function to check if the button is being clicked with the mouse
function isClickingButton(buttonIndex) {
  return dist(circleX[buttonIndex], currentY[buttonIndex], mouseX, mouseY) < diameter / 2;
}

// To update key positions when tuning is changed
function updateKeys(){
  // Update the key positions to reflect current tuning
   for (let i = 0; i< buttonCount; i++) {  //Move each button based on cents difference from reference in 12TET
    currentY[i] = circleY[i] + map(centsDif[i], -50, 50, -2*diameter, 2*diameter);  //Move current y to reflect cents +/- (mapped so slider top is +50 and bottom is -50)
  }
}

//For pressing buttons to start the note
function pressButton(yCoord, i){
  lastY[i] = yCoord;            // Remember the y value where we first touched
  gate[i] = 1;                  // Set gate to "1" to indicate button is active
  circleColor[i] = pressCircleColor[i];  //Update the color to show it's pressed
//  topLabel[i] = (Math.round(centsDif[i] * -10) / 10);   //Update to detune cents

  //playNote(i);  //Play the note!
}

//For resetting buttons
function resetButton(i){ 
  gate[i] = 0;                       // Set gate state to "closed"
  circleColor[i] = defaultCircleColor[i];  //Update the color to show it's pressed
  topLabel[i] = intervalLabel[i];   //Update to detune cents
  
  //For touch/latch
  if (touchLatch == 1){
    currentY[i] = circleY[i];        // Reset y position to default
    centsDif[i] = 0;
  } if (touchLatch == 1) {
  }                          // Otherwise do nothing

  //stopNote(i);  //Stop the note
}

// A function that calculates equal tuning with variable divisions of the octave
function equalTuning(buttonIndex) {  //detuneCents is the scaledDistance from the sliders
  let toneIntervals = [0, 1, 2, 3, 4, 0, 5, 6, 7, 8, 9, 10, 11, 0, 12];  //New float array of tone/semitone intervals for diatonic major scale!
  //divisions = 12.;  // Default 12 divisons of the octave, change and take as arg in later version?
  freq[buttonIndex] = tonic * (Math.pow(2, toneIntervals[buttonIndex] / divisions) *oct);  //Frequency is the tonic * 2 ^ (whatever button # aligns w tone array) / divisions as specified 
}  //End brace for equal tuning

function justTuning(buttonIndex) {
  let ratios = [1, 16/15, 10/9, 6/5, 5/4, 0, 4/3, 45/32, 3/2, 8/5, 5/3, 9/5, 15/8, 0, 2];  //New float array of just intervals for diatonic major scale
  freq[buttonIndex] = tonic * (ratios[buttonIndex]*oct);  //Frequency is the tonic * cooresponding intervals * octave multiplier
}

function pythTuning(buttonIndex) {
  let ratios = [1, 256/243, 9/8, 32/27, 81/64, 0, 4/3, 729/512, 3/2, 128/81, 27/16, 16/9, 243/128, 0, 2];  //New float array of pythagorean intervals for diatonic major scale
  freq[buttonIndex] = tonic * (ratios[buttonIndex]*oct);  //Frequency is the tonic * cooresponding intervals * octave multiplier
}

function qcommaTuning(buttonIndex) {
  let ratios = [1, 1.06998, 1.11803, 1.19627, 1.24999, 0, 1.33747, 1.39753, 1.49534, 1.59999, 1.67184, 1.78884, 1.86918, 0, 1.99998];
  freq[buttonIndex] = tonic * (ratios[buttonIndex]*oct);  //Frequency is the tonic * cooresponding intervals * octave multiplier
}

// Cents Calculator to move circleY position of each key-button to the location of the new tuning
function centsCalc(buttonIndex) {  // newFreq is the frequency we are placing on a key-button, eqTempFreq is the reference "default" freq
 centsDif[buttonIndex] = 100*divisions * (Math.log(freq[buttonIndex]/refFreq[buttonIndex])/Math.log(2)); //Find cents difference based on divisions chosen; centsPerOct*log2(newFreq/refFreq)
}
