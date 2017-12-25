// Audio I/O


// Set some global variables
(
~numInputs = 2;
~numOutputs = 2;




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
	/*
	nin.do({


	});*/


});


SynthDef.new(\audioMonitor, {
	arg nin, nout;
	var ins, outs;
	ins = nin.do({|i|
		ins = Array.newClear(nin);

	});

});


)



o = Bus.audio(s, ~numInputs);
