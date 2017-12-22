// Audio I/O

(
SynthDef.new(\audioMasterIn, {
	arg nin, outBus;
	var sig;
	sig = SoundIn.ar((0..nin));

	Out.ar(outBus, sig);
	/*
	nin.do({


	});*/


});


)

(
SynthDef.new(\audioMonitor, {
	arg nin, nout;
	var ins, outs;
	ins = nin.do({|i|
		ins = Array.newClear(nin);

	});

});


)