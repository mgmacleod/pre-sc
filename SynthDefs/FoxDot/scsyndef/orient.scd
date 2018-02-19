SynthDef.new(\orient,
{|amp=1, sus=1, pan=0, freq=0, vib=0, fmod=0, rate=0, bus=0, room=10, verb=0.7|
var osc, env;
freq = In.kr(bus, 1);
freq = freq + fmod;
osc=(LFPulse.ar(freq, 0.5, 0.25, 0.25) + LFPulse.ar(freq, 1, 0.1, 0.25));
env=EnvGen.ar(Env.perc(attackTime: 0.01,releaseTime: sus,level: amp,curve: 0), doneAction: 0);
osc=(osc * env);
osc = Mix(osc) * 0.5;
osc = Pan2.ar(osc, pan);
	ReplaceOut.ar(bus, osc)}).add;