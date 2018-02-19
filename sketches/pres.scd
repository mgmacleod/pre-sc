/*
Some feedback experiments.  PREs, by definition :)
*/


(
SynthDef.new(\fb1, {
	arg inBus=4, outBus=0, feedback=0.5;
	var sig, fbNode, local;

	sig = SoundIn.ar(inBus);
	fbNode = FbNode(1);
	local = sig + fbNode;
	// 15.do {local = AllpassN.ar(local, 0.06, Rand(0.001, 0.06), 3)};

	fbNode.write(local*feedback);

	Out.ar(outBus, sig+local);
}).add;

)

a = Synth.new(\fb1);
a.set(\feedback, 0.8)


