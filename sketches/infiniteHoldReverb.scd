(
~infiniteHoldReverb = {
    arg feedback=1;
    var sig, local;

    //establish input signal
	sig = SoundIn.ar([0,1]);
    local = LocalIn.ar(2)+sig;

    // apply reverb
    15.do {local = AllpassN.ar(local, 0.06, Rand(0.001, 0.06), 3)};

    // complete feedback loop -- send audio back to LocalIn
    LocalOut.ar(local*feedback);

    // non-feedback output to speakers
    Out.ar(0, sig+local);

}.play;

)

~infiniteHoldReverb.set(\feedback, 0.8);


// Version using FbNode instead of LocalIn/LocalOut
(
~feedbackReverb = {
	arg feedback = 1;
	var sig, fbNode, local;

	sig = SoundIn.ar([0,1]);
	fbNode = FbNode(2);
	local = sig + fbNode;
	15.do {local = AllpassN.ar(local, 0.06, Rand(0.001, 0.06), 3)};

	fbNode.write(local*feedback);

	Out.ar(0, sig+local);

}.play;

)

~feedbackReverb.set(\feedback, 0);