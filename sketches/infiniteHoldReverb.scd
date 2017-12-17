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

~infiniteHoldReverb.set(\feedback, 1);
