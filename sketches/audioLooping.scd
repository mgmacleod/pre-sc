/*
A first sketch for audio looping
*/
/////////////////////////////////////////////////////////////////////////////////////////////////

// global vars

(
~clockBus = Bus.audio(s,1);
~recStartBus = Bus.control(s, 1);
~onsetStartBus = Bus.control(s, 1);
~alwaysOnBus = Bus.control(s, 1);
~analysisClockBus = Bus.audio(s,1);
~duffAudioBus = Bus.audio(s,1);

~tempo = 120;
~timeSig = 4;
~bufferTime = 40;
~oneBeat = (s.sampleRate / (~tempo/60)).round;
~recBuf = Buffer.alloc(s, ~oneBeat*~bufferTime, 1);
~loopBufs = List[];
~duffBuf = Buffer.alloc(s, 1024);
~loopSynths = List[];
~onsetFrames = List[];
~onsetsList = List[];
~currentLoopIndex = 0;

~nowRecording = false;

~beatCounter = 0;
~totalRecBeats = 0;
)




(
// SynthDefs

//Time Keeper SynthDef
SynthDef(\clickTrack) { |buf, tempo, oneBeat, timeSig, outClock, recTrigger=0, outStartRecBus, onsetTrigger=0, outStartOnsetBus, beepVol=1|
	var phase;
	var barTrig, barSTrig;
	var beatTrig, beatSTrig;
	var beep, beepEnvFunc, env1, env2;

	phase = Phasor.ar(0, BufRateScale.kr(buf), 0, inf, 0);

	beep = [SinOsc.ar(2000,0,0.1), SinOsc.ar(1000,0,0.1)]*beepVol;

	beepEnvFunc = {|trig| EnvGen.ar(Env.asr(0.01,1,0.01, \sine), trig)};

	barTrig = Trig.ar(phase+1 % (oneBeat*timeSig));
	beatTrig = Trig.ar(phase+1 % oneBeat);

	barSTrig = SendTrig.kr(A2K.kr(barTrig), 1, timeSig);
	beatSTrig = SendTrig.kr(A2K.kr(beatTrig), 2, 1);

	//Output clock data
	Out.ar(outClock, phase);

	//Output recStart trigger
	Out.kr(outStartRecBus, Latch.kr(recTrigger, beatOneTrig));

	//Output loopStart trigger
	Out.kr(outStartOnsetBus, Select.kr(onsetTrigger, [DC.kr(0), A2K.kr(crotchetTrig)]));

	//Output metronome Beeps
	Out.ar(0, Pan2.ar(Mix.new([beep[0]*beepEnvFunc.(A2K.kr(barTrig)), beep[1]*beepEnvFunc.(A2K.kr(beatTrig))]), 1));

}.send(s);

//Recording SynthDef
SynthDef(\GCRec) { |sigIn=0, out=0, clockIn, bufnum, trigger, stopRec=0, oneBeat|
	var inSig;
	var clock;
	var phase;
	var phase2;
	var env;
	var sig;
	var trig;
	var trig2;
	var imp, delimp;
	var lag;

	inSig = SoundIn.ar(sigIn);
	clock = In.ar(clockIn);
	phase = clock%BufFrames.kr(bufnum);
	phase2 = (clock%oneBeat)+(s.sampleRate/50)%oneBeat;


	trig = In.kr(trigger);

	trig2 = (Trig1.kr(phase2, 0.2)-1).abs;

	env = EnvGen.ar(Env.asr(0.01, 1, 0.02, 'welch'), Select.kr(stopRec, [trig, trig2]));

	sig = BufWr.ar(inSig*env, bufnum, phase, 1);

	imp = Impulse.kr(10);
	delimp = Delay1.kr(imp);
	// measure rms and Peak
	SendReply.kr(imp, '/tr', [Amplitude.kr(inSig), K2A.ar(Peak.ar(inSig, delimp).lag(0, 3))], 0);

	Out.ar(out, inSig*env)
}.send(s);

//Simple looping synth
SynthDef(\GCPlay) { |outBus, bufnum, trigBus, clockOut, amp=1, pan=0, index, ampLag=0, panLag=0|
	var sig;
	var phase;
	var trigIn;
	var select;
	var latch;
	var imp, delimp;

	trigIn = In.kr(trigBus);
	latch = Latch.kr(trigIn, trigIn);

	phase = Phasor.ar(latch, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum), 0);

	sig = BufRd.ar(1, bufnum, phase, 1, 4);

	select = Select.kr(latch, [trigIn, Lag.kr(amp, ampLag)]);

	imp = Impulse.kr(10);
	delimp = Delay1.kr(imp);
	// measure rms and Peak
	//SendReply.kr(imp, '/mix', [Amplitude.kr(sig*select), K2A.ar(Peak.ar(sig*select, delimp).lag(0, 3))], index);

	//Output clock data
	Out.ar(clockOut, phase);
	//Output playback signal
	Out.ar(outBus, Pan2.ar(sig*select, Lag.kr(pan, panLag)));
}.send(s);

SynthDef(\onBus) { |outBus|
	Out.kr(outBus,
		DC.kr(1);
	);
}.send(s);

SynthDef(\offBus) { |outBus|
	Out.kr(outBus,
		DC.kr(0);
	);
}.send(s);

)


// OSCdef: dummy for now
(
OSCdef.new(\trig, {
	arg msg, time, addr, port;
	msg[1].postln;
}, '/tr').add;

)

// create the init synths
(
s.makeBundle(0.2, {
	//Instantiate metronome synth
	~metroSynth = Synth(\clickTrack, [	\buf, ~recBuf, \outClock, ~clockBus, \tempo, ~tempo, \timeSig, ~timeSig, \oneBeat, ~oneBeat,
		\recTrigger, 0, \outStartRecBus, ~recStartBus, \onsetTrigger, 0, \outStartOnsetBus, ~onsetStartBus, \beepVol, 1]);
	//Instantiate recording synth
	~recSynth = Synth.after(~metroSynth, \GCRec, [\bufnum, ~recBuf, \clockIn, ~clockBus, \trigger, ~recStartBus, \oneBeat, ~oneBeat]);

	~onSynth = Synth(\onBus, [\outBus, ~alwaysOnBus]);

});
)
