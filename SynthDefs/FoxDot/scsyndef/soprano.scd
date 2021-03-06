SynthDef.new(\soprano,
{|amp=1, sus=1, pan=0, freq=0, vib=5, fmod=0, rate=0, bus=0, verb=0.5|
var osc, env;
freq = In.kr(bus, 1);
freq = freq + fmod;
sus=(sus * 1.75);
amp=(amp / 2);
osc=(SinOsc.ar((freq * 3), mul: amp) + SinOscFB.ar((freq * 3), mul: (amp / 2)));
env=EnvGen.ar(Env(times: [(sus / 2), (sus / 2)],levels: [0, amp, 0],curve: 'lin'), doneAction: 0);
osc=(osc * env);
osc = Mix(osc) * 0.5;
osc = Pan2.ar(osc, pan);
	ReplaceOut.ar(bus, osc)}).add;
