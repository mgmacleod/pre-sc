SynthDef.new(\spark,
{|amp=1, sus=1, pan=0, freq=0, vib=0, fmod=0, rate=0, bus=0|
var osc, env;
freq = In.kr(bus, 1);
freq = freq + fmod;
amp=(amp + 1e-05);
freq=[freq, (freq + LFNoise2.ar(50).range(-2, 2))];
osc=((LFSaw.ar((freq * 1.002), iphase: Saw.ar(0.1)) * 0.3) + (LFSaw.ar(freq, iphase: Saw.ar(0.1)) * 0.3));
osc=(((osc * Line.ar(amp, (amp / 10000), (sus * 1.5))) * 0.3) * Line.ar(0.01, 1, (sus * 0.033)));
osc = Mix(osc) * 0.5;
osc = Pan2.ar(osc, pan);
	ReplaceOut.ar(bus, osc)}).add;
