SynthDef.new(\scatter,
{|amp=1, sus=1, pan=0, freq=0, vib=0, fmod=0, rate=0, bus=0|
var osc, env;
freq = In.kr(bus, 1);
freq = freq + fmod;
osc=((Saw.ar(freq, mul: (amp / 8)) + VarSaw.ar([(freq + 2), (freq + 1)], mul: (amp / 8))) * LFNoise0.ar(rate));
env=EnvGen.ar(Env.linen(attackTime: 0.01,releaseTime: (sus / 2),level: (sus / 2),curve: 0), doneAction: 0);
osc=(osc * env);
osc = Mix(osc) * 0.5;
osc = Pan2.ar(osc, pan);
	ReplaceOut.ar(bus, osc)}).add;
