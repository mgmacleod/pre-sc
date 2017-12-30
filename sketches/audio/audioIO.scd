// Audio I/O
/*
Basic flow:

Raw audio comes in from the hardware buses (0 - nin).
We grab it (for science) and write to internal buses

My main system has 8 in, 8 out (of which I use 0, 1, (2, 3), 4, 5).

So let's get 0 and 1 on a bus (left and right channels of guitar rig 1)
(optional: 2, 3 on a bus for guit rig 2)
and 4, 5 on separate buses (mics 1 and 2)

We'll want some pre-processing on some channels: Compression and EQing on mics

*/
s.boot;
a = ();

a.isAwesome = true;


// Set some global variables
(
~nin = s.options.numInputBusChannels;
~nout = s.options.numOutputBusChannels;

~mstInBus = Bus.audio(s, ~nin);
~mstOutBus = Bus.audio(s, ~nout);

)


// Make some SynthDefs
(
// Copy the raw input to a master bus
// We assume the output bus number (outBus) corresponds to a properly configured audio bus
SynthDef.new(\audioMasterIn, {
	arg nin, outBus;
	var sig;
	sig = SoundIn.ar((0..nin));

	Out.ar(outBus, sig);
});


SynthDef.new(\audioMonitor, {
	arg nin, nout;
	var ins, outs;
	ins = nin.do({|i|
		ins = Array.newClear(nin);

	});

});


)


