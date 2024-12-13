// Synths for Alt Tuning Keyboard DEBUG CODE FOR SIMPLE KEYBOARD
// Rae Quarles - 11/6/24

//Now allows for control of playing notes via OSC
//Supercollider no longer does any math, just takes in a frequency from the functions in processing

//Boot the server
s.boot;

//Find your localhost
NetAddr.localAddr;

//A synthdef to sound like a piano
(
SynthDef(\pianoKey, {
    arg freq = 440, amp = 0.5, sustain = 60, attack = 0.01, release = 0.6, gate = 1;
	var signal, env, output;

    signal = SinOsc.ar(freq, 0, 1);   // Create the signal (Sine wave)
	signal = signal + (SinOsc.ar(freq*2, 0, 1)*0.4); //Give it some even harmonics to sound like a piano
	signal = signal + (SinOsc.ar(freq*4, 0, 1)*0.1);
	signal = LPF.ar(signal, 18000); //Filter it
	env = EnvGen.kr(Env.asr(attack, 1, release), gate, doneAction: 2); //ADSR w gate
	output = signal * env * amp; // Combine signal and envelope, scale by amplitude
    Out.ar(0, output);  // Send the output to speakers
}).add;
)

//OSC def to start, change, and stop notes
(
OSCdef(\piano, {
    arg msg;

	var keyNum = msg[1], freq = msg[2], gate = msg[3], rel = msg[4];

    if (gate == 0) {  // If gate is closed, stop the note
        if (~x.notNil) {
            ~x.set(\gate, 0);  // Close the envelope
            ~x = nil;  // Clear reference once the synth is done
        }
	};
	if (gate == 1) {  // If gate is open, play / update note
		if (~x.isNil) { //If no note right now, make one
            ~x = Synth(\pianoKey, [\freq, freq, \release,  rel, \gate, 1]);  // Start new synth
        } { //If there is a note, update it
            ~x.set(\freq, freq, \release,  rel, \gate, 1);  // Update frequency
        }
    };
    msg.postln;  // Print the OSC message for debugging
}, "/key");
)