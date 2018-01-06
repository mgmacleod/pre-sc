//////////////////////////////////////////////
// «bouncy-ball delay» by snappizz
// delay effect with accelerating echoes
// http://sccode.org/1-56v


~buf = Buffer.alloc(s, s.sampleRate * 5);

(
{
    var trig, freq;
    var dry, snd, phase, iois;
    var cumulDelay;
    var decayFactor, lpfCutoff, numEchoes, ioiScale, ioiDecayFactor;

    // play with these!
    decayFactor = 0.65;
    lpfCutoff = 500;
    numEchoes = 16;
    ioiScale = 0.4;
    ioiDecayFactor = 0.75;

    // example input -- you can substitute other stuff here
    trig = Dust.ar(1);
    dry = Pulse.ar(100 * TIRand.ar(1, 12, trig));
    dry = dry * Decay2.ar(trig, 0.01, 0.2);

    phase = DelTapWr.ar(~buf, dry);
    iois = Array.geom(numEchoes, ioiScale, ioiDecayFactor);
    cumulDelay = iois.sum;
    (cumulDelay > ~buf.duration).if {
        Error("use a larger buffer").throw;
    };
    snd = Silent.ar;
    iois.reverse.do { |ioi|
        snd = (snd + DelTapRd.ar(~buf, phase, cumulDelay, interp: 4)) * decayFactor;
        // one-pole lowpass -- LPF was too aggressive
        snd = OnePole.ar(snd, lpfCutoff / SampleRate.ir);
        cumulDelay = cumulDelay - ioi;
    };
    snd = snd + dry;

    snd * 0.5!2;
}.play;

// contributors so far: Nathan Ho
)