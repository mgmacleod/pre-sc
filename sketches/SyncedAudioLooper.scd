/*
A synced audio looper in SuperCollider

Yoinked from http://jeremah.co.uk/blog/permalink/a_synced_audio_looper_in_supercollider
*/

(
// definition of the looper
SynthDef(\looper, {
    // need a buffer to listen to and an input for the loop trigger
    arg bufnum, t_reset=0;

    // variables for the existing signal in the loop, the new input,
    // the output signal and the recording head position
    var inputSig, outputSig, existingSig, recHead;

    // get the input signal
    inputSig = In.ar(0);

    // generate the recording (also playback) position
    recHead = Phasor.ar(t_reset, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum));

	// print the recHead position
	recHead.poll;

    // read the existing signal from the loop
    existingSig = BufRd.ar(1, bufnum, recHead);

    // put the existing signal plus the new signal into the loop
    BufWr.ar(inputSig + existingSig, bufnum, recHead);

    // play back signal we got from the loop before the writing operation
    Out.ar(0, existingSig);
}).add;
)

(
// a crappy instrument to test with
SynthDef(\ping, {
    arg freq;
    var sig;
    sig = SinOsc.ar(freq) * 0.5;
    sig = EnvGen.kr(Env.perc(0.05, 2), doneAction:2) * sig;
    Out.ar(0, sig);
}).add;
)
// create a big empty buffer (20 secs is enough for me)
b = Buffer.alloc(s, 20 * s.sampleRate, 1);

(
// listen for a an OSC message indicating that we've reached the loop point
p = OSCresponderNode(nil, '/newbar', {|t, r, msg| ~looper.set(\t_reset, 1)}).add;

// listen for OSC triggering the test instrument
o = OSCresponderNode(nil, '/newnote', {
    |t, r, msg| msg[1].postln; Synth.new(\ping, [\freq, msg[1].midicps])
}).add;
)
// create an instance of the looper
~looper = Synth.new(\looper, [\bufnum, b.bufnum]);