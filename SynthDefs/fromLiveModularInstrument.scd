// SynthDefs yoinked from LiveModularInstrument (https://github.com/spluta/LiveModularInstrument)



SynthDef("ampFollower_mod", {arg inBus0, inBus1, outBus, ampMult = 1, whichState = 0, gate = 1, pauseGate = 1;
	var in0, in1, amp, env, out, impulse, dust, whichEnv, pauseEnv;

	in0 = In.ar(inBus0, 8);
	in1 = In.ar(inBus1, 1);
	amp = LagUD.kr(Amplitude.kr(in1)*ampMult, 0.05, 0.15);

	whichEnv =Select.kr(whichState, [1, amp]);

	out = (in0*whichEnv);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, out*env*pauseEnv);
}).add;


SynthDef("ampInterrupter_mod", {arg inBus0, inBus1, outBus, thresh = 1, whichState = 0, gate = 1, pauseGate = 1;
	var in0, in1, amp, env, out, impulse, dust, processOn, pauseEnv;

	in0 = In.ar(inBus0, 8);
	in1 = In.ar(inBus1, 1);

	amp = LagUD.kr(Amplitude.kr(in1), 0.05, 0.15);

	processOn = Select.kr(whichState, [0, amp]);

	out = Select.ar((processOn>thresh), [in0, in1]);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, out*env*pauseEnv);
}).add;


SynthDef("ampMod_mod", {arg inBus, outBus, pulseRate0 = 1, pulseRate1 = 1, onBypass=0, gate=1, pauseGate=1;
	var env, out, impulse, dust, mod, pauseEnv;

	impulse = Impulse.kr(pulseRate0);
	dust = Dust.kr(pulseRate1);

	mod = Lag.kr(Select.kr(onBypass, [1, Stepper.kr(impulse+dust, 0, 0, 1, 1, 0)]), 0.02);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, In.ar(inBus, 8)*env*mod*pauseEnv);
}).add;


SynthDef("largeEnvShifter_mod",{arg outBusNum, attack, decay, gate;
	var env, out;

	env = Env.asr(attack,1,decay);
	Out.kr(outBusNum, EnvGen.kr(env, gate, doneAction: 2));
}).add;


SynthDef(\playBufShifter_mod, {arg bufNum, outBusNum, length, gate = 1.0;
	var out, env;

	env = Env.new([0.001, 1, 1, 0.001], [3, length-6.1, 3], 'sine');
	out = EnvGen.kr(env, gate, doneAction: 2)*PlayBuf.ar(1, bufNum);
	Out.ar(outBusNum, out);
}).add;


SynthDef(\writeBufShifter_mod, {arg inBusNum=0, bufNum, rate=1, length;
	var in, out, env;
	in = In.ar(inBusNum);
	env = Env.new([0,1,1,0],[0.1, length-0.2, 0.1], 'linear');
	out =  BufWr.ar(EnvGen.ar(env,1.0,doneAction: 2)*in, bufNum, Phasor.ar(0, BufRateScale.kr(bufNum) * rate, 0, BufFrames.kr(bufNum)), 0);
}).add;


SynthDef(\shifterX_mod, {arg inBusNum, outBus1, outBus2, outBus3, outBus4, length, delayTime, windowSize, pitchRatio, 				pitchDisp, xStart, xEnd, yStart, yEnd, largeEnvBusNum;
	var in, in2, out1, out2, out3, out4, addToSlope, env, bigEnv, largeEnv;

	addToSlope = length/4;
	env = Env.new([0.001,1,1,0.001], [addToSlope+1,length-(2+(2*addToSlope)),1+addToSlope], 'linear');
	bigEnv = Env.new([0.001, 1, 1, 0.001], [0.001, length + addToSlope + delayTime +2, 0.001], 'linear');

	largeEnv = In.kr(largeEnvBusNum, 1);

	in = In.ar(inBusNum, 1);
	in2 =  in*EnvGen.kr(bigEnv, doneAction: 2)*EnvGen.kr(env, doneAction: 0)*largeEnv;

	# out1, out2, out3, out4 = Pan4.ar(
		PitchShift.ar(DelayL.ar(in2, 0.5, delayTime), windowSize, pitchRatio, pitchDisp),					Line.kr(xStart, xEnd, length+2.1+delayTime),					Line.kr(yStart, yEnd, length+2.1+delayTime)
	);

	Out.ar(outBus1, out1);
	Out.ar(outBus2, out2);
	Out.ar(outBus3, out3);
	Out.ar(outBus4, out4);
}).add;

SynthDef("tapeFeedback_mod", {arg inBus, outBus, length, startLine, endLine;
	var local, in, amp, initEnv, envLength, delayTime, env, vol;

	in = In.ar(inBus);

	//Out.ar(0, in);

	in = Compander.ar(in, in, thresh: 0.5, slopeBelow: 1, slopeAbove: 0.5, clampTime: 0.01,relaxTime: 0.01);

	amp = Amplitude.kr(in);
	//in = in * (amp > 0.02); // noise gate

	local = LocalIn.ar(1);

	local = DelayN.ar(local, 0.5, Line.kr(startLine, endLine, length));

	local = LeakDC.ar(local);
	local = ((local + in) * 1.25).softclip;

	LocalOut.ar(local);

	env = EnvGen.kr(Env.sine(length), doneAction:2);

	Out.ar(outBus, local * 0.1 * env);
}).add;


SynthDef("busToOuts2_mod", {arg outBus, bus1, bus2, bus3, bus4, bus5, bus6, bus7, bus8, bus1a, bus2a, bus3a, bus4a, bus5a, bus6a, bus7a, bus8a, fade, volBus, gate=1, pauseGate = 1;
	var out, out1, out2, out3, out4, out5, out6, out7, out8, fade2, pauseEnv, env, vol;

	vol = In.kr(volBus);

	fade2 = Lag.kr(fade, 0.05);

	out1 = XFade2.ar(In.ar(bus1), In.ar(bus1a), fade2);
	out2 = XFade2.ar(In.ar(bus2), In.ar(bus2a), fade2);
	out3 = XFade2.ar(In.ar(bus3), In.ar(bus3a), fade2);
	out4 = XFade2.ar(In.ar(bus4), In.ar(bus4a), fade2);
	out5 = XFade2.ar(In.ar(bus5), In.ar(bus5a), fade2);
	out6 = XFade2.ar(In.ar(bus6), In.ar(bus6a), fade2);
	out7 = XFade2.ar(In.ar(bus7), In.ar(bus7a), fade2);
	out8 = XFade2.ar(In.ar(bus8), In.ar(bus8a), fade2);

	out = Pan2.ar(out1,1,0.5)+ Pan2.ar(out2,-0.75,0.5)+ Pan2.ar(out3,0.75,0.5)+ Pan2.ar(out4,-0.6,0.5)+ Pan2.ar(out5,0.6,0.5)+ Pan2.ar(out6,-0.2,0.5)+ Pan2.ar(out7,0.2,0.5)+Pan2.ar(out8,-1,0.5);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0.2,1,0.2), gate, doneAction:2);

	Out.ar(outBus, pauseEnv*env*LeakDC.ar(out*Lag.kr(vol, 0.05)));
}).add;

SynthDef("busToOuts4_mod", {arg outBus, bus1, bus2, bus3, bus4, bus5, bus6, bus7, bus8, bus1a, bus2a, bus3a, bus4a, bus5a, bus6a, bus7a, bus8a, fade, volBus, gate=1, pauseGate = 1;
	var outa, outb, out1, out2, out3, out4, out5, out6, out7, out8, fade2, pauseEnv, env, vol;

	vol = In.kr(volBus);

	fade2 = Lag.kr(fade, 0.05);

	out1 = XFade2.ar(In.ar(bus1), In.ar(bus1a), fade2);
	out2 = XFade2.ar(In.ar(bus2), In.ar(bus2a), fade2);
	out3 = XFade2.ar(In.ar(bus3), In.ar(bus3a), fade2);
	out4 = XFade2.ar(In.ar(bus4), In.ar(bus4a), fade2);
	out5 = XFade2.ar(In.ar(bus5), In.ar(bus5a), fade2);
	out6 = XFade2.ar(In.ar(bus6), In.ar(bus6a), fade2);
	out7 = XFade2.ar(In.ar(bus7), In.ar(bus7a), fade2);
	out8 = XFade2.ar(In.ar(bus8), In.ar(bus8a), fade2);

	outa = [out1, out3, out5, out7];
	outb = [out2, out4, out6, out8];

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0.2,1,0.2), gate, doneAction:2);

	Out.ar(outBus, pauseEnv*env*LeakDC.ar((outa+outb)*Lag.kr(vol, 0.05)));
}).add;

SynthDef("busToOuts8_mod", {arg outBus, bus1, bus2, bus3, bus4, bus5, bus6, bus7, bus8, bus1a, bus2a, bus3a, bus4a, bus5a, bus6a, bus7a, bus8a, fade, volBus, gate=1, pauseGate = 1;
	var out, out1, out2, out3, out4, out5, out6, out7, out8, fade2, pauseEnv, env, vol;

	vol = In.kr(volBus);

	fade2 = Lag.kr(fade, 0.05);

	out1 = XFade2.ar(In.ar(bus1), In.ar(bus1a), fade2);
	out2 = XFade2.ar(In.ar(bus2), In.ar(bus2a), fade2);
	out3 = XFade2.ar(In.ar(bus3), In.ar(bus3a), fade2);
	out4 = XFade2.ar(In.ar(bus4), In.ar(bus4a), fade2);
	out5 = XFade2.ar(In.ar(bus5), In.ar(bus5a), fade2);
	out6 = XFade2.ar(In.ar(bus6), In.ar(bus6a), fade2);
	out7 = XFade2.ar(In.ar(bus7), In.ar(bus7a), fade2);
	out8 = XFade2.ar(In.ar(bus8), In.ar(bus8a), fade2);

	out = [out1, out2, out3, out4, out5, out6, out7, out8];

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0.2,1,0.2), gate, doneAction:2);

	Out.ar(outBus, pauseEnv*env*LeakDC.ar(out*Lag.kr(vol, 0.05)));
}).add;

SynthDef("delayBomb2_mod", {arg buf, outBus, volBus;
	var out, env, env1, dur, vol;

	vol = In.kr(volBus);

	env = EnvGen.kr(Env.sine(Rand(0.5, 0.9), 1));

	out = PlayBuf.ar(1, buf, startPos: MouseX.kr*BufFrames.kr(buf))*env;

	dur = Rand(7.0, 11.0);

	env1 = EnvGen.kr(Env.new([0,1,0],[0.1, dur]), doneAction:2);

	Out.ar(outBus, Pan2.ar(CombC.ar(out, 0.3, Rand(0.1, 0.3), dur*4)*env1, Rand(-1,1), vol));

}).add;

SynthDef("delayBomb4_mod", {arg buf, outBus, volBus;
	var out, env, env1, dur, vol;

	vol = In.kr(volBus);

	env = EnvGen.kr(Env.sine(Rand(0.5, 0.9), 1));

	out = PlayBuf.ar(1, buf, startPos: MouseX.kr*BufFrames.kr(buf))*env;

	dur = Rand(7.0, 11.0);

	env1 = EnvGen.kr(Env.new([0,1,0],[0.1, dur]), doneAction:2);

	Out.ar(outBus, PanAz.ar(4, CombC.ar(out, 0.3, Rand(0.1, 0.3), dur*4)*env1, Rand(-1,1), vol));

}).add;

SynthDef("delayBomb8_mod", {arg buf, outBus, volBus;
	var out, env, env1, dur, vol;

	vol = In.kr(volBus);

	env = EnvGen.kr(Env.sine(Rand(0.5, 0.9), 1));

	out = PlayBuf.ar(1, buf, startPos: MouseX.kr*BufFrames.kr(buf))*env;

	dur = Rand(7.0, 11.0);

	env1 = EnvGen.kr(Env.new([0,1,0],[0.1, dur]), doneAction:2);

	Out.ar(outBus, PanAz.ar(8, CombC.ar(out, 0.3, Rand(0.1, 0.3), dur*4)*env1, Rand(-1,1), vol));

}).add;


SynthDef("bitCrusher2_Mod",{ arg inbus, outbus, sr1Bus, sr2Bus, distVolBus, sineVolBus, gate = 1, pauseGate = 1;
	var input, fx1, fx2, sines, sine0, sine1, sine2, sine3, sine4, fund, skip, freq, hasFreq, env, pauseEnv;
	var sr1, sr2, distVol, sineVol;

	sr1 = In.kr(sr1Bus);
	sr2 = In.kr(sr2Bus);
	distVol = In.kr(distVolBus);
	sineVol = In.kr(sineVolBus);

	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	input=In.ar(inbus, 1);
	fx1=Latch.ar(input.round(0.125),Impulse.ar(sr1));
	fx2=Latch.ar(input.round(0.1),Impulse.ar(sr2));

	#freq, hasFreq = Pitch.kr(fx1, ampThreshold: 0.02, median: 7);

	fund = TIRand.kr(7, 50, hasFreq);
	skip = TIRand.kr(1, 5, hasFreq);

	sine0 = SinOsc.ar(freq, 0, hasFreq);
	sine1 = SinOsc.ar(freq+(fund*skip), 0, hasFreq);
	sine2 = SinOsc.ar(freq+(2*fund*skip), 0, hasFreq);
	sine3 = SinOsc.ar(freq+(3*fund*skip), 0, hasFreq);
	sine4 = SinOsc.ar(freq+(4*fund*skip), 0, hasFreq);

	sines = Pan2.ar(sine0, TRand.kr(-1,1,hasFreq)) + Pan2.ar(sine1, TRand.kr(-1,1,hasFreq)) + Pan2.ar(sine2, TRand.kr(-1,1,hasFreq)) + Pan2.ar(sine3, TRand.kr(-1,1,hasFreq)) + Pan2.ar(sine4, TRand.kr(-1,1,hasFreq));

	Out.ar(outbus, sines*0.25*sineVol*env*pauseEnv);
	Out.ar(outbus,([fx1,fx2])*distVol*env*pauseEnv);
}).add;

SynthDef("bitCrusher4_Mod",{ arg inbus, outbus, sr1Bus, sr2Bus, distVolBus, sineVolBus, gate = 1, pauseGate = 1;
	var input, fx1, fx2, fx3, fx4, sines, sine0, sine1, sine2, sine3, sine4, fund, skip, freq, hasFreq, env, pauseEnv;
	var sr1, sr2, distVol, sineVol;

	sr1 = In.kr(sr1Bus);
	sr2 = In.kr(sr2Bus);
	distVol = In.kr(distVolBus);
	sineVol = In.kr(sineVolBus);
	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	input=In.ar(inbus, 1);
	fx1=Latch.ar(input.round(0.125),Impulse.ar(sr1));
	fx2=Latch.ar(input.round(0.1),Impulse.ar(sr2));
	fx3=Latch.ar(input.round(0.1125),Impulse.ar(sr1-50));
	fx4=Latch.ar(input.round(0.15),Impulse.ar(sr2+50));

	#freq, hasFreq = Pitch.kr(fx1, ampThreshold: 0.02, median: 7);

	fund = TIRand.kr(7, 50, hasFreq);
	skip = TIRand.kr(1, 5, hasFreq);

	sine0 = SinOsc.ar(freq, 0, hasFreq);
	sine1 = SinOsc.ar(freq+(fund*skip), 0, hasFreq);
	sine2 = SinOsc.ar(freq+(2*fund*skip), 0, hasFreq);
	sine3 = SinOsc.ar(freq+(3*fund*skip), 0, hasFreq);
	sine4 = SinOsc.ar(freq+(4*fund*skip), 0, hasFreq);

	sines = Pan4.ar(sine0, TRand.kr(-1,1,hasFreq), TRand.kr(-1,1,hasFreq)) + Pan4.ar(sine1, TRand.kr(-1,1,hasFreq), TRand.kr(-1,1,hasFreq)) + Pan4.ar(sine2, TRand.kr(-1,1,hasFreq), TRand.kr(-1,1,hasFreq)) + Pan4.ar(sine3, TRand.kr(-1,1,hasFreq), TRand.kr(-1,1,hasFreq)) + Pan4.ar(sine4, TRand.kr(-1,1,hasFreq), TRand.kr(-1,1,hasFreq));

	Out.ar(outbus, sines*0.25*sineVol*env*pauseEnv);
	Out.ar(outbus,([fx1,fx2,fx3,fx4])*distVol*env*pauseEnv);
}).add;

SynthDef("bitCrusher8_Mod",{ arg inbus, outbus, sr1Bus, sr2Bus, distVolBus, sineVolBus, gate = 1, pauseGate = 1;
	var input, fx1, fx2, fx3, fx4, fx5, fx6, fx7, fx8, sines, sine0, sine1, sine2, sine3, sine4, fund, skip, freq, hasFreq, env, pauseEnv;
	var sr1, sr2, distVol, sineVol;

	sr1 = In.kr(sr1Bus);
	sr2 = In.kr(sr2Bus);
	distVol = In.kr(distVolBus);
	sineVol = In.kr(sineVolBus);
	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	input=In.ar(inbus, 1);
	fx1=Latch.ar(input.round(0.125),Impulse.ar(sr1));
	fx2=Latch.ar(input.round(0.1),Impulse.ar(sr2));
	fx3=Latch.ar(input.round(0.1125),Impulse.ar(sr1-25));
	fx4=Latch.ar(input.round(0.15),Impulse.ar(sr2+25));
	fx5=Latch.ar(input.round(0.125),Impulse.ar(sr1-50));
	fx6=Latch.ar(input.round(0.1),Impulse.ar(sr2+50));
	fx7=Latch.ar(input.round(0.1125),Impulse.ar(sr1-75));
	fx8=Latch.ar(input.round(0.15),Impulse.ar(sr2+75));

	#freq, hasFreq = Pitch.kr(fx1, ampThreshold: 0.02, median: 7);

	fund = TIRand.kr(7, 50, hasFreq);
	skip = TIRand.kr(1, 5, hasFreq);

	sine0 = SinOsc.ar(freq, 0, hasFreq);
	sine1 = SinOsc.ar(freq+(fund*skip), 0, hasFreq);
	sine2 = SinOsc.ar(freq+(2*fund*skip), 0, hasFreq);
	sine3 = SinOsc.ar(freq+(3*fund*skip), 0, hasFreq);
	sine4 = SinOsc.ar(freq+(4*fund*skip), 0, hasFreq);

	sines = PanAz.ar(8, sine0, TRand.kr(-1,1,hasFreq)) +
	PanAz.ar(8, sine1, TRand.kr(-1,1,hasFreq)) +
	PanAz.ar(8, sine2, TRand.kr(-1,1,hasFreq)) +
	PanAz.ar(8, sine3, TRand.kr(-1,1,hasFreq)) +
	PanAz.ar(8, sine4, TRand.kr(-1,1,hasFreq));

	Out.ar(outbus, sines*0.25*sineVol*env*pauseEnv);
	Out.ar(outbus,([fx1,fx2,fx3,fx4,fx5,fx6,fx7,fx8])*distVol*env*pauseEnv);
}).add;


SynthDef("bitInterrupter2_Mod",{ arg inbus, outbus, sr1Bus, sr2Bus, distVolBus, distortSwitch, gate = 1, pauseGate = 1;
	var in, fx1, fx2, env, pauseEnv, out;
	var sr1, sr2, distVol;

	sr1 = In.kr(sr1Bus);
	sr2 = In.kr(sr2Bus);
	distVol = In.kr(distVolBus);

	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in=In.ar(inbus, 2);

	fx1=Latch.ar(in[0].round(0.125),Impulse.ar(sr1));
	fx2=Latch.ar(in[1].round(0.1),Impulse.ar(sr2));

	out = ([fx1,fx2])*distVol*env*pauseEnv;

	out = (Lag.kr(1-distortSwitch, 0.05)*in)+(Lag.kr(distortSwitch, 0.05)*out);

	Out.ar(outbus,out);
}).add;

SynthDef("bitInterrupter4_Mod",{ arg inbus, outbus, sr1Bus, sr2Bus, distVolBus, distortSwitch, gate = 1, pauseGate = 1;
	var in, fx1, fx2, fx3, fx4, env, pauseEnv, out;
	var sr1, sr2, distVol;

	sr1 = In.kr(sr1Bus);
	sr2 = In.kr(sr2Bus);
	distVol = In.kr(distVolBus);

	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in=In.ar(inbus, 4);

	fx1=Latch.ar(in[0].round(0.125),Impulse.ar(sr1));
	fx2=Latch.ar(in[1].round(0.1),Impulse.ar(sr2));
	fx3=Latch.ar(in[2].round(0.1125),Impulse.ar(sr1-50));
	fx4=Latch.ar(in[3].round(0.15),Impulse.ar(sr2+50));

	out = ([fx1,fx2,fx3,fx4])*distVol*env*pauseEnv;

	out = (Lag.kr(1-distortSwitch, 0.05)*in)+(Lag.kr(distortSwitch, 0.05)*out);

	Out.ar(outbus,out);
}).add;

SynthDef("bitInterrupter8_Mod",{ arg inbus, outbus, sr1Bus, sr2Bus, distVolBus, distortSwitch, gate = 1, pauseGate = 1;
	var in, fx1, fx2, fx3, fx4, fx5, fx6, fx7, fx8, env, pauseEnv, out;
	var sr1, sr2, distVol;

	sr1 = In.kr(sr1Bus);
	sr2 = In.kr(sr2Bus);
	distVol = In.kr(distVolBus);

	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in=In.ar(inbus, 8);

	fx1=Latch.ar(in[0].round(0.125),Impulse.ar(sr1));
	fx2=Latch.ar(in[1].round(0.1),Impulse.ar(sr2));
	fx3=Latch.ar(in[2].round(0.1125),Impulse.ar(sr1-25));
	fx4=Latch.ar(in[3].round(0.15),Impulse.ar(sr2+25));
	fx5=Latch.ar(in[4].round(0.125),Impulse.ar(sr1-50));
	fx6=Latch.ar(in[5].round(0.1),Impulse.ar(sr2+50));
	fx7=Latch.ar(in[6].round(0.1125),Impulse.ar(sr1-75));
	fx8=Latch.ar(in[7].round(0.15),Impulse.ar(sr2+75));

	out = ([fx1,fx2,fx3,fx4,fx5,fx6,fx7,fx8])*distVol*env*pauseEnv;

	out = (Lag.kr(1-distortSwitch, 0.05)*in)+(Lag.kr(distortSwitch, 0.05)*out);

	Out.ar(outbus,out);
}).add;


SynthDef("AtdVMuter_mod", {arg inBus, outBus, gate = 1, pauseGate = 1, muteGate = 1;
	var in, pauseEnv, env, muteEnv;

	env = EnvGen.kr(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	muteEnv = EnvGen.kr(Env.asr(0,1,0), muteGate);

	in = In.ar(inBus, 8);

	Out.ar(outBus, in*env*pauseEnv*muteEnv);
}).add;

SynthDef("AtdVPlayer_mod", {arg bufnum, outBus, volBus, gate = 1, pauseGate = 1, muteGate = 1;
	var out, out2, vol, pauseEnv, env, muteEnv;

	env = EnvGen.kr(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	muteEnv = EnvGen.kr(Env.asr(0,1,0), muteGate, doneAction:1);

	vol = In.kr(volBus);

	//out = PlayBuf.ar(2, bufnum, startPos: Rand(44100, 44100*20), loop: 1)*0;

	out2 = PlayBuf.ar(2, bufnum, startPos: Rand(44100, 44100*20), loop: 1);

	ReplaceOut.ar(outBus, [0,0]);
	ReplaceOut.ar(outBus+2, out2*env*vol*pauseEnv*muteEnv);

	//Out.ar(0, out*env*vol*pauseEnv*muteEnv);

}).add;


SynthDef("autoTune_mod", { |inBus, outBus, whichScale = 0, thresh = 0.05, tuneVol=1, synthVol=1, gate = 1, pauseGate = 1|
	var baseFreq = 100;
	var in, freq, hasFreq, out, synth, amp, env, pauseEnv, cScale, scale, vocoder;
	var sig, ampSig;

	in = In.ar(inBus);

	//in = DelayC.ar(In.ar(inBus), 0.5, 0.5);

	# freq, hasFreq = Pitch.kr(in, ampThreshold: 0.02, median: 7);
	baseFreq = freq.cpsmidi.round.midicps;



	cScale = DegreeToKey.kr(LocalBuf.newFrom([0,0,2,2,2,2,4,4,5,5,5,5,7,7,7,7,9,9,9,9,11,11,12,12]), freq.cpsmidi*2, 12, 1);

	baseFreq = Select.kr(whichScale, [baseFreq, cScale.midicps]);

	amp = Amplitude.kr(in,0.01,0.1);

	synth = LFTri.ar([baseFreq, baseFreq], 0, Lag.kr(amp, 0.3));
	amp = Lag.kr((amp>thresh),0.1);


	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus,synth)
}).add;


SynthDef("bandPassFreeze2_mod", { arg audioInBus, transferBus, buffer, buf0, buf1, buf2, thresh, low = 0.1, hi = 0.5, t_trig=0, gate = 1, pauseGate = 1;
	var audioIn, fftIn, chain, chain0, chain1, chain2, outSig, trig0, trig1, trig2, trig, amp, pan0, pan1, pan2, env, env0, env1, env2, outSig0, outSig1, outSig2, pauseEnv, muteEnv;

	audioIn = In.ar(audioInBus)*EnvGen.kr(Env.dadsr(1,0,0,1,0), 1);

	amp = Amplitude.kr(audioIn);

	//trig = Trig1.ar(amp-thresh,0.01);

	trig = Coyote.kr(audioIn, thresh: thresh, minDur: 0.1)+Trig1.kr(Decay.kr(t_trig, 0.1)-0.1, 0.1);

	SendTrig.kr(trig, 10, 1);

	//PulseCount.kr(trig);

	trig0 = Trig1.ar(PulseDivider.kr(trig, 3, 0), 0.02);
	trig1 = Trig1.ar(PulseDivider.kr(trig, 3, 1), 0.02);
	trig2 = Trig1.ar(PulseDivider.kr(trig, 3, 2), 0.02);

	chain = FFT(buffer, audioIn);

	chain0 = PV_Copy(chain, buf0);
	chain1 = PV_Copy(chain, buf1);
	chain2 = PV_Copy(chain, buf2);

	chain0 = PV_Freeze(chain0, 1 - (trig0+EnvGen.kr(Env.new([0,0,2,0], [0.5, 0.1,0.001]), 1)));
	chain1 = PV_Freeze(chain1, 1 - (trig1+EnvGen.kr(Env.new([0,0,2,0], [0.5, 0.1,0.001]), 1)));
	chain2 = PV_Freeze(chain2, 1 - (trig2+EnvGen.kr(Env.new([0,0,2,0], [0.5, 0.1,0.001]), 1)));

	chain0 = PV_BrickWall(chain0, SinOsc.ar(LFNoise2.ar(1).range(low, hi)));
	chain1 = PV_BrickWall(chain1, SinOsc.ar(LFNoise2.ar(1).range(low, hi)));
	chain2 = PV_BrickWall(chain2, SinOsc.ar(LFNoise2.ar(1).range(low, hi)));

	outSig0 = IFFT(chain0);
	outSig1 = IFFT(chain1);
	outSig2 = IFFT(chain2);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(1.1,1,0.1), gate, doneAction:2);

	Out.ar(transferBus, [outSig0, outSig1, outSig2]);
}).add;

SynthDef("bpfPan2_mod", {arg transferBus, audioOutBus, onOff = 1, vol=0, pauseGate = 1, gate = 1;
	var in, pan0, pan1, pan2, outSig0, outSig1, outSig2, outSig, pauseEnv, muteEnv, env;

	in = In.ar(transferBus, 3);

	pan0 = SinOsc.ar(LFNoise2.kr(0.1).range(0.2, 1));
	pan1 = SinOsc.ar(LFNoise2.kr(0.1).range(0.2, 1));
	pan2 = SinOsc.ar(LFNoise2.kr(0.1).range(0.2, 1));
	outSig0 = Pan2.ar(in[0], pan0, 1);
	outSig1 = Pan2.ar(in[1], pan1, 1);
	outSig2 = Pan2.ar(in[2], pan2, 1);

	outSig = outSig0+outSig1+outSig2;

	outSig = Compander.ar(outSig, outSig,
		thresh: 0.8,
		slopeBelow: 1,
		slopeAbove: 0.5,
		clampTime: 0.01,
		relaxTime: 0.01
	);

	muteEnv = EnvGen.kr(Env.asr(0.001, 1, 0.001), onOff);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);

	outSig = outSig*vol*env*pauseEnv*muteEnv;

	Out.ar(audioOutBus, outSig);

}).add;

SynthDef("bpfPan4_mod", {arg transferBus, audioOutBus, onOff = 1, vol=0, pauseGate = 1, gate = 1;
	var in, pan0, pan1, pan2, outSig0, outSig1, outSig2, outSig, pauseEnv, muteEnv, env;

	in = In.ar(transferBus, 3);

	pan0 = SinOsc.ar(LFNoise2.kr(0.1).range(0.2, 1))+SinOsc.ar(LFNoise2.kr(0.1).range(0.05, 0.1), Rand(0, 2));
	pan1 = SinOsc.ar(LFNoise2.kr(0.1).range(0.2, 1))+SinOsc.ar(LFNoise2.kr(0.1).range(0.05, 0.1), Rand(0, 2));
	pan2 = SinOsc.ar(LFNoise2.kr(0.1).range(0.2, 1))+SinOsc.ar(LFNoise2.kr(0.1).range(0.05, 0.1), Rand(0, 2));
	outSig0 = PanAz.ar(4, in[0], pan0, 1);
	outSig1 = PanAz.ar(4, in[1], pan1, 1);
	outSig2 = PanAz.ar(4, in[2], pan2, 1);

	outSig = outSig0+outSig1+outSig2;

	outSig = Compander.ar(outSig, outSig,
		thresh: 0.8,
		slopeBelow: 1,
		slopeAbove: 0.5,
		clampTime: 0.01,
		relaxTime: 0.01
	);

	muteEnv = EnvGen.kr(Env.asr(0.001, 1, 0.001), onOff);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);

	outSig = outSig*vol*env*pauseEnv*muteEnv;

	Out.ar(audioOutBus, outSig);

}).add;

SynthDef("bpfPan8_mod", {arg transferBus, audioOutBus, onOff = 1, vol=0, pauseGate = 1, gate = 1;
	var in, pan0, pan1, pan2, outSig0, outSig1, outSig2, outSig, pauseEnv, muteEnv, env;

	in = In.ar(transferBus, 3);

	pan0 = SinOsc.ar(LFNoise2.kr(0.1).range(0.2, 1))+SinOsc.ar(LFNoise2.kr(0.1).range(0.05, 0.1), Rand(0, 2));
	pan1 = SinOsc.ar(LFNoise2.kr(0.1).range(0.2, 1))+SinOsc.ar(LFNoise2.kr(0.1).range(0.05, 0.1), Rand(0, 2));
	pan2 = SinOsc.ar(LFNoise2.kr(0.1).range(0.2, 1))+SinOsc.ar(LFNoise2.kr(0.1).range(0.05, 0.1), Rand(0, 2));
	outSig0 = PanAz.ar(8, in[0], pan0, 1);
	outSig1 = PanAz.ar(8, in[1], pan1, 1);
	outSig2 = PanAz.ar(8, in[2], pan2, 1);

	outSig = outSig0+outSig1+outSig2;

	outSig = Compander.ar(outSig, outSig,
		thresh: 0.8,
		slopeBelow: 1,
		slopeAbove: 0.5,
		clampTime: 0.01,
		relaxTime: 0.01
	);

	muteEnv = EnvGen.kr(Env.asr(0.001, 1, 0.001), onOff);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);

	outSig = outSig*vol*env*pauseEnv*muteEnv;

	Out.ar(audioOutBus, outSig);

}).add;


SynthDef("bplVerb_mod",{arg inBus, outBus, gate=1, pauseGate=1;
	var in, env, out, pauseEnv;

	in = In.ar(inBus, 1);

	//out = Mix.new(GVerb.ar(in, 200, 3, 1,�1, 15, 0, 0, 1, 200));
	out = Mix.new(GVerb.ar(in, 200, 3, drylevel:0, taillevel:1)*0.2);
	//Out.ar(0, in); Out.ar(1, out);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:0);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);

	Out.ar(outBus, out*env*pauseEnv);
}).add;

SynthDef("bplFilterSynth2_mod", {arg inBus, outBus, pitchStart, pitchEnd, smallLength, duration, volBus;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, smallEnv, volume, xStart, xEnd, impulse, pitch;

	buffer = LocalBuf(88200);

	volume = In.kr(volBus);

	in = In.ar(inBus, 1);

	//Out.ar(0, in);

	env = EnvGen.kr(Env.new([0,1,0], [0.001,duration-0.002], 'linear'), doneAction:2);

	in = BPF.ar(in, Rand(200, 15,000), Rand(0.15, 0.3));

	RecordBuf.ar(in, buffer, loop:0);

	pitch = XLine.kr(pitchStart, pitchEnd, duration);

	impulse = DelayN.ar(Impulse.ar(1/(smallLength)), 0.1, 0.1);

	xStart = Rand(-1,1);
	xEnd = Rand(-1,1);

	out = TGrains.ar(2, impulse, buffer, pitch, smallLength/2, smallLength, Line.kr(xStart, xEnd, duration));

	//out = PlayBuf.ar(1, buffer, pitch, DelayN.kr(impulse, 2, (smallLength/2)+0.05), 0, 1)+PlayBuf.ar(1, buffer, XLine.kr(pitchStart, pitchEnd, duration), DelayN.kr(impulse, 2, 0.05), 0, 1);

	Out.ar(outBus, out*volume*env);
}).add;


SynthDef("buchlaLowFilter_mod", {arg inBus, freq, db, lagTime=0, gate = 1, pauseGate = 1;
	var in, out, env, pauseEnv;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in  = In.ar(inBus, 2);

	out = BLowShelf.ar(in,freq,1,Lag.kr(db, lagTime)+LFNoise1.kr(0.1));

	ReplaceOut.ar(inBus, out*env*pauseEnv);
}).add;
SynthDef("buchlaMidFilter_mod", {arg inBus, freq, rq, db, lagTime=0, gate = 1, pauseGate = 1;
	var in, out, env, pauseEnv;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in  = In.ar(inBus);

	out = MidEQ.ar(in,freq, Lag.kr(rq, lagTime), Lag.kr(db, lagTime)+LFNoise1.kr(0.1));

	ReplaceOut.ar(inBus, out*env*pauseEnv);
}).add;
SynthDef("buchlaHighFilter_mod", {arg inBus, freq, db, lagTime=0, gate = 1, pauseGate = 1;
	var in, out, env, pauseEnv;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in  = In.ar(inBus, 2);

	out = BHiShelf.ar(in,freq,1 ,Lag.kr(db, lagTime)+LFNoise1.kr(0.1));

	ReplaceOut.ar(inBus, out*env*pauseEnv);
}).add;
SynthDef("buchlaOut1_mod", {arg inBus, outBus, gate = 1, pauseGate = 1;
	var in, out, env, pauseEnv;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in  = In.ar(inBus, 2);

	Out.ar(outBus, in*env*pauseEnv);
}).add;
SynthDef("buchlaOut2_mod", {arg inBus, outBus, gate = 1, pauseGate = 1;
	var in, out, env, pauseEnv;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in  = In.ar(inBus, 2);

	Out.ar(outBus, in*env*pauseEnv);
}).add;


SynthDef("buchlaFMPatchSolo_mod", {arg inBus, outBus, pitchBus, amp0 = 0, amp1=0, amp2 = 0, amp3 = 0, amp4 = 0, amp5 = 0, amp6 = 0, amp7 = 0, freq0 = 300, freq1=200, arpFreq = 400, ampModFreq=0, ampModVol = 0, noise1Select=0, noise2Select = 0, ampModNoiseSelect=0, t_trig, lagTime = 0.1, gate = 1, pauseGate = 1;
	var layer2, layer1, layer0, ampMod, seq, env, pauseEnv, layer1Noise, in, freq, hasFreq;

	in = In.ar(inBus);

	#freq, hasFreq = Tartini.kr(in);

	Out.kr(pitchBus, freq);

	layer2 = WhiteNoise.ar(amp5)+PinkNoise.ar(amp6)+BrownNoise.ar(amp7);

	layer2 = Select.ar(noise2Select, [layer2, Latch.ar(layer2, Dust.ar(TRand.ar(200, 1000, noise2Select)))]);

	layer1Noise = BrownNoise.ar(amp4);
	layer1Noise = Select.ar(noise1Select, [layer1Noise, Latch.ar(layer1Noise, Dust.ar(TRand.ar(200, 1000, noise1Select)))]);

	layer1 = SinOsc.ar(freq1+layer2,0,amp2)+LFSaw.ar(freq1+layer2,0,amp3)+layer1Noise;

	ampMod = SinOsc.ar(ampModFreq+(Select.kr(ampModNoiseSelect, [0, LFNoise2.kr(TRand.kr(0.5, 2, ampModNoiseSelect)).range(0, 30)])), 0, ampModVol/2, ampModVol/2);



	layer0 = SinOsc.ar(freq0+layer1, 0, ampModVol-(ampMod*Lag.kr((ampModFreq>1), 1/ampModFreq)));


	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);

	Out.ar(outBus, [layer0,layer0]*env*pauseEnv)
}).add


SynthDef("overLapSamplePlayer_mod", {arg bufnum0, bufnum1, whichOut = 0, playRate=1, numGrains = 1, startPos, startPos0, dur, outBus, vol=0, trigOnOff=0, onOff = 1, pauseGate = 1, gate = 1;
	var env, pauseEnv, onOffEnv, impulse, out, out0, out1, pan, fade, trigRate, trigRateA, duration, envs, impulse0;
	var playBuf0, playBuf1;
	var toggle;
	var counter;

	env = EnvGen.kr(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.05,1,0.01), pauseGate, doneAction:1);
	onOffEnv = EnvGen.kr(Env.asr(0.01,1,0.01), onOff, doneAction:0);

	duration = (BufDur.kr(bufnum0)*dur).clip(0.02, BufDur.kr(bufnum0));

	trigRate = Select.kr(trigOnOff, [0, numGrains/(duration-0.01)]).clip(1/(duration-0.01), 100);

	fade = (BufDur.kr(bufnum0) - ((BufDur.kr(bufnum0)/numGrains))).clip(0.01, duration/2);

	impulse = Impulse.kr(trigRate);

	counter = Stepper.kr(impulse, 0, 0, 7, 1);

	toggle = Select.kr(counter, [[1,0,0,0,0,0,0,0],[0,1,0,0,0,0,0,0],[0,0,1,0,0,0,0,0],[0,0,0,1,0,0,0,0],[0,0,0,0,1,0,0,0],[0,0,0,0,0,1,0,0],[0,0,0,0,0,0,1,0],[0,0,0,0,0,0,0,1]]);

	pan = Select.kr(whichOut, [TRand.kr(-1,1, toggle), -1]);

	envs = EnvGen.kr(Env.asr(fade, 1, fade, 'welch'), toggle);

	startPos = Select.kr((playRate+4/4).floor.clip(0, 1), [startPos0, startPos]);

	playBuf0 = Pan2.ar(PlayBuf.ar(1, bufnum0, playRate*BufRateScale.kr(bufnum0), toggle, startPos*BufFrames.kr(bufnum0), 0), pan)*envs;

	playBuf1 = Pan2.ar(PlayBuf.ar(1, bufnum1, playRate*BufRateScale.kr(bufnum1), toggle, startPos*BufFrames.kr(bufnum1), 0), 1)*envs;

	out0 = Mix(playBuf0);
	out1 = Mix(playBuf1);

	out = Select.ar(whichOut, [out0, out0+out1]);

	Out.ar(outBus, out*env*pauseEnv*vol*onOffEnv);
}).add;


SynthDef("loopPlayer_mod", {arg bufnum0, bufnum1, whichOut=0, outBus, vol, startPos=0, gate = 1, pausePlayGate = 0, pauseGate = 1, t_trig = 0, loop = 0;
	var in0, in1, env, out, pauseEnv, pausePlayEnv, playBuf0, playBuf1, pan;

	env = EnvGen.kr(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.05,1,0.1), pauseGate, doneAction:1);
	pausePlayEnv = EnvGen.kr(Env.asr(0.05,1,0), pausePlayGate, doneAction:0);

	pan = Select.kr(whichOut, [0, -1]);

	playBuf0 = Pan2.ar(PlayBuf.ar(1, bufnum0, BufRateScale.kr(bufnum0)*pausePlayGate, Decay2.kr(t_trig, 0.1)-0.2, startPos, loop), pan);

	playBuf1 = Pan2.ar(PlayBuf.ar(1, bufnum1, BufRateScale.kr(bufnum1)*pausePlayGate, Decay2.kr(t_trig, 0.1)-0.2, startPos, loop), 1);

	out = Select.ar(whichOut, [playBuf0, playBuf0+playBuf1]);

	out = LeakDC.ar(out);

	Out.ar(outBus, out*env*vol*pauseEnv*pausePlayEnv);
}).add;


SynthDef("sampleMashupPlayerMono_mod", {arg bufnum, outBus, startPos = 0, dur, volBus, gate = 1, pauseGate = 1;
	var in0, in1, env, env2, out, pauseEnv, vol;

	vol = In.kr(volBus);

	env2 = EnvGen.kr(Env.new([0,1,1,0],[0.01, dur, 0.01]), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	out = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), 1, startPos, loop: 0);
	out = Pan2.ar(out, Rand(-1.0,1.0));
	Out.ar(outBus, out*env2*pauseGate*vol);
}).add;

SynthDef("sampleMashupPlayerStereo_mod", {arg bufnum, outBus, startPos = 0, dur, volBus, gate = 1, pauseGate = 1;
	var in0, in1, env, env2, out, pauseEnv, vol;

	vol = In.kr(volBus);

	env2 = EnvGen.kr(Env.new([0,1,1,0],[0.01, dur, 0.01]), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	out = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), 1, startPos, loop: 0);

	Out.ar(outBus, out*env2*pauseGate*vol);
}).add;


SynthDef(\combFilter_mod, { arg inBus, outBus, vol=0, delayTime=0.01, decayTime=1, pauseGate=1, gate=1;

	var in, env, pauseEnv;

	in = In.ar(inBus);

	in = CombC.ar(in, 0.05, delayTime, decayTime, vol);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);

	Out.ar(outBus, in.dup*env*pauseEnv);
}).add;


SynthDef(\klankFilter_mod, { arg inBus, outBus, i_freq, vol=0, delayTime=0.01, decayTime=1, pauseGate=1, gate=1;

	var in, env, pauseEnv;

	in = In.ar(inBus);

	in = Klank.ar(`[Array.series(60,1,1), Array.fill(60,1/60), Array.fill(60,0.1)], in, i_freq);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);

	Out.ar(outBus, in.dup*env*pauseEnv*vol);
}).add;


SynthDef(\klankFilter2_mod, { arg inBus, outBus, i_freq, vol=0, delayTime=0.01, decayTime=1, pauseGate=1, gate=1;

	var in, env, pauseEnv;

	in = In.ar(inBus);

	in = Klank.ar(`[[2341, 1787.7, 1582, 1434.3, 1117.74, 872.9, 809.6, 710.3, 613.2, 483.2, 432.6, 372.2, 327.7, 288.5, 253.2, 221.5, 165, 141.93, 124, 107.3, 58.99].addAll([2341, 1787.7, 1582, 1434.3, 1117.74, 872.9, 809.6, 710.3, 613.2, 483.2, 432.6, 372.2, 327.7, 288.5, 253.2, 221.5, 165, 141.93, 124, 107.3, 58.99]*2), Array.fill(24, 1/24), Array.fill(24,1)], in);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);

	Out.ar(outBus, in.dup*env*pauseEnv*vol);
}).add;


SynthDef(\pinknoise_mod, { arg outBus, vol=0, pauseGate=1, gate=1;

	var env, pauseEnv, out;

	out = PinkNoise.ar([vol, vol]);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);

	Out.ar(outBus, out*env*pauseEnv);
}).add;


SynthDef("comby2_mod", {arg inBus, outBus, volBus, lowRandBus, hiRandBus, gate = 1, pauseGate = 1;
	var in, env, out, vol, lowRand, hiRand, pauseEnv;

	in = In.ar(inBus);

	vol = In.kr(volBus);
	lowRand = 0.0001;
	hiRand = 0.01;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	out = CombC.ar(in, 0.01, TRand.kr(lowRand, hiRand, Impulse.kr(LFNoise2.kr(2, 5, 20))), 0.2);

	Out.ar(outBus, Pan2.ar(out*env*vol*pauseEnv, SinOsc.kr(Rand(0.5,0.25))));
}).add;

SynthDef("comby4_mod", {arg inBus, outBus, volBus, lowRandBus, hiRandBus, gate = 1, pauseGate = 1;
	var in, env, out, vol, lowRand, hiRand, pauseEnv;

	in = In.ar(inBus);

	vol = In.kr(volBus);
	lowRand = 0.0001;
	hiRand = 0.01;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	out = CombC.ar(in, 0.01, TRand.kr(lowRand, hiRand, Impulse.kr(LFNoise2.kr(2, 5, 20))), 0.2);

	Out.ar(outBus, PanAz.ar(4, out*env*vol*pauseEnv, SinOsc.kr(Rand(0.5,0.25))*2));
}).add;

SynthDef("comby8_mod", {arg inBus, outBus, volBus, lowRandBus, hiRandBus, gate = 1, pauseGate = 1;
	var in, env, out, vol, lowRand, hiRand, pauseEnv;

	in = In.ar(inBus);

	vol = In.kr(volBus);
	lowRand = 0.0001;
	hiRand = 0.01;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	out = CombC.ar(in, 0.01, TRand.kr(lowRand, hiRand, Impulse.kr(LFNoise2.kr(2, 5, 20))), 0.2);

	Out.ar(outBus, PanAz.ar(8, out*env*vol*pauseEnv, SinOsc.kr(Rand(0.5,0.25))*2));
}).add;


SynthDef("convolution_mod", {arg inBus0, inBus1, outBus, vol, lpFreq=2000, gate = 1, pauseGate = 1;
	var in0, in1, env, out, pauseEnv;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in0 = Mix(In.ar(inBus0, 8));
	in1 = Mix(In.ar(inBus1, 8));

	out = Convolution.ar(in0, in1, 2048)*env*vol*pauseEnv;

	Out.ar(outBus, out, 0);
}).add;


SynthDef("crackleSynth2_mod", { |outBus, vol, whichSawFreq = 0, sawFreq = 20, crackleMult = 20, crackleAdd=0.5, hpfFreq = 40, envRate=5, justOn = 1, whichOscil = 1, gate = 1, pauseGate = 1|
	var randSawFreq, synth, noise0, noise1, env, pauseEnv;

	randSawFreq = LFNoise0.kr(LFNoise0.kr(1, 5, 5)).range(20, 2020);

	synth = SelectX.ar(whichOscil, [SinOsc.ar(LFSaw.ar(Select.kr(whichSawFreq, [sawFreq,randSawFreq]), 0, 2000, 0)+Crackle.ar([1.93, 1.97], crackleMult, LFNoise0.kr(LFNoise2.kr(1, 60, 100), crackleAdd*5, crackleAdd*5000)), 0, 0.8),
		SinOsc.ar(LFSaw.ar(Select.kr(whichSawFreq, [sawFreq,randSawFreq]), 0, 2000, 0)+Crackle.ar([1.93, 1.97], crackleMult, LFNoise0.kr(LFNoise2.kr(1, 60, 100), crackleAdd*5, crackleAdd*5000)), 0, 0.8),
		Pulse.ar(Crackle.ar([1.93, 1.97], crackleMult, LFNoise0.kr(LFNoise2.kr(1, 60, 100), crackleAdd*5, crackleAdd*100)), 0.5,1.5)]);

	synth = HPF.ar(synth, hpfFreq).clip2(0.2);

	noise0 = LFNoise2.kr(0.75);

	noise1 = LFNoise2.kr(0.5, 20, 10);

	synth = ((Pan2.ar(synth[0], (noise0-(LFNoise2.kr(2, 0.1).abs)).clip2(1))*(1-Trig1.ar(Dust.kr(noise1), 1/100))) + (Pan2.ar(synth[1], (noise0+(LFNoise2.kr(2, 0.1).abs)).clip2(1))*(1-Trig1.ar(Dust.kr(noise1), 1/100))));

	synth = Normalizer.ar(synth, 0.5, 0.05);

	env = EnvGen.kr(Env.asr(0, 1, 5), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, (max(LFSaw.kr(envRate, 0, 1, 0.5), Lag.kr(justOn, 0.01)))*synth*vol*env*pauseEnv);

}).add;


SynthDef("cutter2_mod", {arg inBus, outBus, bufnum, pointClkFreeze, latchPoint, lowRate, highRate, volBus, onOff, overlap = 1, gate = 1, pauseGate = 1;
	var in, trate, dur, xPos, clk, pointClk, point, point0, point1, point2, point3, point4, point5, point6, point7, phasor, env, pauseEnv, vol;

	vol = In.kr(volBus);

	trate = Select.kr(onOff, [LFNoise2.kr(LFNoise2.kr(0.5, 1.5, 2)).range(lowRate, highRate), 0]);
	dur = (1 / trate)*overlap;
	clk = Impulse.kr(trate);

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum));

	in = In.ar(inBus);

	BufWr.ar(in, bufnum, phasor, 1);

	xPos = (phasor/SampleRate.ir);

	pointClk = Select.kr(pointClkFreeze, [clk, 0]);

	point0 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 0));
	point1 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 1));
	point2 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 2));
	point3 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 3));
	point4 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 4));
	point5 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 5));
	point6 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 6));
	point7 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 7));

	point = TWChoose.kr(clk, [point0,point1,point2,point3], [LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1),LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1),LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1)].normalizeSum);

	point = Select.kr(latchPoint, [point, Latch.kr(point, latchPoint)]);

	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.1,1,0.1), pauseGate, doneAction:1);

	Out.ar(outBus, TGrains2.ar(2, clk, bufnum, 1.0, point, dur, TRand.kr(-1, 1, clk), 1, 0.01, 0.01, 4)*vol*env*pauseEnv);
}).add;

SynthDef("cutter4_mod", {arg inBus, outBus, bufnum, pointClkFreeze, latchPoint, lowRate, highRate, volBus, onOff, overlap = 1, gate = 1, pauseGate = 1;
	var in, trate, dur, xPos, clk, pointClk, point, point0, point1, point2, point3, point4, point5, point6, point7, phasor, env, pauseEnv, vol;

	vol = In.kr(volBus);

	trate = Select.kr(onOff, [LFNoise2.kr(LFNoise2.kr(0.5, 1.5, 2)).range(lowRate, highRate), 0]);
	dur = (1 / trate)*overlap;
	clk = Impulse.kr(trate);

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum));

	in = In.ar(inBus);

	BufWr.ar(in, bufnum, phasor, 1);

	xPos = (phasor/SampleRate.ir);

	pointClk = Select.kr(pointClkFreeze, [clk, 0]);

	point0 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 0));
	point1 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 1));
	point2 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 2));
	point3 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 3));
	point4 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 4));
	point5 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 5));
	point6 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 6));
	point7 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 7));

	point = TWChoose.kr(clk, [point0,point1,point2,point3], [LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1),LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1),LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1)].normalizeSum);

	point = Select.kr(latchPoint, [point, Latch.kr(point, latchPoint)]);

	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.1,1,0.1), pauseGate, doneAction:1);

	Out.ar(outBus, TGrains2.ar(4, clk, bufnum, 1.0, point, dur, TRand.kr(-1, 1, clk), 1, 0.01, 0.01, 4)*vol*env*pauseEnv);
}).add;

SynthDef("cutter8_mod", {arg inBus, outBus, bufnum, pointClkFreeze, latchPoint, lowRate, highRate, volBus, onOff, overlap = 1, gate = 1, pauseGate = 1;
	var in, trate, dur, xPos, clk, pointClk, point, point0, point1, point2, point3, point4, point5, point6, point7, phasor, env, pauseEnv, vol;

	vol = In.kr(volBus);

	trate = Select.kr(onOff, [LFNoise2.kr(LFNoise2.kr(0.5, 1.5, 2)).range(lowRate, highRate), 0]);
	dur = (1 / trate)*overlap;
	clk = Impulse.kr(trate);

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum));

	in = In.ar(inBus);

	BufWr.ar(in, bufnum, phasor, 1);

	xPos = (phasor/SampleRate.ir);

	pointClk = Select.kr(pointClkFreeze, [clk, 0]);

	point0 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 0));
	point1 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 1));
	point2 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 2));
	point3 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 3));
	point4 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 4));
	point5 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 5));
	point6 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 6));
	point7 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 7));

	point = TWChoose.kr(clk, [point0,point1,point2,point3], [LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1),LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1),LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1)].normalizeSum);

	point = Select.kr(latchPoint, [point, Latch.kr(point, latchPoint)]);

	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.1,1,0.1), pauseGate, doneAction:1);

	Out.ar(outBus, TGrains2.ar(8, clk, bufnum, 1.0, point, dur, TRand.kr(-1, 1, clk), 1, 0.01, 0.01, 4)*vol*env*pauseEnv);
}).add;


SynthDef("cutterB2_mod", {arg inBus, outBus, bufnum, pointClkFreeze, latchPoint, lowRate, highRate, volBus, onOff, whichSig=0, gate = 1, pauseGate = 1;
	var inSt, in, out, trate, dur, xPos, clk, pointClk, point, point0, point1, point2, point3, point4, point5, point6, point7, phasor, env, pauseEnv, vol;

	vol = In.kr(volBus);

	trate = Select.kr(onOff, [LFNoise2.kr(LFNoise2.kr(0.5, 1.5, 2)).range(lowRate, highRate), 0]);
	dur = 1 / trate;
	clk = Impulse.kr(trate+LFNoise2.kr(1).range((trate/20).neg, trate/20));

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum));

	inSt = In.ar(inBus,2);
	in = Mix.new(inSt);

	BufWr.ar(in, bufnum, phasor, 1);

	xPos = (phasor/SampleRate.ir);

	pointClk = Select.kr(pointClkFreeze, [clk, 0]);

	point0 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 0));
	point1 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 1));
	point2 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 2));
	point3 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 3));
	point4 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 4));
	point5 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 5));
	point6 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 6));
	point7 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 7));

	point = TWChoose.kr(clk, [point0,point1,point2,point3], [LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1),LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1),LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1)].normalizeSum);

	point = Select.kr(latchPoint, [point, Latch.kr(point, latchPoint)]);

	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.1,1,0.1), pauseGate, doneAction:1);

	out = SelectX.ar(Lag.kr(whichSig,0.1)*2, [inSt, TGrains2.ar(2, clk, bufnum, 1.0, point, dur, TRand.kr(-1, 1, clk), 1, 0.01, 0.01, 4)*vol]);

	Out.ar(outBus, out*env*pauseEnv);
}).add;

SynthDef("cutterB4_mod", {arg inBus, outBus, bufnum, pointClkFreeze, latchPoint, lowRate, highRate, volBus, onOff, whichSig=0, gate = 1, pauseGate = 1;
	var inSt, in, out, trate, dur, xPos, clk, pointClk, point, point0, point1, point2, point3, point4, point5, point6, point7, phasor, env, pauseEnv, vol;

	vol = In.kr(volBus);

	trate = Select.kr(onOff, [LFNoise2.kr(LFNoise2.kr(0.5, 1.5, 2)).range(lowRate, highRate), 0]);
	dur = 1 / trate;
	clk = Impulse.kr(trate+LFNoise2.kr(1).range((trate/20).neg, trate/20));

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum));

	inSt = In.ar(inBus,4);
	in = Mix.new(inSt);


	BufWr.ar(in, bufnum, phasor, 1);

	xPos = (phasor/SampleRate.ir);

	pointClk = Select.kr(pointClkFreeze, [clk, 0]);

	point0 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 0));
	point1 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 1));
	point2 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 2));
	point3 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 3));
	point4 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 4));
	point5 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 5));
	point6 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 6));
	point7 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 7));

	point = TWChoose.kr(clk, [point0,point1,point2,point3], [LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1),LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1),LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1)].normalizeSum);

	point = Select.kr(latchPoint, [point, Latch.kr(point, latchPoint)]);

	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.1,1,0.1), pauseGate, doneAction:1);

	out = SelectX.ar(Lag.kr(whichSig,0.1)*2, [inSt, TGrains2.ar(4, clk, bufnum, 1.0, point, dur, TRand.kr(-1, 1, clk), 1, 0.01, 0.01, 4)*vol]);

	Out.ar(outBus, out*env*pauseEnv);

}).add;

SynthDef("cutterB8_mod", {arg inBus, outBus, bufnum, pointClkFreeze, latchPoint, lowRate, highRate, volBus, onOff, whichSig=0, gate = 1, pauseGate = 1;
	var inSt, in, out, trate, dur, xPos, clk, pointClk, point, point0, point1, point2, point3, point4, point5, point6, point7, phasor, env, pauseEnv, vol;

	vol = In.kr(volBus);

	trate = Select.kr(onOff, [LFNoise2.kr(LFNoise2.kr(0.5, 1.5, 2)).range(lowRate, highRate), 0]);
	dur = 1 / trate;
	clk = Impulse.kr(trate+LFNoise2.kr(1).range((trate/20).neg, trate/20));

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum));

	inSt = In.ar(inBus,8);
	in = Mix.new(inSt);

	BufWr.ar(in, bufnum, phasor, 1);

	xPos = (phasor/SampleRate.ir);

	pointClk = Select.kr(pointClkFreeze, [clk, 0]);

	point0 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 0));
	point1 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 1));
	point2 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 2));
	point3 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 3));
	point4 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 4));
	point5 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 5));
	point6 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 6));
	point7 = Latch.kr(xPos, PulseDivider.kr(pointClk, 8, 7));

	point = TWChoose.kr(clk, [point0,point1,point2,point3], [LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1),LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1),LFNoise0.kr(0.5, 0.5,1), LFNoise0.kr(0.5, 0.5,1)].normalizeSum);

	point = Select.kr(latchPoint, [point, Latch.kr(point, latchPoint)]);

	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.1,1,0.1), pauseGate, doneAction:1);

	out = SelectX.ar(Lag.kr(whichSig,0.1)*2, [inSt, TGrains2.ar(8, clk, bufnum, 1.0, point, dur, TRand.kr(-1, 1, clk), 1, 0.01, 0.01, 4)*vol]);

	Out.ar(outBus, out*env*pauseEnv);
}).add;


SynthDef("cycleGripper_mod", {arg inBus, outBus, trigRateDust=0, trigRateImpulse=0, mode=0, inDelay = 0.02, t_trig = 0, gate = 1, pauseGate = 1;				var trig, div0, div1, switch0, switch1, source, local, delay, delayTime;
	var triga, div0a, div1a, switch0a, switch1a, env, pauseEnv;

	env = EnvGen.kr(Env.asr(0.01,1,0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.01,1,0.01), pauseGate, doneAction:1);

	trig = Dust.kr(trigRateDust) + Impulse.kr(trigRateImpulse);

	div0 = PulseDivider.kr(trig, 2, 0);
	div1 = PulseDivider.kr(trig, 2, 1);
	switch0 = SetResetFF.kr(div0,div1);
	switch1 = SetResetFF.kr(div1,div0);

	div0a = Trig.kr(t_trig, 0.01);
	div1a = Trig.kr(TDelay.kr(t_trig, inDelay), 0.01);
	switch0a = SetResetFF.kr(div0a,div1a);
	switch1a = SetResetFF.kr(div1a,div0a);

	switch0 = Select.kr(mode, [switch0, switch0a, 1]);
	switch1 = Select.kr(mode, [switch1, switch1a, 0]);

	source = In.ar(inBus, 2);

	delayTime = Select.kr(mode, [TRand.kr(64/44100, 1024/44100, trig), inDelay, inDelay]);

	delay = DelayN.ar(LocalIn.ar(2), 8192/44100, delayTime);

	delay = Compander.ar((switch1*delay), (switch1*delay), 1, 1, 0.5, 0.01, 0.01).distort.clip2(0.8);
	//delay = (delay+PitchShift.ar(delay, 0.02, TRand.kr(0.9, 1.1, switch1), 0.01, 0));

	local = Mix.new([(switch0*source),delay]);

	LocalOut.ar(local.reverse*1.2);

	Out.ar(outBus, local*env*pauseEnv);
}).add;


SynthDef("decimateGrains_Mod",{ arg inbus, outbus, volume, trigRate, gate = 1, pauseGate = 1;
	var input, dustNoise, env, pauseEnv, trig, fx1, pan;
	var delay1, delay2, delay3, delay4, delay5;
	var grain;

	input=In.ar(inbus, 1);

	dustNoise = LFNoise2.ar(3).range(3, 10);

	//input = input*Trig1.ar(Dust.ar(dustNoise), 1/(dustNoise*2));

	fx1=HPF.ar(Latch.ar(input.round(0.125),Impulse.ar(LFNoise2.ar(2).range(150, 400))), 400);


	delay1 = DelayC.ar(fx1, 0.1, 0.02);
	delay2 = DelayC.ar(fx1, 0.1, 0.04);
	delay3 = DelayC.ar(fx1, 0.1, 0.06);
	delay4 = DelayC.ar(fx1, 0.1, 0.08);
	delay5 = DelayC.ar(fx1, 0.1, 0.1);

	trig = Dust.kr(trigRate);

	fx1 = SelectX.ar(LFNoise2.kr(6).range(0, 1), [fx1, delay1, delay2, delay3, delay4, delay5]);

	pan = LFNoise2.kr(LFNoise0.kr(2).range(2,6)).range(-1,1);

	grain = GrainIn.ar(2, trig, TRand.kr(0.01, 0.1, trig), fx1, pan, -1);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outbus,grain*volume*env*pauseEnv);
}).add;


SynthDef("triggerSines_mod",{ arg inbus, outbus, volume=0.2, ampThreshold=0.1, 				t_trig, gate = 1, pauseGate = 1;
	var input, env, pauseEnv, trig, sine0, sine1, sine2, sine3, sine4;
	var freq, hasFreq, fund, skip, amp;

	input=In.ar(inbus, 1);

	//input = PlayBuf.ar(1, 0, loop:1);

	#freq, hasFreq = Pitch.kr(input, ampThreshold: ampThreshold, median: 7);

	//hasFreq = Select.kr(MouseX.kr>0.5, [hasFreq, Latch.kr(hasFreq, MouseX.kr>0.5)]);
	amp = Amplitude.kr(input);
	trig = (amp>ampThreshold);

	//fund = TIRand.kr(30, 50, hasFreq);
	skip = TIRand.kr(5, 15, hasFreq);

	sine0 = Pan2.ar(SinOsc.ar(freq*skip, 0, hasFreq), LFNoise2.kr(0.5).range(-1, 1));
	sine1 = Pan2.ar(SinOsc.ar(freq*2*skip, 0, hasFreq), LFNoise2.kr(0.5).range(-1, 1));
	sine2 = Pan2.ar(SinOsc.ar(freq*3*skip, 0, hasFreq), LFNoise2.kr(0.5).range(-1, 1));
	sine3 = Pan2.ar(SinOsc.ar(freq*4*skip, 0, hasFreq), LFNoise2.kr(0.5).range(-1, 1));
	sine4 = Pan2.ar(SinOsc.ar(freq*5*skip, 0, hasFreq), LFNoise2.kr(0.5).range(-1, 1));

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	//Out.ar(outbus,input);
	Out.ar(outbus,(sine0+sine1+sine2+sine3+sine4)*volume*env*pauseEnv*amp);
}).add;


SynthDef("delayRingmod_mod",{ arg inbus, outbus, volume, gate = 1, pauseGate = 1;
	var input, dustNoise, env, pauseEnv, trig, fx1, pan;
	var delay1, delay2, delay3, delay4, delay5;
	var grain;

	input=In.ar(inbus, 1)*volume;

	//input = input*Trig1.ar(Dust.ar(dustNoise), 1/(dustNoise*2));

	delay1 = Pan2.ar(BPF.ar(DelayC.ar(input, 1, LFNoise2.kr(1).range(0.025, 0.05)), LFNoise2.kr(1).range(800,1600), 0.1), LFNoise2.kr(0.25));
	delay2 = Pan2.ar(BPF.ar(DelayC.ar(input, 1, LFNoise2.kr(1.1).range(0.05, 0.075)), LFNoise2.kr(1.1).range(1600,3200), 0.1), LFNoise2.kr(0.25));
	delay3 = Pan2.ar(BPF.ar(DelayC.ar(input, 1, LFNoise2.kr(0.9).range(0.075, 0.1)), LFNoise2.kr(0.9).range(3200,7200), 0.1), LFNoise2.kr(0.25));
	delay4 = Pan2.ar(BPF.ar(DelayC.ar(input, 1, LFNoise2.kr(1.2).range(0.1, 0.125)), LFNoise2.kr(1.2).range(7200,11000), 0.1), LFNoise2.kr(0.25));
	delay5 = Pan2.ar(BPF.ar(DelayC.ar(input, 1.3, LFNoise2.kr(0.95).range(0.125, 0.15)), LFNoise2.kr(0.95).range(11000,20000), 0.1), LFNoise2.kr(0.25));

	fx1 = (SinOsc.ar(LFNoise0.kr(120).range(200, 2000), SinOsc.ar(LFNoise0.kr(121).range(200, 2000)).dup/*+HenonN.ar(LFNoise2.kr(5).exprange(200, 10000)).dup*/))*(delay1+delay2+delay3+delay4+delay5);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outbus,fx1*env*pauseEnv);
}).add;


SynthDef("noiseGliss2_mod", {arg inBus, outBus, pulseRate, shift, vol, gate = 1, pauseGate = 1;
	var in, out0, env, pauseEnv;

	pauseEnv = EnvGen.kr(Env.asr(0.01,1,0.01), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0.01,1,0.01), gate, doneAction:2);

	in = In.ar(inBus, 1);

	out0 = PitchShift.ar(in, 0.2, shift);

	out0 = Latch.ar(out0, Impulse.ar(LFNoise0.kr(0.1).range(1000, 5000)));

	out0 = out0*Trig1.ar(Dust.kr(LFNoise0.kr(0.2).range(pulseRate, pulseRate*1.5)), LFNoise0.kr(0.3).range(0.025, 0.05)).lag(0.001);

	out0 = Pan2.ar(out0, SinOsc.ar(LFNoise0.kr(0.2).range(0.25, 1), Rand(0, 2pi)));

	Out.ar(outBus, out0*vol*pauseEnv*env);
}).add;



SynthDef("noiseGliss4_mod", {arg inBus, outBus, pulseRate, shift, vol, gate = 1, pauseGate = 1;
	var in, out0, env, pauseEnv;

	pauseEnv = EnvGen.kr(Env.asr(0.01,1,0.01), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0.01,1,0.01), gate, doneAction:2);

	in = In.ar(inBus, 1);

	out0 = PitchShift.ar(in, 0.2, shift);

	out0 = Latch.ar(out0, Impulse.ar(LFNoise0.kr(0.1).range(1000, 5000)));

	out0 = out0*Trig1.ar(Dust.kr(LFNoise0.kr(0.2).range(pulseRate, pulseRate*1.5)), LFNoise0.kr(0.3).range(0.025, 0.05)).lag(0.001);

	out0 = PanAz.ar(4, out0, SinOsc.ar(LFNoise0.kr(0.2).range(0.25, 1), Rand(0, 2pi)));

	Out.ar(outBus, out0*vol*pauseEnv*env);
}).add;



SynthDef("noiseGliss8_mod", {arg inBus, outBus, pulseRate, shift, vol, gate = 1, pauseGate = 1;
	var in, out0, env, pauseEnv;

	pauseEnv = EnvGen.kr(Env.asr(0.01,1,0.01), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0.01,1,0.01), gate, doneAction:2);

	in = In.ar(inBus, 1);

	out0 = PitchShift.ar(in, 0.2, shift);

	out0 = Latch.ar(out0, Impulse.ar(LFNoise0.kr(0.1).range(1000, 5000)));

	out0 = out0*Trig1.ar(Dust.kr(LFNoise0.kr(0.2).range(pulseRate, pulseRate*1.5)), LFNoise0.kr(0.3).range(0.025, 0.05)).lag(0.001);

	out0 = PanAz.ar(8, out0, SinOsc.ar(LFNoise0.kr(0.2).range(0.25, 1), Rand(0, 2pi)));

	Out.ar(outBus, out0*vol*pauseEnv*env);
}).add;


SynthDef("distortMonoA_mod", {arg inBus, outBus, compThreshBus, gainBus, limitBus, delayMult, gate = 1, pauseGate = 1;
	var out, outL, outR, pauseEnv, env, compThresh = 0.5, preGain = 1, limit = 0.5;

	compThresh = In.kr(compThreshBus);
	preGain = In.kr(gainBus);
	limit = In.kr(limitBus);

	out = In.ar(inBus);

	out = Compander.ar(out, out, compThresh, 1, 0.5, 0.01, 0.01);

	outL = Limiter.ar((Mix.new(out+DelayN.ar(out, 0.001*delayMult, 0.001*delayMult))*preGain).softclip, limit);

	outR = Limiter.ar((Mix.new(out+DelayN.ar(out, 0.002*delayMult, 0.0015*delayMult))*preGain).softclip, limit);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	out = LeakDC.ar([outL,outR]*pauseEnv*env);

	Out.ar(outBus, out);

}).add;
SynthDef("distortMonoB_mod", {arg inBus, outBus, compThreshBus, gainBus, limitBus, delayMult, gate = 1, pauseGate = 1;
	var out, outL, outR, pauseEnv, env, compThresh = 0.5, preGain = 1, limit = 0.5;

	compThresh = In.kr(compThreshBus);
	preGain = In.kr(gainBus);
	limit = In.kr(limitBus);

	out = In.ar(inBus);

	out = Compander.ar(out, out, compThresh, 1, 0.5, 0.01, 0.01);

	outL = Limiter.ar((Mix.new(out+DelayN.ar(out, 0.001*delayMult, 0.001*delayMult))*preGain).softclip, limit);

	outR = Limiter.ar((Mix.new(out+DelayN.ar(out, 0.002*delayMult, 0.0015*delayMult))*preGain).softclip, limit);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	out = LeakDC.ar([outR,outL]*pauseEnv*env);

	Out.ar(outBus, out);

}).add;


SynthDef("DSverb2_mod",{arg verbBus, verbVolBus, outBus, gate=1, pauseGate=1;
	var in, out, pauseEnv, env, verbVol;

	verbVol = In.kr(verbVolBus);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	in = In.ar(verbBus);
	out = GVerb.ar(in, 80, 4.85, 0.41, 0.19, 15, 0, 0);

	Out.ar(outBus, out*env*pauseEnv*verbVolBus);
}).add;
SynthDef("DSverb4_mod",{arg verbBus, verbVolBus, outBus, gate=1, pauseGate=1;
	var in, out, out2, pauseEnv, env, verbVol;

	verbVol = In.kr(verbVolBus);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	in = In.ar(verbBus,2);
	out = GVerb.ar(in[0], 80, 4.85, 0.41, 0.19, 15, 0, 0);
	out2 = GVerb.ar(in[1], 80, 4.85, 0.41, 0.19, 15, 0, 0);

	Out.ar(outBus, out*env*pauseEnv*verbVolBus);
	Out.ar(outBus+2, out2*env*pauseEnv*verbVolBus);
}).add;
SynthDef("DSverb8_mod",{arg verbBus, verbVolBus, outBus, gate=1, pauseGate=1;
	var in, out, out2, out3, out4, pauseEnv, env, verbVol;

	verbVol = In.kr(verbVolBus);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	in = In.ar(verbBus,4);
	out = GVerb.ar(in[0], 80, 4.85, 0.41, 0.19, 15, 0, 0);
	out2 = GVerb.ar(in[1], 80, 4.85, 0.41, 0.19, 15, 0, 0);
	out3 = GVerb.ar(in[2], 80, 4.85, 0.41, 0.19, 15, 0, 0);
	out4 = GVerb.ar(in[3], 80, 4.85, 0.41, 0.19, 15, 0, 0);

	Out.ar(outBus, out*env*pauseEnv*verbVolBus);
	Out.ar(outBus+2, out2*env*pauseEnv*verbVolBus);
	Out.ar(outBus+4, out3*env*pauseEnv*verbVolBus);
	Out.ar(outBus+6, out4*env*pauseEnv*verbVolBus);
}).add;



SynthDef("downShift2_mod", {|inBus, outBus, volBus, verbBus, length=1, delayTime, gate = 1, pauseGate = 1|
	var in, out, amp, decayTime, vol, env, pauseEnv, verbEnv;

	vol = In.kr(volBus);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	env = EnvGen.kr(Env.new([0,0,1,1,0], [delayTime, length/4,length/2,length/4]), gate, doneAction: 2);

	verbEnv = EnvGen.kr(Env.new([0,0,2], [delayTime, length]), gate, doneAction: 0);

	in = DelayC.ar(In.ar(inBus,1), delayTime, delayTime*[1,0.95]);

	out = PitchShift.ar(in, Rand(0.5, 1), [XLine.kr(Rand(1.95,2.05), Rand(0.25, 0.125), length),Line.kr(Rand(4,8), Rand(0.25, 0.125), length)].choose, 0, 0.1);

	out = out*pauseEnv*vol;

	Out.ar(outBus, out*env);
	Out.ar(verbBus, Mix.new(out)*verbEnv);

}).add;
SynthDef("downShift4_mod", {|inBus, outBus, volBus, verbBus, length=1, delayTime, start, gate = 1, pauseGate = 1|
	var in, out, amp, decayTime, vol, env, pauseEnv, verbEnv, out1, out2, out3, out4;

	vol = In.kr(volBus);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	env = EnvGen.kr(Env.new([0,0,1,1,0], [delayTime, length/4,length/2,length/4]), gate, doneAction: 2);

	verbEnv = EnvGen.kr(Env.new([0,0,2], [delayTime, length]), gate, doneAction: 0);

	in = DelayC.ar(In.ar(inBus,1), delayTime, delayTime*[1,0.95]);

	out = PitchShift.ar(in, Rand(0.5, 1), [XLine.kr(Rand(1.95,2.05), Rand(0.25, 0.125), length),Line.kr(Rand(4,8), Rand(0.25, 0.125), length)].choose, 0, 0.1);

	out = out*pauseEnv*vol;

	#out1, out3 = Pan2.ar(out[0], Line.kr(start, start.neg, length));
	#out2, out4 = Pan2.ar(out[1], Line.kr(start, start.neg, length));

	Out.ar(outBus, [out1, out2, out3, out4]*env);
	Out.ar(verbBus, Pan2.ar(Mix.new(out)*verbEnv, Line.kr(start, start.neg, length)));

}).add;
SynthDef("downShift8_mod", {|inBus, outBus, volBus, verbBus, length=1, delayTime, start, end, gate = 1, pauseGate = 1|
	var in, out, amp, decayTime, vol, env, pauseEnv, verbEnv, out1, out2, out3, out4, out5, out6, out7, out8;

	vol = In.kr(volBus);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	env = EnvGen.kr(Env.new([0,0,1,1,0], [delayTime, length/4,length/2,length/4]), gate, doneAction: 2);

	verbEnv = EnvGen.kr(Env.new([0,0,2], [delayTime, length]), gate, doneAction: 0);

	in = DelayC.ar(In.ar(inBus,1), delayTime, delayTime*[1,0.95]);

	out = PitchShift.ar(in, Rand(0.5, 1), [XLine.kr(Rand(1.95,2.05), Rand(0.25, 0.125), length),Line.kr(Rand(4,8), Rand(0.25, 0.125), length)].choose, 0, 0.1);

	out = out*pauseEnv*vol;

	#out1, out3, out5, out7 = PanAz.ar(4, out[0], Line.kr(start, end, length), orientation:0);
	#out2, out4, out6, out8 = PanAz.ar(4, out[1], Line.kr(start, end, length), orientation:0);

	Out.ar(outBus, [out1, out2, out3, out4, out5, out6, out7, out8]*env);
	Out.ar(verbBus, PanAz.ar(4, Mix.new(out)*verbEnv, Line.kr(start, end, length), orientation:0));

}).add;


SynthDef("floatShifter_mod", {|inBus, outBus, volBus, gate = 1, pauseGate = 1|
	var in, out, amp, decayTime, vol, env, pauseEnv, verbEnv;

	vol = In.kr(volBus);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	env = EnvGen.kr(Env.asr(0.1,1,2), gate, doneAction: 2);

	in = In.ar(inBus,2);

	out = PitchShift.ar(in, Rand(0.5, 1), TChoose.kr(Dust.kr(2), [1,0])+Rand(0.95, 1.05), Rand(0,0.05), Rand(0.1,0.7));

	out = out*pauseEnv*vol;

	Out.ar(outBus, out*env);

}).add;


SynthDef(\drumBombsAnal_mod, { arg inBus, inVol=0, thresh = 0.1, trigDiv, trigDivLow = 10, trigDivHigh = 10, muteGate = 1, gate = 1, pauseGate = 1;
	var sound, verb, trig, trig1, env, pauseEnv, shifted0, shifted1, shifted, amp, trigEnv, chain;

	sound = In.ar(inBus)*EnvGen.kr(Env.asr(0,1,0), muteGate, doneAction:0)*inVol;

	amp = Amplitude.kr(sound);

	chain = FFT(LocalBuf(1024), sound);

	trig = Onsets.kr(chain, thresh, \rcomplex);

	//trig1 = Decay2.kr(PulseDivider.kr(trig, trigDiv, 0), 0.05, 0.2);
	//trigDiv = TRand.kr(trigDivLow, trigDivHigh, trig1);

	SendTrig.kr(trig-0.1, 0, amp);

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);


}).add;

SynthDef(\drumBombsPlay_mod, { arg buffer, outBus, outVol=0, gate = 1, pauseGate = 1;
	var sig, env, pauseEnv;

	sig = PlayBuf.ar(2, buffer, 1);
	sig = Rotate2.ar(sig[0],sig[1], Rand(-1, 1));

	env = EnvGen.kr(Env([0,1,1,0],[0.02,BufDur.kr(buffer),0.02]), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, sig*env*pauseEnv*outVol);
}).add;


SynthDef("eightDelays2Line_mod", {arg start, end, time, length, delayBus, pauseGate=1;
	ReplaceOut.kr(delayBus, Line.kr(start, end, time, doneAction: 2));
	EnvGen.kr(Env.new([0,1],[length]), doneAction:2);
	EnvGen.kr(Env.asr(0.001, 1, 0.001), pauseGate);
}).add;

SynthDef("eightDelays2L2_mod", {arg inBus, outBus, delayBus, maxDelay, volBus, length, pauseGate = 1;
	var in, out, env, phasor, delayIn, out0, out1, out2, out3, out4, out5, out6, out7, pauseEnv, vol;

	vol = In.kr(volBus);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.ar(Env.new([0,1,1,0],[length/4, length/4, length/2]), 1, doneAction: 2);
	in = In.ar(inBus);

	delayIn = In.kr(delayBus);

	out0 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(1/8)), -1);
	out1 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(2/8)), -0.75);
	out2 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(3/8)), -0.5);
	out3 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(4/8)), -0.25);
	out4 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(5/8)), 0.25);
	out5 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(6/8)), 0.5);
	out6 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(7/8)), 0.75);
	out7 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(8/8)), 1);

	Out.ar(outBus, (out0+out1+out2+out3+out4+out5+out6+out7)*env*vol*pauseEnv);
}).add;

SynthDef("eightDelays2R2_mod", {arg inBus, outBus, delayBus, maxDelay, volBus, length, pauseGate = 1;
	var in, out, env, phasor, delayIn, out0, out1, out2, out3, out4, out5, out6, out7, pauseEnv, vol;

	vol = In.kr(volBus);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.ar(Env.new([0,1,1,0],[length/4, length/4, length/2]), 1, doneAction: 2);
	in = In.ar(inBus);

	delayIn = In.kr(delayBus);

	out0 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(1/8)), 1);
	out1 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(2/8)), 0.75);
	out2 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(3/8)), 0.5);
	out3 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(4/8)), 0.25);
	out4 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(5/8)), -0.25);
	out5 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(6/8)), -0.5);
	out6 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(7/8)), -0.75);
	out7 = Pan2.ar(DelayC.ar(in, maxDelay, delayIn*(8/8)), -1);

	Out.ar(outBus, (out0+out1+out2+out3+out4+out5+out6+out7)*env*vol*pauseEnv);
}).add;

//4 channel

SynthDef("eightDelays2L4_mod", {arg inBus, outBus, delayBus, maxDelay, volBus, length, pauseGate = 1;
	var in, out, env, phasor, delayIn, out0, out1, out2, out3, out4, out5, out6, out7, pauseEnv, vol;

	vol = In.kr(volBus);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.ar(Env.new([0,1,1,0],[length/4, length/4, length/2]), 1, doneAction: 2);
	in = In.ar(inBus);

	delayIn = In.kr(delayBus);

	out0 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(1/8)), -1);
	out1 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(2/8)), -0.75);
	out2 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(3/8)), -0.5);
	out3 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(4/8)), -0.25);
	out4 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(5/8)), 0.25);
	out5 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(6/8)), 0.5);
	out6 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(7/8)), 0.75);
	out7 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(8/8)), 1);

	Out.ar(outBus, (out0+out1+out2+out3+out4+out5+out6+out7)*env*vol*pauseEnv);
}).add;

SynthDef("eightDelays2R4_mod", {arg inBus, outBus, delayBus, maxDelay, volBus, length, pauseGate = 1;
	var in, out, env, phasor, delayIn, out0, out1, out2, out3, out4, out5, out6, out7, pauseEnv, vol;

	vol = In.kr(volBus);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.ar(Env.new([0,1,1,0],[length/4, length/4, length/2]), 1, doneAction: 2);
	in = In.ar(inBus);

	delayIn = In.kr(delayBus);

	out0 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(1/8)), 1);
	out1 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(2/8)), 0.75);
	out2 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(3/8)), 0.5);
	out3 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(4/8)), 0.25);
	out4 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(5/8)), -0.25);
	out5 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(6/8)), -0.5);
	out6 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(7/8)), -0.75);
	out7 = PanAz.ar(4, DelayC.ar(in, maxDelay, delayIn*(8/8)), -1);

	#out1, out2, out3, out4 = out0+out1+out2+out3+out4+out5+out6+out7;

	Out.ar(outBus, [out1, out2, out4, out3]*env*vol*pauseEnv);
}).add;

//8 channel

SynthDef("eightDelays2L8_mod", {arg inBus, outBus, delayBus, maxDelay, volBus, length, pauseGate = 1;
	var in, out, env, phasor, delayIn, out0, out1, out2, out3, out4, out5, out6, out7, pauseEnv, vol;

	vol = In.kr(volBus);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.ar(Env.new([0,1,1,0],[length/4, length/4, length/2]), 1, doneAction: 2);
	in = In.ar(inBus);

	delayIn = In.kr(delayBus);

	out0 = DelayC.ar(in, maxDelay, delayIn*(1/8));
	out1 = DelayC.ar(in, maxDelay, delayIn*(2/8));
	out2 = DelayC.ar(in, maxDelay, delayIn*(3/8));
	out3 = DelayC.ar(in, maxDelay, delayIn*(4/8));
	out4 = DelayC.ar(in, maxDelay, delayIn*(5/8));
	out5 = DelayC.ar(in, maxDelay, delayIn*(6/8));
	out6 = DelayC.ar(in, maxDelay, delayIn*(7/8));
	out7 = DelayC.ar(in, maxDelay, delayIn*(8/8));


	Out.ar(outBus, [out3,out4,out2,out5,out1,out6,out0,out7]*env*vol*pauseEnv);
}).add;

SynthDef("eightDelays2R8_mod", {arg inBus, outBus, delayBus, maxDelay, volBus, length, pauseGate = 1;
	var in, out, env, phasor, delayIn, out0, out1, out2, out3, out4, out5, out6, out7, pauseEnv, vol;

	vol = In.kr(volBus);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.ar(Env.new([0,1,1,0],[length/4, length/4, length/2]), 1, doneAction: 2);
	in = In.ar(inBus);

	delayIn = In.kr(delayBus);

	out0 = DelayC.ar(in, maxDelay, delayIn*(1/8));
	out1 = DelayC.ar(in, maxDelay, delayIn*(2/8));
	out2 = DelayC.ar(in, maxDelay, delayIn*(3/8));
	out3 = DelayC.ar(in, maxDelay, delayIn*(4/8));
	out4 = DelayC.ar(in, maxDelay, delayIn*(5/8));
	out5 = DelayC.ar(in, maxDelay, delayIn*(6/8));
	out6 = DelayC.ar(in, maxDelay, delayIn*(7/8));
	out7 = DelayC.ar(in, maxDelay, delayIn*(8/8));

	Out.ar(outBus, [out4,out3,out5,out2,out6,out1,out7,out0]*env*vol*pauseEnv);
}).add;


SynthDef("melter2_mod", {arg inBus, outBus, delayStart, delayEnd, ratio0, ratio1, length, volBus, gate = 1, pauseGate = 1;
	var in, out0, out1, env, phasor, delayTime, pauseEnv, vol, ratio, pan;

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.ar(Env.new([0, 1, 1, 0, 0],[length/8, 3*length/4, length/8, 1]), 1, doneAction: 2);

	in = In.ar(inBus)*env;

	vol = In.kr(volBus);

	ratio = Line.kr(ratio0, ratio1, length);

	out0 = PitchShift.ar(in, Rand(0.05,0.025), ratio, 0, 0.01);
	out1 = DelayC.ar(PitchShift.ar(in, Rand(0.025,0.05), ratio, 0, 0.01), 0.01, Rand(0.001, 0.01));

	pan = Rand(-0.9,0.9);

	Out.ar(outBus, Pan2.ar(out0*vol*pauseEnv, pan)+Pan2.ar(out1*vol*pauseEnv, pan+Rand(-0.07, 0.07)));
	//	Out.ar(outBus, Pan2.ar(out0*vol*pauseEnv, pan));
}).add;

SynthDef("melter4_mod", {arg inBus, outBus, delayStart, delayEnd, ratio0, ratio1, length, volBus, gate = 1, pauseGate = 1;
	var in, out0, out1, out2, out3, out4, env, phasor, delayTime, pauseEnv, vol, ratio, pan;

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.ar(Env.new([0, 1, 1, 0, 0],[length/8, 3*length/4, length/8, 1]), 1, doneAction: 2);

	in = In.ar(inBus)*env;

	vol = In.kr(volBus);

	ratio = Line.kr(ratio0, ratio1, length);

	out0 = PitchShift.ar(in, Rand(0.05,0.025), ratio, 0, 0.01);
	out1 = DelayC.ar(PitchShift.ar(in, Rand(0.025,0.05), ratio, 0, 0.01), 0.01, Rand(0.001, 0.01));

	pan = Rand(-0.9,0.9);

	#out1, out2, out3, out4 = PanAz.ar(4, out0*vol*pauseEnv, pan)+PanAz.ar(4, out1*vol*pauseEnv, pan.neg);

	Out.ar(outBus, [out1, out2, out4, out3]);
}).add;

SynthDef("melter8_mod", {arg inBus, outBus, delayStart, delayEnd, ratio0, ratio1, length, volBus, gate = 1, pauseGate = 1;
	var in, out0, out1, out2, out3, out4, out5, out6, out7, out8, env, phasor, delayTime, pauseEnv, vol, ratio, pan;

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.ar(Env.new([0, 1, 1, 0, 0],[length/8, 3*length/4, length/8, 1]), 1, doneAction: 2);

	in = In.ar(inBus)*env;

	vol = In.kr(volBus);

	ratio = Line.kr(ratio0, ratio1, length);

	out0 = PitchShift.ar(in, Rand(0.05,0.025), ratio, 0, 0.01);
	out1 = DelayC.ar(PitchShift.ar(in, Rand(0.025,0.05), ratio, 0, 0.01), 0.01, Rand(0.001, 0.01));

	pan = Rand(-0.9,0.9);

	#out1, out2, out3, out4, out5, out6, out7, out8 = PanAz.ar(8, out0*vol*pauseEnv, pan)+PanAz.ar(8, out1*vol*pauseEnv, pan.neg);

	Out.ar(outBus, [out1, out2, out8, out3, out7, out4, out6, out5]);
}).add;


SynthDef("longDelay2_mod", {arg inBus, outBus, volBus, delBus, decBus, panBus, gate = 1, pauseGate = 1;
	var in, out, env, phasor, out0, pauseEnv, delayTime=4, decayTime=20, vol=0, pan = 0;

	delayTime = In.kr(delBus);
	decayTime = In.kr(decBus);
	vol = In.kr(volBus);
	pan = In.kr(panBus);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.ar(Env.asr(0.1, 1, 0.1), gate, doneAction: 2);

	in = In.ar(inBus)*vol;
	out0 = Pan2.ar(AllpassC.ar(in, 17, delayTime, decayTime), pan);

	Out.ar(outBus, (out0)*env*pauseEnv);
}).add;

SynthDef("longDelay4_mod", {arg inBus, outBus, volBus, delBus, decBus, panBus, gate = 1, pauseGate = 1;
	var in, out, env, phasor, out0, pauseEnv, delayTime=4, decayTime=20, vol=0, pan = 0;

	delayTime = In.kr(delBus);
	decayTime = In.kr(decBus);
	vol = In.kr(volBus);
	pan = In.kr(panBus);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.ar(Env.asr(0.1, 1, 0.1), gate, doneAction: 2);

	in = In.ar(inBus)*vol;
	out0 = PanAz.ar(4, AllpassC.ar(in, 17, delayTime, decayTime), pan);

	Out.ar(outBus, [out0[0], out0[1], out0[3], out0[2]]*env*pauseEnv);
}).add;

SynthDef("longDelay8_mod", {arg inBus, outBus, volBus, delBus, decBus, panBus, gate = 1, pauseGate = 1;
	var in, out, env, phasor, out0, pauseEnv, delayTime=4, decayTime=20, vol=0, pan = 0;

	delayTime = In.kr(delBus);
	decayTime = In.kr(decBus);
	vol = In.kr(volBus);
	pan = In.kr(panBus);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.ar(Env.asr(0.1, 1, 0.1), gate, doneAction: 2);

	in = In.ar(inBus)*vol;
	out0 = PanAz.ar(8, AllpassC.ar(in, 17, delayTime, decayTime), pan);

	Out.ar(outBus, [out0[0], out0[1], out0[7], out0[2], out0[6], out0[3], out0[5], out0[4]]*env*pauseEnv);
}).add;


SynthDef("envGen_mod", {arg inBus, outBus, pulseRate0=0, onBypass=0, attack=0.01, release=1, curve=(-4), whichOscil=0, oscilFreq, oscilMult, gate = 1, pauseGate = 1;
	var env, localEnv, out, impulse, dust, mod, pauseEnv, oscil;

	oscil = Select.kr(whichOscil, [0, LFSaw.kr(oscilFreq, 0, oscilMult, oscilMult/2), LFTri.kr(oscilFreq, 0, oscilMult, oscilMult/2)]);

	impulse = Impulse.kr(pulseRate0+oscil);

	localEnv = EnvGen.kr(Env.perc(attack, release, 1, curve), impulse);

	mod = Lag.kr(Select.kr(onBypass, [1, localEnv]), 0.01);

	env = EnvGen.kr(Env.asr(0.01,1,0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, In.ar(inBus, 8)*env*mod*pauseEnv*mod);
}).add;


SynthDef("eqLowFilter_mod", {arg inBus, freqBus, rqBus, dbBus, lagTime=0, gate = 1, pauseGate = 1;
	var in, out, env, pauseEnv, freq, rq, db;

	freq = In.kr(freqBus);
	rq = In.kr(rqBus);
	db = In.kr(dbBus);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in  = In.ar(inBus, 8);

	out = BLowShelf.ar(in,freq,rq,Lag.kr(db, lagTime)+LFNoise1.kr(0.1));

	ReplaceOut.ar(inBus, out*env*pauseEnv);
}).add;
SynthDef("eqMidFilter_mod", {arg inBus, freqBus, rqBus, dbBus, lagTime=0, gate = 1, pauseGate = 1;
	var in, out, env, pauseEnv, freq, rq, db;

	freq = In.kr(freqBus);
	rq = In.kr(rqBus);
	db = In.kr(dbBus);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in  = In.ar(inBus, 8);

	out = MidEQ.ar(in,freq, Lag.kr(rq, lagTime), Lag.kr(db, lagTime)+LFNoise1.kr(0.1));

	ReplaceOut.ar(inBus, out*env*pauseEnv);
}).add;
SynthDef("eqHighFilter_mod", {arg inBus, freqBus, rqBus, dbBus, lagTime=0, gate = 1, pauseGate = 1;
	var in, out, env, pauseEnv, freq, rq, db;

	freq = In.kr(freqBus);
	rq = In.kr(rqBus);
	db = In.kr(dbBus);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in  = In.ar(inBus, 8);

	out = BHiShelf.ar(in,freq, rq,Lag.kr(db, lagTime)+LFNoise1.kr(0.1));

	ReplaceOut.ar(inBus, out*env*pauseEnv);
}).add;
SynthDef("eqOut_mod", {arg inBus, outBus, gate = 1, pauseGate = 1;
	var in, out, env, pauseEnv;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in  = In.ar(inBus, 8);

	Out.ar(outBus, in*env*pauseEnv);
}).add;


SynthDef("spectralLimiter_mod", {arg inBus, outBus, bufnum, threshold, mulBus0, tripBus, pauseGate = 1, gate=1;
	var mulArray0, tripMul, chain0, chain1, env, pauseEnv, in, fftSize, clip, outSig;

	fftSize = 2048;

	in = In.ar(inBus, 2);

	mulArray0 = Lag.kr(In.kr(mulBus0, 320), 0.1);

	tripMul = Lag.kr(In.kr(tripBus, 320), 3);

	FFT(bufnum, in[0]);

	chain0 = FFT(LocalBuf(fftSize), in[0], 0.75);

	chain0 = chain0.pvcollect(fftSize, {|mag, phase, index|
		mag*mulArray0[index]*tripMul[index];
	}, frombin: 0, tobin: 319, zeroothers: 1);

	env = EnvGen.kr(Env.asr(2,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	outSig = IFFT(chain0);

	Out.ar(outBus, outSig*env*pauseEnv);
}).add;


SynthDef("delayFeedback_mod", {arg inBus, outBus, volBus, delay = 0.02158, varAmount=0.5, varFreq=0.02, pauseGate = 1, gate = 1;
	var in, convolveAudio, volume, env, pauseEnv;

	volume = In.kr(volBus);

	//in  = LPF.ar(In.ar(inBus, 2), 2800);

	in  = In.ar(inBus, 2);

	in = Compander.ar(in, in,
		thresh: 0.5,
		slopeBelow: 1,
		slopeAbove: 0.5,
		clampTime: 0.01,
		relaxTime: 0.01
	);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, Mix.new(Limiter.ar(in, 0.1, 0.03)*volume));
}).add;


SynthDef("largeEnvFilt_mod",{arg outBusNum, gate=1, pauseGate=1;
	var env, out, pauseEnv;

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:0);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);
	Out.kr(outBusNum, env*pauseEnv);
}).add;

SynthDef("filterDelays2_mod", {arg inBusNum, outBus, largeEnvBusNum, filterStart, filterEnd, rqStart, rqEnd, delayTime, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, bigEnv, volume, xStart, xEnd;

	volume = In.kr(vol);

	largeEnv = In.kr(largeEnvBusNum, 1);
	in = In.ar(inBusNum, 1)*largeEnv;

	env = Env.new([0.001,1,1,0.001], [1,length,1], 'linear');
	bigEnv = Env.new([0.001,1,1,0.001], [0.01,length+delayTime+1.98,0.01], 'linear');

	in2 = EnvGen.ar(env, doneAction: 0)*EnvGen.ar(bigEnv, doneAction: 2)*in;

	xStart = Rand(-1,1);
	xEnd = Rand(-1,1);

	delayedSignal = DelayL.ar(in2, 7.5, delayTime);

	out = Pan2.ar(BPF.ar(
		delayedSignal,
		Line.kr(filterStart, filterEnd, length+2)+LFNoise1.kr(0.3,100, 200),
		Line.kr(rqStart, rqEnd, length+2)),
	Line.kr(xStart, xEnd, length+2));
	Out.ar(outBus, out*volume);
}).add;

SynthDef("filterDelays4_mod", {arg inBusNum, outBus, largeEnvBusNum, filterStart, filterEnd, rqStart, rqEnd, delayTime, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, bigEnv, volume, xStart, xEnd, yStart, yEnd;

	volume = In.kr(vol);

	largeEnv = In.kr(largeEnvBusNum, 1);
	in = In.ar(inBusNum, 1)*largeEnv;

	env = Env.new([0.001,1,1,0.001], [1,length,1], 'linear');
	bigEnv = Env.new([0.001,1,1,0.001], [0.01,length+delayTime+1.98,0.01], 'linear');

	in2 = EnvGen.ar(env, doneAction: 0)*EnvGen.ar(bigEnv, doneAction: 2)*in;

	xStart = Rand(-1,1);
	xEnd = Rand(-1,1);
	yStart = Rand(-1,1);
	yEnd = Rand(-1,1);

	delayedSignal = DelayL.ar(in2, 7.5, delayTime);
	out = Pan4.ar(BPF.ar(
		delayedSignal,
		Line.kr(filterStart, filterEnd, length+delayTime+2)+LFNoise1.kr(0.3,100, 200),
		Line.kr(rqStart, rqEnd, length+delayTime+2)),
	Line.kr(xStart, xEnd, length+2+delayTime),
	Line.kr(yStart, yEnd, length+2+delayTime)
	);
	Out.ar(outBus, out*volume);
}).add;

SynthDef("filterDelays8_mod", {arg inBusNum, outBus, largeEnvBusNum, filterStart, filterEnd, rqStart, rqEnd, delayTime, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, bigEnv, volume, azStart, azEnd;

	volume = In.kr(vol);

	largeEnv = In.kr(largeEnvBusNum, 1);
	in = In.ar(inBusNum, 1)*largeEnv;

	env = Env.new([0.001,1,1,0.001], [1,length,1], 'linear');
	bigEnv = Env.new([0.001,1,1,0.001], [0.01,length+delayTime+1.98,0.01], 'linear');

	in2 = EnvGen.ar(env, doneAction: 0)*EnvGen.ar(bigEnv, doneAction: 2)*in;

	azStart = Rand(-1,1);
	azEnd = azStart+Rand(-1,1);

	delayedSignal = DelayL.ar(in2, 7.5, delayTime);
	out = PanAz.ar(8, BPF.ar(
		delayedSignal,
		Line.kr(filterStart, filterEnd, length+delayTime+2)+LFNoise1.kr(0.3,100, 200),
		Line.kr(rqStart, rqEnd, length+delayTime+2)),
	Line.kr(azStart, azEnd, length+2+delayTime));
	Out.ar(outBus, out*volume);
}).add;


SynthDef("gestureLines_mod", {arg ratioBus, dispersionBus, start, end, length;
	Out.kr(ratioBus, XLine.kr(start, end, length+(length/4), doneAction:2));

	Out.kr(dispersionBus, Line.kr(Rand(0,1.0), Rand(0,1.0), length+(length/4)));

}).add;


SynthDef("filterGrainsB2_mod", {arg inBusNum, outBus, largeEnvBusNum, ratioBus, dispersionBus, filterStart, filterEnd, rqStart, rqEnd, delayTime, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, bigEnv, volume, xStart, xEnd, ratio, grains, dispersion,  winSize, filt;

	volume = In.kr(vol);

	largeEnv = In.kr(largeEnvBusNum, 1);
	in = In.ar(inBusNum, 1)*largeEnv;

	env = Env.new([0.001,1,1,0.001], [1,length,1]);
	bigEnv = Env.new([0.001,1,1,0.001], [0.01,length+delayTime+1.98,0.01]);

	in2 = EnvGen.ar(env, doneAction: 0)*EnvGen.ar(bigEnv, doneAction: 2)*in;

	xStart = Rand(-1,1);
	xEnd = Rand(-1,1);

	delayedSignal = DelayL.ar(in2, 5, delayTime);

	ratio = In.kr(ratioBus);

	//filt = BPF.ar(delayedSignal, ratio+LFNoise1.kr(0.3,100, 200), Line.kr(rqStart, rqEnd, length+delayTime+2));

	filt = BPF.ar(delayedSignal, Line.kr(filterStart, filterEnd, length+delayTime+2)+LFNoise1.kr(Rand(0.25, 0.35),100, 200), Line.kr(rqStart, rqEnd, length+delayTime+2));


	dispersion = In.kr(dispersionBus);
	winSize = Rand(0.1, 0.2);

	grains = PitchShift.ar(filt, winSize, ratio, dispersion*winSize, 0.2);
	//grains = PitchShift.ar(filt, winSize, 1, 0, winSize);

	out = Pan2.ar(grains,
		Line.kr(xStart, xEnd, length+2+delayTime));
	Out.ar(outBus, out*volume);
}).add;


SynthDef("filters_mod", {arg inBus, outBus, sweepTime0=10, sweepTime1=10, top=22000, bottom=0, upDown=0, whichOne=0;
	var saw, q, sweepTime, sig, noise0, noise2, in, ampIn, ampSig, out, impulse;

	q = LFNoise2.kr(0.87).range(0.025, 0.075);

	in = In.ar(inBus,8);

	ampIn = Amplitude.ar(in);

	sweepTime = LFNoise2.kr(1).range(sweepTime0, sweepTime1);

	impulse = Impulse.kr(1/sweepTime);

	saw = Phasor.ar(impulse, 1/(sweepTime*SampleRate.ir));

	saw = Select.kr(upDown, [1-saw, saw]);

	saw = LinLin.kr(saw, 0,1, TRand.kr(bottom, bottom+((top-bottom)/8), impulse), TRand.kr(top, top-((top-bottom)/8), impulse));

	noise0 = TRand.kr(bottom, top, impulse);

	noise2 = Lag3.kr(noise0, sweepTime);

	sig = LPF.ar(in, Lag3.kr(Select.kr(whichOne, [20000, saw+(saw*q/2), noise0+(noise0*q/2), noise2+(noise2*q/2)]), 0.1));
	sig = HPF.ar(sig, Lag3.kr(Select.kr(whichOne, [20, saw-(saw*q/2), noise0-(noise0*q/2), noise2-(noise2*q/2)]), 0.1));

	ampSig = Amplitude.ar(sig);

	sig = sig*(ampIn/(ampSig+0.001));

	Out.ar(outBus, sig);
}).add;


SynthDef("followerCrusher_mod", {arg inBus, outBus, inVol=0, synthVol=0, thresh=0.1, offOn = 0;
	var decay, freq, hasFreq, sigVol, sig, fx1, fx2, in, inMix;

	in = In.ar(inBus, 2);
	inMix = Mix.new(in);

	decay = 0.99;
	#freq, hasFreq = Pitch.kr(inMix);

	sigVol = PeakFollower.ar(inMix*hasFreq, decay);

	sigVol = LagUD.ar((sigVol > thresh)*sigVol, 0.01, 0.2);

	sig = SinOsc.ar((freq*4)+SinOsc.ar(freq, 0, SinOsc.kr(0.3).range(200,2000)), 0, 0.5*sigVol*synthVol).clip2(0.1);

	fx1=Latch.ar(sig.round(0.125),Impulse.ar(LFNoise2.ar(0.5).range(3000, 8000)));
	fx2=Latch.ar(sig.round(0.1),Impulse.ar(LFNoise2.ar(0.5).range(3000, 8000)));

	Out.ar(outBus, in*inVol);
	Out.ar(outBus, [fx1, fx2]*offOn);

}).add;


SynthDef("rdFreeze_mod", { arg audioInBus, audioOutBus, levelBus, t_keyTrig, volBus, threshBus, muteGateBus, onOffBus, buffer, gate = 1, pauseGate = 1;
	var audioIn, fftIn, chain, outSig, trig1, trig2, trig, amp, sin, peak, env, pauseEnv, muteEnv, vol, thresh, muteGate, onOff;

	vol = In.kr(volBus);
	thresh = In.kr(threshBus);
	muteGate = In.kr(muteGateBus);
	onOff = In.kr(onOffBus);

	audioIn = In.ar(audioInBus, 1)*EnvGen.kr(Env.dadsr(3,0,0,1,0), 1);

	amp = Amplitude.kr(audioIn)*EnvGen.kr(Env.asr(0.001, 1, 0.001), onOff);

	trig1 = Trig1.kr(Coyote.kr(audioIn, thresh: thresh, minDur: 0.1),0.1)*1.1;

	trig2 = Trig1.kr(t_keyTrig, 0.1)*1.1;

	trig = (trig1+trig2);

	chain = FFT(buffer, audioIn);

	chain = PV_Freeze(chain, ((1 - (trig+EnvGen.kr(Env.new([0,0,2,0], [0.5, 0.1,0.001]), 1)))*EnvGen.kr(Env.dadsr(3,0,0,1,0), 1)));
	outSig = IFFT(chain);

	peak = PeakFollower.ar(outSig, 0.99);
	Out.kr(levelBus, peak);

	sin = SinOsc.kr(Rand(0.09,1.1))*0.25;

	outSig = Compander.ar(outSig, outSig,
		thresh: 0.8,
		slopeBelow: 1,
		slopeAbove: 0.5,
		clampTime: 0.01,
		relaxTime: 0.01
	);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);
	muteEnv = EnvGen.kr(Env.asr(0.1,1,0.1), muteGate);

	outSig = outSig*vol*env*pauseEnv*muteEnv;

	Out.ar(audioOutBus, outSig);
}).add;


SynthDef("tFreeze2_mod", { arg inBus, outBus, modeBus, trigRateBus, dustOnBus, triggerOnce, volBus, gate = 1, pauseGate = 1, buffer0, buffer1;
	var audioIn, chain, outSig, trig, trig0, trig1, switch0, switch1, env, pauseEnv, trigRate, dustOn, vol, mode;

	audioIn = In.ar(inBus, 2)*EnvGen.kr(Env.dadsr(1,0,0,1,0), 1);

	dustOn = In.kr(dustOnBus);
	vol = In.kr(volBus);
	trigRate = In.kr(trigRateBus);
	mode = In.kr(modeBus);

	chain = FFT([buffer0,buffer1], audioIn);

	trig1 = 1-Trig1.kr(Dust.kr(trigRate, 0.1), 0.02);

	trig = triggerOnce+(trig1*dustOn);

	chain = PV_Freeze(chain, trig);

	outSig = IFFT(chain);

	outSig = Compander.ar(outSig, outSig, 0.5, 1, 0.5, 0.01, 0.01);

	switch0 = Lag.kr(Select.kr(mode, [1, 0]), 0.01);
	switch1 = Lag.kr(Select.kr(mode, [0, 1]), 0.01);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);

	Out.ar(outBus, ((audioIn*switch0)+(outSig*switch1*vol))*pauseEnv*env);
}).add;


SynthDef("glassSine2", {arg freq, volBus, outBus, vol=0, gate = 1, pauseGate = 1;
	var sine, env, pauseEnv, mainVol;

	pauseEnv = EnvGen.kr(Env.asr(0,1,6), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	sine = SinOsc.ar(freq+LFNoise2.kr(0.1, 5), 0, LagUD.kr(vol, LFNoise2.kr(0.1, 1.25, 1.5), LFNoise2.kr(0.1, 2.25, 3.5))*0.1);

	mainVol = Lag.kr(In.kr(volBus), 0.1);

	Out.ar(outBus, Pan2.ar(sine*AmpComp.kr(freq)*env*pauseEnv*mainVol, Rand(-1, 1)));
}).add;

SynthDef("glassSine4", {arg freq, volBus, outBus, vol=0, gate = 1, pauseGate = 1;
	var sine, env, pauseEnv, mainVol;

	pauseEnv = EnvGen.kr(Env.asr(0,1,6), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	sine = SinOsc.ar(freq+LFNoise2.kr(0.1, 5), 0, LagUD.kr(vol, LFNoise2.kr(0.1, 1.25, 1.5), LFNoise2.kr(0.1, 2.25, 3.5))*0.1);

	mainVol = Lag.kr(In.kr(volBus), 0.1);

	Out.ar(outBus, PanAz.ar(4, sine*AmpComp.kr(freq)*env*pauseEnv*mainVol, Rand(-1, 1)));
}).add;

SynthDef("glassSine8", {arg freq, volBus, outBus, vol=0, gate = 1, pauseGate = 1;
	var sine, env, pauseEnv, mainVol;

	pauseEnv = EnvGen.kr(Env.asr(0,1,6), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	sine = SinOsc.ar(freq+LFNoise2.kr(0.1, 5), 0, LagUD.kr(vol, LFNoise2.kr(0.1, 1.25, 1.5), LFNoise2.kr(0.1, 2.25, 3.5))*0.1);

	mainVol = Lag.kr(In.kr(volBus), 0.1);

	Out.ar(outBus, PanAz.ar(8, sine*AmpComp.kr(freq)*env*pauseEnv*mainVol, Rand(-1, 1)));
}).add;


SynthDef("gman",{arg sinFreq0, sinFreq1, gmanFreq0, gmanFreq1, dustFreq0, dustFreq1, dustFreq2, dustFreq3, dustFreq4, dustFreq5, selectFAM2=0, outBus, onOff = 1, vol = 0, gate=1, pauseGate = 1;
	var trig0, trig1, trig2, sinFreq, gmanFreq, out, fastAmpMod, slowAmpMod, fastAmpMod2, ampMod, pauseEnv, env;


	sinFreq = LFNoise0.kr(LFNoise0.kr(2).range(0.1, 8)).range(sinFreq0, sinFreq1);
	gmanFreq = LFNoise0.kr(LFNoise0.kr(5).range(0.1, 8)).range(gmanFreq0, gmanFreq1);

	trig0 = Dust.kr(LFNoise0.kr(2).range(dustFreq0, dustFreq1));
	fastAmpMod = Trig1.kr(trig0, TRand.kr(0.015,0.4,trig0));

	trig1 = Dust.kr(LFNoise0.kr(0.5).range(dustFreq2, dustFreq3));
	slowAmpMod = Lag.kr(1-Trig1.kr(trig1, TRand.kr(1.5/(dustFreq2+0.001*2), 1.5/(dustFreq3+0.001*2),trig1)), 0.001);

	trig2 = Dust.kr(LFNoise0.kr(0.5).range(dustFreq4, dustFreq5));
	fastAmpMod2 = Select.kr(selectFAM2, [1, Lag.kr(Trig1.kr(trig2, TRand.kr(0.01,0.05,trig2)), 0.001)]);

	ampMod = fastAmpMod*slowAmpMod*fastAmpMod2*Lag.kr(onOff, 0.001);

	out = SinOsc.ar(sinFreq, GbmanN.ar(gmanFreq) ,vol*ampMod).dup;

	//SendTrig.kr(Trig1.kr(ampMod, 0.01), 1, 1);
	//SendTrig.kr(Trig1.kr((1-ampMod).abs, 0.01), 0, 0);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	Out.ar(outBus, [out[0], Delay2.ar(out[1])].distort*pauseEnv*env);

	Out.ar(outBus+2, [Delay2.ar(out[0]), out[1]].distort*pauseEnv*env);
	Out.ar(outBus+4, [out[0], Delay2.ar(out[1])].distort*pauseEnv*env);
	Out.ar(outBus+6, [Delay2.ar(out[0]), out[1]].distort*pauseEnv*env);

}).add;


SynthDef("grainageRecord_mod", {arg inBus, bufnum, run, gate=1, pauseGate=1;
	var in, phasor, vol, env, smallEnv, pauseEnv;

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum));

	in = In.ar(inBus);

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	RecordBuf.ar(in, bufnum, run:run, loop:1);
}).add;

SynthDef("grainage2_mod", {arg outBus, bufnum, select, vol=1, trate=2, xPlace=0.5, smallGate=0, gate = 1, pauseGate=1;
	var dur, out, env, smallEnv, length, place, pan, pauseEnv;

	length = BufDur.kr(bufnum);

	dur = 4 / trate;

	place = Select.kr(select, [xPlace*length, LFNoise0.kr(10).range(0, length)]);

	pan = Select.kr(select, [xPlace*2-1, LFNoise0.kr(10).range(-1, 1)]);

	out = TGrains.ar(2, Impulse.ar(trate), bufnum, 1, place, dur, pan, 1, 2);

	smallEnv = EnvGen.ar(Env.asr(0.001, 1, 0.001, 'linear'),smallGate);
	env = EnvGen.ar(Env.asr(0.1, 1, 0.1, 'linear'),gate,doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, smallEnv*env*out*vol*pauseEnv);
}).add;


SynthDef(\gfdRecord_mod, { arg inBus, phaseBus, bufnum = 0, gate = 1, pauseGate = 1;
	var sound, phasor, env, pauseEnv;

	sound = In.ar(inBus);
	phasor = Phasor.ar(0, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum));

	Out.kr(phaseBus, phasor);

	BufWr.ar(sound, bufnum, phasor, 0, BufFrames.kr(bufnum));

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

}).add;

SynthDef(\gfdPlay2_mod, { arg inBus, phaseBus, outBus = 0, bufnum = 0, volBus, thresh = 0.1, trigDiv = 2, addPulse = 2, whichTrig=0, useOnOff = 0, offDensity = 0, impDust=0, t_trigShifter=0, t_trigShiftStay=0, shiftTime = 3, lockGate = 1, muteGate = 1, gate = 1, pauseGate = 1;
	var sound, impulse, trig, trig1, trig2, phase, impRate, out, latchPhase = 0, amp, toggleEnv, shiftTrig, shiftEnv, shiftStay, shift, vol, env, pauseEnv, muteEnv, onOffSwitch, phaseOffset, buf, chain;

	sound = In.ar(inBus);

	phase = In.kr(phaseBus);

	//				amp = Amplitude.kr(sound)*EnvGen.kr(Env.asr(0.001, 1, 0.001), lockGate);
	//
	//				trig = Trig1.kr((amp>thresh),0.05);

	//chain = FFT(fftBuf, sound);

	//trig = Impulse.kr(1);

	//trig = Trig1.kr((Onsets.kr(chain, thresh, mingap:LFNoise2.kr(0.3).range(100, 300))*EnvGen.kr(Env.asr(0.001, 1, 0.001), lockGate)),0.01);

	trig = Trig1.kr((Coyote.kr(sound, thresh: thresh)*EnvGen.kr(Env.asr(0.001, 1, 0.001), lockGate)),0.01);

	SendTrig.kr(trig,0, 1);

	//trig = PulseDivider.kr(trig, 4, 0);

	//PulseCount.kr(trig).poll;

	shiftTrig = Trig1.kr(t_trigShifter, shiftTime);

	shift = TExpRand.kr(0.25,4,t_trigShifter+t_trigShiftStay)-1;
	shiftEnv = EnvGen.kr(Env.new([0, shift, shift, 0],[0, shiftTime, 0]), shiftTrig);
	shiftStay = EnvGen.kr(Env.asr(0, shift, 0), ToggleFF.kr(t_trigShiftStay));

	//trig = Select.kr(shiftTrig, [trig, 0]);

	trig1 = PulseDivider.kr(trig, trigDiv, 0);
	trig2 = PulseDivider.kr(trig, trigDiv, addPulse);

	latchPhase = Latch.kr(phase, trig1);

	trig = Select.kr(whichTrig, [trig, trig1]);

	toggleEnv = Select.kr(whichTrig, [1, Lag.kr(SetResetFF.kr(trig1, trig2), 0.01)]);

	impRate = TExpRand.kr(5, 100, trig);

	impulse = Impulse.kr(impRate);

	impulse = Select.kr(impDust, [impulse, TChoose.kr(impulse, [impulse, 0], [0.95, 0.05])]);

	onOffSwitch = Select.kr(useOnOff, [1, Lag.kr(TChoose.kr(trig, [1,0], [1-offDensity, offDensity].normalizeSum), 0.01)]);

	phaseOffset = (LagUD.kr(1-trig, TRand.kr(2, 4, trig), 0)*TExpRand.kr(0.001, 0.025, trig));

	out = TGrains.ar(2, impulse, bufnum,1 /*(1+shiftEnv+shiftStay)*/, ((latchPhase-512)/44100)/*+phaseOffset*/, TRand.kr(2/impRate, 4/impRate, trig), TRand.kr(-1, 1, trig), 4);

	vol = In.kr(volBus);

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	muteEnv = EnvGen.kr(Env.asr(0,1,0), muteGate, doneAction:0);

	Out.ar(outBus, out*0.1*toggleEnv*env*pauseEnv*muteEnv*vol*onOffSwitch);

}).add;


SynthDef("gfnRecord_mod", {arg inBus, bufnum, dur=0.1, t_trig=0;
	var in, trig, env7;

	in = In.ar(inBus, 1);

	trig = Decay.kr(t_trig, dur);

	env7 = EnvGen.ar(Env.new([0,0,BufFrames.kr(bufnum), 0],[0, BufDur.kr(bufnum),0]), trig);

	BufWr.ar(in, bufnum, env7, 0);
}).add;

SynthDef("gfn2_mod", {arg inBus, outBus, volBus, bufnum, dur, playRate, attackTime=0, gate=0, pauseGate=0, t_trig=0;
	var in, out, env0, env1, env2, env7, vol, pan, impulse, volOsc, trig, pos;

	vol = In.kr(volBus);

	trig = Decay.kr(t_trig, dur);

	impulse = DelayC.kr(Impulse.kr(playRate), 0.05, 0.05);

	pos = EnvGen.kr(Env.new([0,dur/2, BufDur.kr(bufnum)-0.3], [0,1], 0.95), trig) + (SinOsc.kr(Rand(0.05, 0.1)).range((BufDur.kr(bufnum)-0.45).neg, 0)*EnvGen.kr(Env.new([0,0,0,1],[0,0.2, 2]), trig));

	out = TGrains.ar(2, impulse, bufnum, 1, pos, dur, LFNoise2.kr(Rand(2.0,4.0), 2), 2, 4);

	volOsc = SinOsc.kr(0.3, 0.5).range(0.7, 1);

	env1 = EnvGen.kr(Env.asr(attackTime,1,Rand(0.3,0.5)), gate, doneAction:0);

	env2 =  EnvGen.kr(Env.asr(0.2,1,Rand(1,1.5)), pauseGate, doneAction: 1);

	out = out*env1*env2*volOsc*vol;

	Out.ar(outBus, out);
}).add;

SynthDef("gfn4_mod", {arg inBus, outBus, volBus, bufnum, dur, playRate, attackTime=0, gate=0, pauseGate=0, t_trig=0;
	var in, out, env0, env1, env2, env7, vol, pan, impulse, volOsc, trig, pos;

	vol = In.kr(volBus);

	trig = Decay.kr(t_trig, dur);

	impulse = DelayC.kr(Impulse.kr(playRate), 0.05, 0.05);

	pos = EnvGen.kr(Env.new([0,dur/2, BufDur.kr(bufnum)-0.3], [0,1], 0.95), trig) + (SinOsc.kr(Rand(0.05, 0.1)).range((BufDur.kr(bufnum)-0.45).neg, 0)*EnvGen.kr(Env.new([0,0,0,1],[0,0.2, 2]), trig));

	out = TGrains.ar(4, impulse, bufnum, 1, pos, dur, LFNoise2.kr(Rand(2.0,4.0), 2), 2, 4);

	volOsc = SinOsc.kr(0.3, 0.5).range(0.7, 1);

	env1 = EnvGen.kr(Env.asr(attackTime,1,Rand(0.3,0.5)), gate, doneAction:0);

	env2 =  EnvGen.kr(Env.asr(0.2,1,Rand(1,1.5)), pauseGate, doneAction: 1);

	out = [out[0],out[1],out[3],out[2]]*env1*env2*volOsc*vol;

	Out.ar(outBus, out);
}).add;

SynthDef("gfn8_mod", {arg inBus, outBus, volBus, bufnum, dur, playRate, attackTime=0, gate=0, pauseGate=0, t_trig=0;
	var in, out, env0, env1, env2, env7, vol, pan, impulse, volOsc, trig, pos;

	vol = In.kr(volBus);

	trig = Decay.kr(t_trig, dur);

	impulse = DelayC.kr(Impulse.kr(playRate), 0.05, 0.05);

	pos = EnvGen.kr(Env.new([0,dur/2, BufDur.kr(bufnum)-0.3], [0,1], 0.95), trig) + (SinOsc.kr(Rand(0.05, 0.1)).range((BufDur.kr(bufnum)-0.45).neg, 0)*EnvGen.kr(Env.new([0,0,0,1],[0,0.2, 2]), trig));

	out = TGrains.ar(8, impulse, bufnum, 1, pos, dur, LFNoise2.kr(Rand(2.0,4.0), 2), 2, 4);

	volOsc = SinOsc.kr(0.3, 0.5).range(0.7, 1);

	env1 = EnvGen.kr(Env.asr(attackTime,1,Rand(0.3,0.5)), gate, doneAction:0);

	env2 =  EnvGen.kr(Env.asr(0.2,1,Rand(1,1.5)), pauseGate, doneAction: 1);

	out = [out[0],out[1],out[7],out[2],out[6],out[3],out[5],out[4]]*env1*env2*volOsc*vol;

	Out.ar(outBus, out);
}).add;


SynthDef("grainInterrupt_mod", {arg inBus, outBus, xFadeVal, ratio=1, lfoSwitch = 0, lfoFreq=0.2, mult=1, add=0.25, negMult=1, gate = 1, pauseGate = 1;
	var out, in, shift, shiftL, shiftR, pauseEnv, env, lfo, internalRatio, pDisp=0, tDisp=0;

	in = In.ar(inBus, 2);

	lfo = LFSaw.kr(lfoFreq, 0, mult*negMult, mult/2+add+0.25);

	internalRatio = Select.kr(lfoSwitch, [ratio, lfo]);

	pDisp = LFNoise2.kr(0.5, 0.12, 0.13).abs;
	tDisp = LFNoise2.kr(0.4, 0.08, 0.09).abs;

	#shiftL, shiftR = PitchShift.ar(in, 0.02, internalRatio, pDisp, tDisp);

	shiftL = Pan2.ar(shiftL, Lag.kr(TRand.kr(-1,0,Dust.kr(0.1)), 0.05));
	shiftR = Pan2.ar(shiftR, Lag.kr(TRand.kr(0,1,Dust.kr(0.1)), 0.05));

	shift = shiftL+shiftR;

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	out = SelectX.ar(Lag.kr(xFadeVal,0.02), [in, shift*1.5]);

	Out.ar(outBus, out*pauseEnv*env);

}).add;


SynthDef("greatExpectations_mod", { arg outBus, inBus, verbVol, allpassVol, verbTime, gate = 1, pauseGate = 1;
	var in, in2, verbSig, env, pauseEnv, out;
	var shifties, freq, hasFreq, amp, wave, allpass;

	env = EnvGen.kr(Env.asr(0,1,0.5), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in = In.ar(inBus,1);

	allpass = CombC.ar(in, 1, Array.fill(60, {rrand(0.05, 1)}), Array.fill(60, {rrand(5,10)}), LFNoise2.kr(LFNoise2.kr(0.5).range(0.1, 0.2)).range(0,1) );

	allpass = Splay.ar(allpass);

	//amp = Amplitude.kr(in, 0.1, 0.3);

	/*#freq, hasFreq = Pitch.kr(in, 440, 120, 700);

	wave = LFTri.ar(freq*[0.12495, 0.12505], 0, amp);*/

	in2 = PitchShift.ar(in, 0.2, [0.125,0.25], 0, 0.1);

	//in2 = CombC.ar(shifties, 0.1, [ 0.052898466587067, 0.040793769359589, 0.053465979099274, 0.049592454433441, 0.05687507390976, 0.057903006076813 ], 5);

	verbSig = GVerb.ar(Mix.new(in2), 100, verbTime, 0.5, 1, 15, 0, 0.1, 0.1, 100);

	verbSig = LPF.ar(verbSig, 400);

	out = (verbSig*verbVol)+(allpass*allpassVol);

	Out.ar(outBus, out*env*pauseEnv);
}).add;


SynthDef("largeEnvHD_mod",{arg outBusNum, attack, decay, gate=1, pauseGate=1;
	var env, out, pauseEnv;

	env = Env.asr(attack,1,decay);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate);

	Out.kr(outBusNum, EnvGen.kr(env, gate, doneAction: 2)*pauseEnv);
}).add;

SynthDef("harmonicDoubler_mod", {arg inBusNum, outBus, largeEnvBusNum, xStart, xEnd, pitchRatio, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, volume;

	volume = In.kr(vol);

	in = In.ar(inBusNum, 1);
	largeEnv = In.kr(largeEnvBusNum, 1);

	env = EnvGen.ar(Env.sine(length, 1), doneAction:2);

	out = PitchShift.ar(in, 0.1, pitchRatio, 0, 0.01);

	out = Pan2.ar(out, Line.kr(xStart, xEnd, length));
	Out.ar(outBus, out*volume*env);
}).add;


SynthDef("largeEnvHD_mod",{arg outBusNum, attack, decay, gate=1, pauseGate=1;
	var env, out, pauseEnv;

	env = Env.asr(attack,1,decay);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate);

	Out.kr(outBusNum, EnvGen.kr(env, gate, doneAction: 2)*pauseEnv);
}).add;

SynthDef("harmonicDoubler_mod", {arg inBusNum, outBus, largeEnvBusNum, xStart, xEnd, pitchRatio, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, volume;

	volume = In.kr(vol);

	in = In.ar(inBusNum, 1);
	largeEnv = In.kr(largeEnvBusNum, 1);

	env = EnvGen.ar(Env.sine(length, 1), doneAction:2);

	out = PitchShift.ar(in, 0.1, pitchRatio, 0, 0.01);

	out = Pan2.ar(out, Line.kr(xStart, xEnd, length));
	Out.ar(outBus, out*volume*env);
}).add;

SynthDef("harmonicDoubler2_mod", {arg inBusNum, outBus, largeEnvBusNum, xStart, xEnd, pitchRatio, delayTime, decayTime, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, volume, env2;

	volume = In.kr(vol);

	in = In.ar(inBusNum, 1);
	largeEnv = In.kr(largeEnvBusNum, 1);

	env = EnvGen.ar(Env.new([0,1,0,0], [length/2,length/2,decayTime], 'sine'), doneAction:2);

	env2 = EnvGen.ar(Env.new([0,0,1,0],[length/2,delayTime/2,delayTime/2], 'sine'), doneAction:0);

	out = PitchShift.ar(in, 0.1, pitchRatio, 0, 0.01);

	out = (out*env)+CombC.ar(out*env2, delayTime, delayTime, decayTime);

	out = Pan2.ar(out, Line.kr(xStart, xEnd, decayTime));

	Out.ar(outBus, out*volume*env);
}).add;


SynthDef("largeEnvShifter_mod",{arg outBusNum, attack, decay, gate;
	var env, out;

	env = Env.asr(attack,1,decay);
	Out.kr(outBusNum, EnvGen.kr(env, gate, doneAction: 2));
}).add;
SynthDef(\audioDelay_mod, {arg inBus, outBus, delayTime;
	var in;

	in = DelayC.ar(In.ar(inBus), delayTime, delayTime);

	Out.ar(outBus, in);
}).add;

SynthDef(\shifterX2_mod, {arg inBus, outBus1, outBus2, outBus3, outBus4, length, delayTime, windowSize, pitchRatio, 				pitchDisp, xStart, xEnd, yStart, yEnd, largeEnvBusNum;
	var in, in2, out1, out2, out3, out4, addToSlope, env, bigEnv, largeEnv;

	addToSlope = length/4;
	env = Env.new([0.001,1,1,0.001], [addToSlope+1,length-(2+(2*addToSlope)),1+addToSlope], 'linear');
	bigEnv = Env.new([0.001, 1, 1, 0.001], [0.001, length + addToSlope + delayTime +2, 0.001], 'linear');

	largeEnv = In.kr(largeEnvBusNum, 1);

	in = In.ar(inBus, 1);

	in2 =  in*EnvGen.kr(bigEnv, doneAction: 2)*EnvGen.kr(env, doneAction: 0)*largeEnv;

	# out1, out2, out3, out4 = Pan4.ar(
		PitchShift.ar(DelayL.ar(in2, 0.5, delayTime), windowSize, pitchRatio, pitchDisp),					Line.kr(xStart, xEnd, length+2.1+delayTime),					Line.kr(yStart, yEnd, length+2.1+delayTime)
	);

	Out.ar(outBus1, out1);
	Out.ar(outBus2, out2);
	Out.ar(outBus3, out3);
	Out.ar(outBus4, out4);
}).add;


SynthDef("interruptDelays_mod", {arg inBus, outBus, volBus, delGap0 = 0.5, delGap1 = 0.5, delGap2 = 0.5, delGap3 = 0.5, delGap4 = 0.5, delGap5 = 0.5, delGap6 = 0.5, delGap7 = 0.5, delaySwitch=0, gate = 1, pauseGate = 1;
	var in, out, out0, out1, out2, out3, out4, out5, out6, out7, vol, env, pauseEnv;

	vol = In.kr(volBus);

	env = EnvGen.kr(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in = In.ar(inBus, 8);

	out0 = Mix(DelayC.ar(in[0], 4.0, [delGap0, delGap2, delGap3, delGap4, delGap5, delGap6, delGap7]));
	out1 = Mix(DelayC.ar(in[1], 4.0, [delGap0, delGap2, delGap3, delGap4, delGap5, delGap6, delGap7]));
	out2 = Mix(DelayC.ar(in[2], 4.0, [delGap0, delGap2, delGap3, delGap4, delGap5, delGap6, delGap7]));
	out3 = Mix(DelayC.ar(in[3], 4.0, [delGap0, delGap2, delGap3, delGap4, delGap5, delGap6, delGap7]));
	out4 = Mix(DelayC.ar(in[4], 4.0, [delGap0, delGap2, delGap3, delGap4, delGap5, delGap6, delGap7]));
	out5 = Mix(DelayC.ar(in[5], 4.0, [delGap0, delGap2, delGap3, delGap4, delGap5, delGap6, delGap7]));
	out6 = Mix(DelayC.ar(in[6], 4.0, [delGap0, delGap2, delGap3, delGap4, delGap5, delGap6, delGap7]));
	out7 = Mix(DelayC.ar(in[7], 4.0, [delGap0, delGap2, delGap3, delGap4, delGap5, delGap6, delGap7]));

	out = [out0, out1, out2, out3, out4, out5, out6, out7];

	out = in+(LagUD.kr(delaySwitch, 0.05, 0.2)*out*vol);

	Out.ar(outBus, out);
}).add;


SynthDef("interruptDistortion_mod", {arg inBus, outBus, sinRate=1, volBus, distortBus, distortSwitch=0, gate = 1, pauseGate = 1;
	var in, out, chan1, chan2, delayTime, pan, pauseEnv, env, muteEnv, vol;

	vol = In.kr(volBus);
	//distortSwitch = In.kr(distortBus);

	env = EnvGen.kr(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in = In.ar(inBus, 2);

	chan1 = Mix.new(in);

	delayTime = (chan1 * LFNoise2.kr(2, 0.05, 0.01)) + 0.15;
	chan1 = DelayC.ar(chan1, 0.25, delayTime).distort;
	pan = SinOsc.ar(sinRate);
	chan2 = DelayC.ar(chan1, 0.025, 0.025).neg.softclip;
	out = Pan2.ar(chan1, pan) + Pan2.ar(chan2, pan.neg);


	out = (Lag.kr(1-distortSwitch, 0.05)*in)+(Lag.kr(distortSwitch, 0.05)*out*vol);

	Out.ar(outBus, out);
}).add;


SynthDef("inturruptLoopRecord_mod", {arg inBus, outBus, bufnum, phasorBus, smallGate = 1, gate=1, pauseGate=1;
	var in, phasor, vol, env, smallEnv, pauseEnv;

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum)*smallGate, 0, BufFrames.kr(bufnum));
	Out.kr(phasorBus, A2K.kr(phasor));

	in = In.ar(inBus,8);

	smallEnv = EnvGen.kr(Env.asr(0.02,1,0.02), smallGate);
	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	BufWr.ar(in, bufnum, phasor, loop:1);

	Out.ar(outBus, in*env*smallEnv*pauseEnv);
}).add;
SynthDef("inturruptLoopPlay_mod", {arg outBus, bufnum, phaseStart, phaseLength, gate=1, pauseGate=1;
	var playBack, phase, env, pauseEnv;

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	phase = (Phasor.ar(0, BufRateScale.kr(bufnum), 0, phaseLength)+phaseStart).wrap(0, BufFrames.kr(bufnum));

	playBack = BufRd.ar(8, bufnum, phase, loop:1)*env*pauseEnv;

	XOut.ar(outBus, env, playBack);
}).add;

SynthDef("inturruptLoopPlayJumpy_mod", {arg outBus, bufnum, phaseStart, phaseLength, gate=1, pauseGate=1;
	var playBack, phase, env, pauseEnv, phaseStart2;

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	//phaseStart2 = TRand.kr(phaseStart-phaseLength, phaseStart, Impulse.kr(1/(phaseLength/BufFrames.kr(bufnum))));
	phaseStart2 = TRand.kr(phaseStart-(BufFrames.kr(bufnum)/8), phaseStart, Impulse.kr((1/(phaseLength/(BufFrames.kr(bufnum)/8)))/(Rand(3, 7).floor)));

	phase = (Phasor.ar(0, BufRateScale.kr(bufnum), 0, phaseLength)+phaseStart2).wrap(0, BufFrames.kr(bufnum));

	playBack = BufRd.ar(8, bufnum, phase, loop:1)*env*pauseEnv;

	XOut.ar(outBus, env, playBack);
}).add;


SynthDef("interruptSine_mod", {arg inBus, outBus, volBus, pulseRate, whichSig = 0, t_shortTrigger=0, t_freqTrigger=0, gate = 1, pauseGate = 1;
	var in, sine, out, freq, switch, dust, impulseRate, pauseEnv, env, muteEnv, vol, trig;

	vol = In.kr(volBus);

	env = EnvGen.kr(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	dust = Dust.kr(pulseRate);

	switch = Select.kr(whichSig, [0, Trig1.kr(Decay.kr(t_shortTrigger,0.1), TRand.kr(0.3, 0.7)), Trig1.kr(Impulse.kr(pulseRate), 1/(2*pulseRate)), Trig1.kr(dust, TRand.kr(0.05, 0.15, dust))]);

	in = In.ar(inBus, 8);

	trig = Trig1.kr(Decay.kr(t_freqTrigger, 0.02), 0.1);

	freq = TRand.kr(60, 10000, Select.kr(TChoose.kr(trig, [0,1]), [trig, switch]));

	//sine	= SinOsc.ar([freq, freq+Rand(-1,1), freq+Rand(-1,1), freq+Rand(-1,1), freq+Rand(-1,1), freq+Rand(-1,1), freq+Rand(-1,1), freq+Rand(-1,1)]);

	sine = SinOsc.ar([freq, freq+Rand(-1,1)]);

	out = (Lag.kr(1-switch, 0.05)*in)+(Lag.kr(switch, 0.05)*sine*vol);

	Out.ar(outBus, out);
}).add;


SynthDef("largeArcLoopsRec_mod", {arg inBus, outBus, phasorBus, bufnum, t_trig=0, gate=1, pauseGate=1;
	var in, phasor, phaseStart, env, pauseEnv, resetTrig;

	in = In.ar(inBus,1);

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum));

	//phaseStart = Latch.kr(phasor, t_trig);

	env = EnvGen.kr(Env.asr(0, 1, 5), gate, doneAction:2);

	Out.kr(phasorBus, phasor);

	BufWr.ar(in, bufnum, phasor, loop:1);
}).add;

SynthDef("largeArcLoopsPlay_mod", {arg outBus, transferBus, volBus, phasorBus, bufnum, impulseRate, arcDur, panStart, panEnd, gate=1, pauseGate=1;
	var trig, phaseStart, env, smallEnv, pauseEnv, durs, dur, vol, out, verbLine, rate;

	phaseStart = Latch.kr(In.kr(phasorBus),Line.kr(-1, 1, 0.1))-(Rand(22000, 44000));

	trig  = Impulse.ar(Line.kr(impulseRate, impulseRate+Rand(-0.25, 0.25, arcDur)));

	verbLine = EnvGen.kr(Env.new([1, Rand(0.2, 0.5), 1], [arcDur/2,arcDur/2]), 1);

	rate = XLine.kr(1, ExpRand(0.5, 2), arcDur);

	out = TGrains.ar(2, trig, bufnum, rate, (phaseStart/BufFrames.kr(bufnum)*30)+Line.kr(0, Rand(1,3), arcDur), 2/impulseRate, Line.kr(panStart, panEnd, arcDur));

	env = EnvGen.kr(Env.new([0,1,0],[arcDur/3, 2*arcDur/3], \sine), doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	vol = In.kr(volBus);

	out = out*env*pauseEnv*vol;

	Out.ar(transferBus, out*verbLine);

	Out.ar(outBus, out);
}).add;

SynthDef("largeArcVerb_mod", {arg transferBus, outBus, gate=1, pauseGate=1;
	var in, out, env, pauseEnv;

	in = In.ar(transferBus, 2);

	out = FreeVerb2.ar(in[0], in[1], 1, 0.7, 1, 0.8)+FreeVerb2.ar(in[0], in[1], 1, 0.9, 1, 0.08);

	env = EnvGen.kr(Env.asr(0, 1, 5), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, out*env*pauseEnv);
}).add;


SynthDef("loopBufRecord_mod", {arg inBus, outBus, bufnum, phasorBus, volBus, smallGate = 1, gate=1, pauseGate=1;
	var in, phasor, vol, env, smallEnv, pauseEnv;

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum)*smallGate, 0, BufFrames.kr(bufnum));
	Out.kr(phasorBus, A2K.kr(phasor));

	in = In.ar(inBus,8);

	//in = In.ar(inBus,2);

	vol = In.kr(volBus);

	smallEnv = EnvGen.kr(Env.asr(0.02,1,0.02), smallGate);
	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	BufWr.ar(in*smallEnv, bufnum, phasor, loop:1);

	Out.ar(outBus, in*vol*env*pauseEnv);
}).add;

SynthDef("loopBufPlay_mod", {arg outBus, bufnum, rateBus, phasorBus, volBus, rateSwitch = 0, gate=1, pauseGate=1;
	var playBack, phaseStart, phase, env, rate, vol, pauseEnv, dust;

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	vol = In.kr(volBus);

	dust = Dust.kr(5);
	rate = Select.kr(rateSwitch, [In.kr(rateBus), TRand.kr(2,4,dust)*Select.kr(TIRand.kr(0,1,dust), [-1, 1])]);

	phaseStart = Select.kr(rateSwitch, [Latch.kr(In.kr(phasorBus),1), TRand.kr(0,BufFrames.kr(bufnum),dust)]);
	phase = (Phasor.ar(0, BufRateScale.kr(bufnum)*rate, 0, BufFrames.kr(bufnum))+phaseStart).wrap(0, BufFrames.kr(bufnum));

	playBack = BufRd.ar(8, bufnum, phase, loop:1)*env*vol*pauseEnv;

	XOut.ar(outBus, env, playBack);
}).add;


SynthDef("loopBufRecordOverlap_mod", {arg inBus, outBus, bufnum, phasorBus, volBus, smallGate0 = 0, smallGate = 0, gate=1, pauseGate=1;
	var in, phasor, vol, env, smallEnv, pauseEnv, internalSmallGate;

	internalSmallGate = 1-((smallGate+smallGate0).clip(0,1));

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum)*internalSmallGate, 0, BufFrames.kr(bufnum));
	Out.kr(phasorBus, A2K.kr(phasor));

	in = In.ar(inBus,8);

	//in = In.ar(inBus,2);

	vol = In.kr(volBus);

	smallEnv = EnvGen.kr(Env.asr(0.02,1,0.02), internalSmallGate);
	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	BufWr.ar(in*smallEnv, bufnum, phasor, loop:1);

	Out.ar(outBus, in*vol*env*pauseEnv);
}).add;
SynthDef("loopMachineOverLapSamplePlayer_mod", {arg bufnum, outBus, playRate=1, numGrains = 1, startPos, startPos0, dur, phasorBus, t_trig=0, vol=0, onOff = 0, z1OnOff = 0, z2OnOff = 0, pauseGate = 1, gate = 1;
	var env, pauseEnv, onOffEnv, impulse, out, pan, fade, trigRate, trigRateA, duration, envs;
	var playBuf, toggle, counter, phaseStart, onOffTotal;

	env = EnvGen.kr(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.05,1,0.01), pauseGate, doneAction:1);

	duration = (BufDur.kr(bufnum)*dur*(1/(playRate.abs))).clip(0.02, BufDur.kr(bufnum)/(playRate.abs));

	trigRate = (numGrains/(duration-0.01)).clip(1/(duration-0.01));

	//fade = (BufDur.kr(bufnum)/playRate - ((BufDur.kr(bufnum)/numGrains))).clip(0.01, duration/2);

	fade = (duration-(duration/numGrains)).clip(0.01, duration/2);

	impulse = Impulse.kr(trigRate);
	counter = Stepper.kr(impulse, 0, 0, 7, 1);

	toggle = Select.kr(counter, [[1,0,0,0,0,0,0,0],[0,1,0,0,0,0,0,0],[0,0,1,0,0,0,0,0],[0,0,0,1,0,0,0,0],[0,0,0,0,1,0,0,0],[0,0,0,0,0,1,0,0],[0,0,0,0,0,0,1,0],[0,0,0,0,0,0,0,1]]);

	envs = EnvGen.kr(Env.asr(fade, 1, fade, 'welch'), toggle);

	phaseStart = Latch.kr(In.kr(phasorBus),Decay.kr(t_trig, 0.01)-0.2);

	startPos = Select.kr((playRate+4/4).floor.clip(0, 1), [startPos0, startPos]);

	counter = Stepper.kr(impulse, 0, 0, 3, 1);

	playBuf = PlayBuf.ar(8, bufnum, playRate*BufRateScale.kr(bufnum), toggle, startPos*BufFrames.kr(bufnum), 1)*envs;

	out = Mix(playBuf);

	onOffTotal = Lag.kr((onOff+z1OnOff+z2OnOff).clip(0,1), 0.05);

	XOut.ar(outBus, onOffTotal, out*env*pauseEnv*vol);

}).add;


SynthDef("straightLoopRec_mod", {arg inBus, outBus, phaseBus, bufnum, t_trig=0, gate=1, pauseGate=1;
	var in, phasor, phaseStart, env, pauseEnv, resetTrig;

	//resetTrig = Decay2.kr(t_trig, 0.001);

	in = In.ar(inBus,2);

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum));

	phaseStart = Latch.kr(phasor, t_trig);

	Out.kr(phaseBus, phaseStart);

	Out.ar(outBus, in);

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	BufWr.ar(in, bufnum, phasor, loop:1);
}).add;
SynthDef("straightLoopPlay_mod", {arg outBus, phaseBus, bufnum, loopDur, gate=1, pauseGate=1;
	var sig1, sig2, env1, env2, trig, trig1, trig2, phaseStart, env, smallEnv, pauseEnv, resetTrig, durs, dur;

	phaseStart = In.kr(phaseBus)-(loopDur*BufSampleRate.kr(bufnum));

	trig  = Impulse.ar(1/(loopDur-0.02));

	//durs = Dwhite(loopDur-0.05
	//trig = TDuty.kr(durs);

	//dur = Demand.kr(trig, 0, durs);

	trig1 = PulseDivider.ar(trig, 2, 0);
	trig2 = PulseDivider.ar(trig, 2, 1);

	env1 = EnvGen.ar(Env.new([0,1,1,0],[0.01, loopDur-0.02, 0.01]), trig1);
	env2 = EnvGen.ar(Env.new([0,1,1,0],[0.01, loopDur-0.02, 0.01]), trig2);

	sig1 = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), trig1, phaseStart-(TRand.ar(0,10000, trig1)), loop: 1)*env1;
	sig2 = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), trig2, phaseStart-(TRand.ar(0,10000, trig2)), loop: 1)*env2;

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	XOut.ar(outBus,env, (sig1+sig2)*env*pauseEnv);
}).add;


SynthDef("straightLoop2Rec_mod", {arg inBus, phaseBus, bufnum, t_trig=0, gate=1, pauseGate=1;
	var in, phasor, phaseStart, env, pauseEnv, resetTrig;

	//resetTrig = Decay2.kr(t_trig, 0.001);

	in = In.ar(inBus,2);

	RecordBuf.ar(in, bufnum, doneAction:2);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

}).add;
SynthDef("straightLoop2Play_mod", {arg outBus, phaseBus, bufnum, loopDur, gate=1, pauseGate=1;
	var sig1, sig2, env1, env2, trig, trig1, trig2, env, smallEnv, pauseEnv, resetTrig, durs, dur;

	trig  = Impulse.ar(1/(loopDur-0.02));

	trig1 = PulseDivider.ar(trig, 2, 0);
	trig2 = PulseDivider.ar(trig, 2, 1);

	env1 = EnvGen.ar(Env.new([0,1,1,0],[0.01, loopDur-0.02, 0.01]), trig1);
	env2 = EnvGen.ar(Env.new([0,1,1,0],[0.01, loopDur-0.02, 0.01]), trig2);

	sig1 = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), trig1)*env1;
	sig2 = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), trig2)*env2;

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus,(sig1+sig2)*env*pauseEnv);
}).add;


SynthDef("grabNLoopRec_mod", {arg inBus, outBus, phaseBus, bufnum, t_trig=0, gate=1, pauseGate=1;
	var in, phasor, phaseStart, env, pauseEnv, resetTrig;

	//resetTrig = Decay2.kr(t_trig, 0.001);

	in = In.ar(inBus,1);

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum), 0, BufFrames.kr(bufnum));

	phaseStart = Latch.kr(phasor, t_trig);

	env = EnvGen.kr(Env.asr(0, 1, 5), gate, doneAction:2);

	Out.kr(phaseBus, phaseStart);

	//Out.ar(outBus, in);

	BufWr.ar(in, bufnum, phasor, loop:1);
}).add;
SynthDef("grabNLoopPlay_mod", {arg outBus, phaseBus, bufnum, loopDur, volBus, gate=1, pauseGate=1;
	var sig1, sig2, env1, env2, trig, trig1, trig2, phaseStart, env, smallEnv, pauseEnv, resetTrig, durs, dur, phaseAdjust, vol;

	phaseStart = Latch.kr(In.kr(phaseBus), Line.kr(-1, 1, 0.1))-(loopDur*BufSampleRate.kr(bufnum));

	trig  = Impulse.ar(2/(loopDur-0.02));

	trig1 = PulseDivider.ar(trig, 2, 0);
	trig2 = PulseDivider.ar(trig, 2, 1);

	env1 = EnvGen.ar(Env.sine(loopDur), trig1);
	env2 = EnvGen.ar(Env.sine(loopDur), trig2);

	phaseAdjust = SinOsc.kr(Rand(1/(3*(3+loopDur)), 2/(3*(3+loopDur))), 1.5pi, (loopDur+3)/2, (loopDur+3)/2)*BufSampleRate.kr(bufnum);

	sig1 = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), trig1, (phaseStart+phaseAdjust), loop: 1)*env1;
	sig2 = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), trig2, phaseStart+phaseAdjust, loop: 1)*env2;

	env = EnvGen.kr(Env.asr(4,1,4,1,'welch'), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	vol = In.kr(volBus);

	Out.ar(outBus, Pan2.ar((sig1+sig2), LFNoise2.kr(0.2))*env*pauseEnv*vol);
}).add;


SynthDef("lowSine", {arg freq0, freq1, dur, outBus, vol=0, gate = 1, pauseGate = 1, localGate = 0;
	var sine, env, pauseEnv, localEnv, freq;

	pauseEnv = EnvGen.kr(Env.asr(0.05,1,0.05), pauseGate, doneAction:1);
	env = EnvGen.kr(Env([0,1,1,0],[0.5, dur-1, 0.5]), gate, doneAction:2);

	freq = XLine.kr(freq0, freq1, dur);

	sine = SinOsc.ar(freq, 0, 0.2);

	Out.ar(outBus, Pan2.ar(sine*AmpComp.kr(freq)*env*pauseEnv, Rand(-1, 1)));
}).add;


SynthDef("partALucerne_mod", {arg inBus0, inBus1, inBus2, inBus3, fftBuf0, fftBuf1, fftBuf2, fftBuf3, thresh;
	var amp, fft0, fft1, fft2, fft3, in0, in1, in2, in3, onsets0, onsets1, onsets2, onsets3;

	in0 = In.ar(inBus0);
	in1 = In.ar(inBus1);
	in2 = In.ar(inBus2);
	in3 = In.ar(inBus3);

	fft0 = FFT(fftBuf0, in0);
	fft1 = FFT(fftBuf1, in1);
	fft2 = FFT(fftBuf2, in2);
	fft3 = FFT(fftBuf3, in3);

	onsets0 = Onsets.kr(fft0, thresh);
	onsets1 = Onsets.kr(fft1, thresh);
	onsets2 = Onsets.kr(fft2, thresh);
	onsets3 = Onsets.kr(fft3, thresh);

	SendTrig.kr(onsets0, 0, 1);
	SendTrig.kr(onsets1, 1, 1);
	SendTrig.kr(onsets2, 2, 1);
	SendTrig.kr(onsets3, 3, 1);

	SendPeakRMS.kr(in0+in1+in2+in3, 20, 1, "/sigAmplitude");
}).add;


SynthDef("mantaBuffersRecord_mod", {arg inBus, bufnum, gate=1, pauseGate=1, recordOn = 1;
	var in, phasor, env, smallEnv, pauseEnv;

	phasor = Phasor.ar(0, BufRateScale.kr(bufnum)*recordOn, 0, BufFrames.kr(bufnum));

	in = In.ar(inBus);

	//smallEnv = EnvGen.kr(Env.asr(0.02,1,0.02), recordOn);
	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	BufWr.ar(in, bufnum, phasor, loop:1);
}).add;

SynthDef("mantaBuffersPlay_mod", {arg bufnum, outBus, trigRates = #[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], durations = #[ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ], centerPos = #[ 0.1, 0.3, 0.5, 0.7, 0.9, 1.1, 1.3, 1.5, 1.7, 1.9, 2.1, 2.3, 2.5, 2.7, 2.9, 3.1, 3.3, 3.5, 3.7, 3.9, 4.1, 4.3, 4.5, 4.7, 4.9, 5.1, 5.3, 5.5, 5.7, 5.9, 6.1, 6.3, 6.5, 6.7, 6.9, 7.1, 7.3, 7.5, 7.7, 7.9, 8.1, 8.3, 8.5, 8.7, 8.9, 9.1, 9.3, 9.5 ], vol=0, pauseGate = 1, gate = 1;

	var env, pauseEnv, impulse, out, pan, fade, envs, tGrains;

	env = EnvGen.kr(Env.asr(0.01, 1, 0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.05,1,0.01), pauseGate, doneAction:1);

	impulse = Impulse.kr(trigRates);

	pan = TRand.kr(0.7, 1.0, impulse)*TChoose.kr(impulse, [-1,1]);

	//centerPos = centerPos + (LFNoise2.kr(LFNoise0.kr(0.5, 0.05, 0.11), 0.07) ! 48);

	tGrains = TGrains2.ar(2, impulse, bufnum, 1, centerPos, durations, pan, 2, 0.05, 0.05);

	out = Mix(tGrains);

	Out.ar(outBus, out*env*pauseEnv*vol);

}).add;


SynthDef("mikrophonie_mod", {|inBus, outBus, vol=0, hiFreq=10000, lowFreq=30, pan=0, gate = 1, pauseGate = 1|
	var in, out, largeEnv, env, pauseEnv, centerFreq, panPlus, panTot;

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);

	in = In.ar(inBus);

	out = RLPF.ar(in, Lag.kr(max(lowFreq, hiFreq), 0.05), 0.8);
	out = HPF.ar(out, Lag.kr(min(lowFreq, hiFreq), 0.05));

	//centerFreq = ((max(lowFreq, hiFreq)-min(lowFreq, hiFreq))/2)+min(lowFreq, hiFreq);

	//out = Resonz.ar(in, centerFreq, abs(hiFreq-lowFreq)/centerFreq);
	//out = BPF.ar(in, centerFreq, abs(hiFreq-lowFreq)/centerFreq);

	out = env*pauseEnv*vol*out;

	panPlus = LFNoise2.kr(0.3).range(-0.3, 0.3);

	panTot = (pan+panPlus).clip(-1, 1);

	Out.ar(outBus, Pan2.ar(out, panTot));
}).add;


SynthDef("mincekSine_mod", {arg freq, lagTime, outBus, vol=0, lilVol = 1, gate = 1, pauseGate = 1;
	var sine, env, pauseEnv;

	pauseEnv = EnvGen.kr(Env.asr(0,1,6), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	sine = SinOsc.ar(VarLag.kr(freq, lagTime), 0, Lag.kr(vol, 0.01)*Lag.kr(lilVol, 0.1)*0.1);

	Out.ar(outBus, Pan2.ar(sine*AmpComp.kr(freq)*env*pauseEnv, Rand(-1, 1)));
}).add;


SynthDef("mouseDelayz_mod",{ arg mouseBus, delayedMiceBus, delayTime0=0.1, delayTime1=2, gate = 1;
	var in, env, delayTime;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);
	in = LagIn.kr(mouseBus, 2, 0.1);

	Out.kr(delayedMiceBus, DelayC.kr(in, 2.1, SinOsc.kr(Rand(0.1,0.2)).range(delayTime0, delayTime1)));
	Out.kr(delayedMiceBus+2, DelayC.kr(in, 2.1, SinOsc.kr(Rand(0.1,0.2)).range(delayTime0, delayTime1)));
	Out.kr(delayedMiceBus+4, DelayC.kr(in, 2.1, SinOsc.kr(Rand(0.1,0.2)).range(delayTime0, delayTime1)));
	Out.kr(delayedMiceBus+6, DelayC.kr(in, 2.1, SinOsc.kr(Rand(0.1,0.2)).range(delayTime0, delayTime1)));
	Out.kr(delayedMiceBus+8, DelayC.kr(in, 2.1, SinOsc.kr(Rand(0.1,0.2)).range(delayTime0, delayTime1)));
	Out.kr(delayedMiceBus+10, DelayC.kr(in, 2.1, SinOsc.kr(Rand(0.1,0.2)).range(delayTime0, delayTime1)));
	Out.kr(delayedMiceBus+12, DelayC.kr(in, 2.1, SinOsc.kr(Rand(0.1,0.2)).range(delayTime0, delayTime1)));
	Out.kr(delayedMiceBus+14, DelayC.kr(in, 2.1, SinOsc.kr(Rand(0.1,0.2)).range(delayTime0, delayTime1)));
}).add;

SynthDef("mouseDistort_mod",{arg inBus, outBus, attack, sustain, decay, mouseBus, volBus;
	var in, env, time, bigVol, length, vol, mouseIn;
	var out;

	length = attack+sustain+decay;

	mouseIn = In.kr(mouseBus, 2).abs;

	vol = In.kr(volBus);

	in = In.ar(inBus, 1);

	in = CombC.ar(in, 0.2, mouseIn[1], 0.5)+in;

	env = EnvGen.kr(Env([0,1,1,0],[attack, sustain, decay]), doneAction: 2);

	in = in.fold2(mouseIn[0])*env;
	out = Pan2.ar(in,
		Line.kr(Rand(-1.0,1.0), Rand(-1.0,1.0), length), vol
	);

	out = LeakDC.ar(out, 0.995);

	Out.ar(outBus, out);
}).add;


SynthDef("mute_mod", {arg inBus, outBus, mute=1, ramp=0.01, gate=1, pauseGate=1;
	var env, out, pauseEnv, muteEnv;

	muteEnv = EnvGen.kr(Env.asr(ramp, 1, ramp), mute, doneAction:0);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, In.ar(inBus, 8)*env*muteEnv*pauseEnv);
}).add;


SynthDef("largeEnvPulse_mod",{arg outBusNum, attack, decay, gate;
	var env, out;

	env = Env.asr(attack,1,decay);
	Out.kr(outBusNum, EnvGen.kr(env, gate, doneAction: 2));
}).add;

SynthDef("pulsatingDelays2_mod", {arg inBusNum, outBus, largeEnvBusNum, pulseStart, pulseEnd, delayTime, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, bigEnv, volume, xStart, xEnd;

	volume = In.kr(vol);

	in = In.ar(inBusNum, 1);
	largeEnv = In.kr(largeEnvBusNum, 1);

	env = Env.new([0.001,1,1,0.001], [1,length,1], 'linear');
	bigEnv = Env.new([0.001,1,1,0.001], [0.01,length+delayTime+1.98,0.01], 'linear');

	in2 = EnvGen.ar(env, doneAction: 0)*EnvGen.ar(bigEnv, doneAction: 2)*in;

	xStart = Rand(-1,1);
	xEnd = Rand(-1,1);

	delayedSignal = DelayL.ar(in2, 5, delayTime);
	out = Pan2.ar(delayedSignal, Line.kr(xStart, xEnd, length+2+delayTime));
	out = out*SinOsc.kr(Line.kr(pulseStart, pulseEnd, length+2+delayTime), 1, 0.5);
	Out.ar(outBus, out*volume);
}).add;

SynthDef("pulsatingDelays4_mod", {arg inBusNum, outBus, largeEnvBusNum, pulseStart, pulseEnd, delayTime, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, bigEnv, volume, xStart, xEnd;

	volume = In.kr(vol);

	in = In.ar(inBusNum, 1);
	largeEnv = In.kr(largeEnvBusNum, 1);

	env = Env.new([0.001,1,1,0.001], [1,length,1], 'linear');
	bigEnv = Env.new([0.001,1,1,0.001], [0.01,length+delayTime+1.98,0.01], 'linear');

	in2 = EnvGen.ar(env, doneAction: 0)*EnvGen.ar(bigEnv, doneAction: 2)*in;

	xStart = Rand(-0.75,0.75);
	xEnd = Rand(-0.75,0.75);

	delayedSignal = DelayL.ar(in2, 5, delayTime);
	out = PanAz.ar(4, delayedSignal, Line.kr(xStart, xEnd, length+2+delayTime));
	out = out*SinOsc.kr(Line.kr(pulseStart, pulseEnd, length+2+delayTime), 1, 0.5);
	Out.ar(outBus, [out[0],out[1],out[3],out[2]]*volume);
}).add;

SynthDef("pulsatingDelays8_mod", {arg inBusNum, outBus, largeEnvBusNum, pulseStart, pulseEnd, delayTime, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, bigEnv, volume, xStart, xEnd;

	volume = In.kr(vol);

	in = In.ar(inBusNum, 1);
	largeEnv = In.kr(largeEnvBusNum, 1);

	env = Env.new([0.001,1,1,0.001], [1,length,1], 'linear');
	bigEnv = Env.new([0.001,1,1,0.001], [0.01,length+delayTime+1.98,0.01], 'linear');

	in2 = EnvGen.ar(env, doneAction: 0)*EnvGen.ar(bigEnv, doneAction: 2)*in;

	xStart = Rand(-0.6,0.6);
	xEnd = Rand(-0.6,0.6);

	delayedSignal = DelayL.ar(in2, 5, delayTime);
	out = PanAz.ar(8, delayedSignal, Line.kr(xStart, xEnd, length+2+delayTime));
	out = out*SinOsc.kr(Line.kr(pulseStart, pulseEnd, length+2+delayTime), 1, 0.5);
	Out.ar(outBus, [out[0],out[1],out[7],out[2],out[6],out[3],out[5],out[4]]*volume);
}).add;


SynthDef("compander_mod", {arg threshBus, slopeBelowBus, slopeAboveBus, attackBus, releaseBus, inBus, outBus, gate = 1, pauseGate = 1;
	var in, out, env, pauseEnv, thresh, slopeBelow, slopeAbove, attack, release;

	thresh = In.kr(threshBus);
	slopeBelow = In.kr(slopeBelowBus);
	slopeAbove = In.kr(slopeAboveBus);
	attack = In.kr(attackBus);
	release = In.kr(releaseBus);

	in = In.ar(inBus, 2);

	out = Compander.ar(in, in,
		thresh: thresh,
		slopeBelow: slopeBelow,
		slopeAbove: slopeAbove,
		clampTime: attack,
		relaxTime: release
	);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, out*env*pauseEnv);
}).add;


SynthDef("noisePulse_mod", {arg outBus, vol, pulseRate = 1, panSpeed = 1, onOff=0, gate=1, pauseGate=1;
	var env, out, pauseEnv;
	var freqs, numSines = 50, onOffEnv;

	freqs = MouseY.kr(Array.rand(10, 270, 330), Array.rand(10, 7000, 9000));

	out = DynKlang.ar(`[
		SinOsc.kr(Array.rand(numSines, 0.7, 1.3), Array.rand(numSines, 0, 2), freqs, freqs+20),
		SinOsc.kr(Array.rand(numSines, 0.2, 1), 0, 0.1),
		[pi,pi,pi]
	])*Trig1.kr(Impulse.kr(MouseX.kr(4,15)), 0.05);
	onOffEnv = EnvGen.kr(Env.asr(0,1,0), onOff, doneAction:0);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, Pan2.ar(out, SinOsc.kr(panSpeed))*env*onOffEnv*pauseEnv*vol);
}).add;


SynthDef(\oscilMidBump_mod, { arg inBus, outBus, lfoSpeed = 0.1, db = 0, vol=0, delayTime=0.01, decayTime=1, pauseGate=1, gate=1;

	var in, env, pauseEnv, lfo0, lfo1, mid0, mid1;

	in = In.ar(inBus, 2);

	lfo0 = LFTri.kr(lfoSpeed, 3, 1500, 1600);
	lfo1 = Lag.kr(LFPulse.kr(lfoSpeed, 0, 0.3), 1);

	mid0 = MidEQ.ar(in, lfo0, 0.3, (lfo1*db));
	mid1 = MidEQ.ar(mid0, 3100-lfo0, 0.3, (1-lfo1)*db);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);

	Out.ar(outBus, mid1*vol*env*pauseEnv);
}).add;


SynthDef(\pedalRouter_mod, {| inBus, outBus, pedalOutBus, pedalInBus, outVol, inVol, gate = 1, muteGate = 1, pauseGate = 1 |
	var in, out, env, pauseEnv, muteEnv;

	muteEnv = EnvGen.kr(Env.asr(0,1,0), muteGate, doneAction:0);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	in = In.ar(inBus)*inVol;
	Out.ar(pedalOutBus, in);

	out = SoundIn.ar(pedalInBus)*outVol*muteEnv;

	Out.ar(outBus, [out,out]*env*pauseEnv);
}).add;


SynthDef("peSequencer_mod", {arg outBus, volume, fund, offOn, speed, gate = 1, pauseGate = 1;
	var a, freq, trig, trig2, smallEnv, out0, out1, seq, verb, out, smallEnv2, noise, env, pauseEnv;
	seq =
	Dswitch1([
		Dswitch1([
			Dseq([9, 13, 11, 7, 9, 13, 5, 7, 11, 17/2, 15/2, 13/2]/2, inf),
			Dseq([9, 13, 11, 7, 9, 13, 5, 7, 11, 17/2, 15/2, 13/2]*2, inf),
			Dseq([9, 13, 11, 7, 9, 13, 5, 7, 11, 17/2, 15/2, 13/2]*4, inf)
		], Dwhite(0, 2, inf)),
		Dseq([5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25]*2, inf)
	], Dwhite(0, 1, inf));

	trig = Impulse.kr(LFNoise2.kr(1).range(110/60, 110/60*8))*offOn;
	trig2 = Impulse.kr(110/60*16)*offOn;

	trig = Select.kr(speed, [trig, trig2]);

	trig = Trig1.kr(trig, TRand.kr(0.001, Select.kr(speed, [0.05, 0.001]), trig));

	freq = Demand.kr(trig, 0, seq) ;

	smallEnv = EnvGen.ar(Env.perc(0.01, 0.1), trig);

	smallEnv2 = EnvGen.ar(Env.perc(0.001, 0.01), trig);

	noise = LPF.ar(BrownNoise.ar(0.2)*smallEnv2, TRand.kr(200, 1000, trig));

	out0 = SelectX.ar(LFNoise2.kr(2).range(0, 2).sqrt, [
		SinOsc.ar((freq* fund)+SinOsc.ar((freq-TIRand.kr(1, 4))* fund, 0, SinOsc.kr(0.3).range(1,200))) * 0.1,
		Saw.ar((freq* fund)+SinOsc.ar((freq-TIRand.kr(1, 4))* fund, 0, SinOsc.kr(0.3).range(1,200))) * 0.3]) ;

	out1 = SinOsc.ar((freq* fund*2)+SinOsc.ar((freq-TIRand.kr(1, 4))* fund*2, 0, SinOsc.kr(0.3).range(1,200))) * 0.3 ;

	verb = GVerb.ar(out0+out1, 40, 2, 0.1, 0.1, 15, 0, 0.1, 0.5, 40, 0.1);

	out = Pan2.ar(out0+noise, SinOsc.kr(LFNoise2.kr(0.5).range(0.2, 0.8)))+Pan2.ar(out1, SinOsc.kr(LFNoise2.kr(0.5).range(0.2, 0.8)));

	env = EnvGen.kr(Env.asr(0.1,1,0.1), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.1,1,0.1), pauseGate, doneAction:1);

	Out.ar(outBus, (verb+out)* smallEnv*pauseEnv*env*volume);

}).add;


SynthDef("peSynthTone_mod", {arg outBus, volBus, freq;
	var start, end, attack, sustain, release, env, out, volume;

	volume = In.kr(volBus);

	start = Rand(5, 20);
	end = Rand(40, 200);

	attack = Rand(4, 7);
	sustain = Rand(2, 4);
	release = Rand(3, 7);

	env = EnvGen.kr(Env.new([0,1,1,0], [attack, sustain, release]), 1, doneAction:2);

	out = SinOsc.ar(freq, SinOsc.ar(XLine.kr(start, end, attack+sustain+release), 0, 2pi), 0.3)*env;

	out = Pan2.ar(out, Line.kr(Rand(-1, 1), Rand(-1, 1), attack+sustain+release));

	Out.ar(outBus, out* env*volume);

}).add;


SynthDef("pitchShift_mod", {arg inBus, outBus, shiftBus, gate = 1, pauseGate = 1;
	var in, env, out, pauseEnv, shift;

	shift = In.kr(shiftBus);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	in = In.ar(inBus, 1);

	out = [PitchShift.ar(in, 0.07, shift, 0, 0.001), PitchShift.ar(in, 0.07, shift, 0, 0.001)];

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, out*pauseEnv);
}).add;


SynthDef("largeEnvPBP_mod",{arg outBusNum, attack, decay, gate=1, pauseGate=1;
	var env, out, pauseEnv;

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:0);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);
	Out.kr(outBusNum, env*pauseEnv);
}).add;

SynthDef("amplitudePBP_mod", {|inBus, ampBus|
	var amp;

	amp = Amplitude.kr(In.ar(inBus));

	Out.kr(ampBus, amp);
}).add;

SynthDef("pulsingBandPass2_mod", {|inBus, outBus, ampBus, volBus, largeEnvBus, freq, rq, delayTime, gate = 1, pauseGate = 1|
	var in, out, amp, decayTime, vol, largeEnv, env, pauseEnv;

	vol = In.kr(volBus);

	largeEnv = In.kr(largeEnvBus);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);

	amp = In.kr(ampBus);

	decayTime = Latch.kr(amp, 1)*10+5;

	in = In.ar(inBus)*EnvGen.kr(Env.sine(delayTime), 1);

	out = Pan2.ar(CombC.ar(BPF.ar(in, freq, rq), delayTime, delayTime, decayTime), Rand(-1.0, 1.0));

	//Out.ar(outBus, in);
	Out.ar(outBus, env*pauseEnv*vol*largeEnv*out*EnvGen.kr(Env.new([0,1,1,0],[0.01, decayTime, 1]), 1, doneAction:2));
}).add;

SynthDef("pulsingBandPass4_mod", {|inBus, outBus, ampBus, volBus, largeEnvBus, freq, rq, delayTime, gate = 1, pauseGate = 1|
	var in, out, amp, decayTime, vol, largeEnv, env, pauseEnv;

	vol = In.kr(volBus);

	largeEnv = In.kr(largeEnvBus);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);

	amp = In.kr(ampBus);

	decayTime = Latch.kr(amp, 1)*10+5;

	in = In.ar(inBus)*EnvGen.kr(Env.sine(delayTime), 1);

	out = PanAz.ar(4, CombC.ar(BPF.ar(in, freq, rq), delayTime, delayTime, decayTime), Rand(-0.75, 0.75));

	//Out.ar(outBus, in);
	Out.ar(outBus, env*pauseEnv*vol*largeEnv*[out[0],out[1],out[3],out[2]]*EnvGen.kr(Env.new([0,1,1,0],[0.01, decayTime, 1]), 1, doneAction:2));
}).add;

SynthDef("pulsingBandPass8_mod", {|inBus, outBus, ampBus, volBus, largeEnvBus, freq, rq, delayTime, gate = 1, pauseGate = 1|
	var in, out, amp, decayTime, vol, largeEnv, env, pauseEnv;

	vol = In.kr(volBus);

	largeEnv = In.kr(largeEnvBus);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);

	amp = In.kr(ampBus);

	decayTime = Latch.kr(amp, 1)*10+5;

	in = In.ar(inBus)*EnvGen.kr(Env.sine(delayTime), 1);

	out = PanAz.ar(8, CombC.ar(BPF.ar(in, freq, rq), delayTime, delayTime, decayTime), Rand(-0.6, 0.6));

	//Out.ar(outBus, in);
	Out.ar(outBus, env*pauseEnv*vol*largeEnv*[out[0],out[1],out[7],out[2],out[6],out[3],out[5],out[4]]*EnvGen.kr(Env.new([0,1,1,0],[0.01, decayTime, 1]), 1, doneAction:2));
}).add;


SynthDef("record2_mod", { arg bufnum, inBus;
	var in;

	in = In.ar(inBus, 2);
	DiskOut.ar(bufnum, in*0.5)
}).add;
SynthDef("record4_mod", { arg bufnum, inBus;
	var in;

	in = In.ar(inBus, 4);
	DiskOut.ar(bufnum, in*0.5)
}).add;
SynthDef("record8_mod", { arg bufnum, inBus;
	var in;

	in = In.ar(inBus, 8);
	DiskOut.ar(bufnum, in*0.5)
}).add;


SynthDef("resonNoise2_mod", {arg inBus, outBus, transferBus, noiseVol=0, inOutVol=0, centerFreq, lfoFreq, rq = 0.1, onOff=1, gate=1, pauseGate=1;
	var env, in, noiseOut, inOut, pauseEnv, freq;

	in = In.ar(inBus, 1);

	freq = max(centerFreq+SinOsc.ar(lfoFreq, 0, centerFreq*0.8), 40);

	inOut = Resonz.ar(in, freq, rq);

	noiseOut = Resonz.ar(WhiteNoise.ar(1), freq, rq);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	noiseOut = Pan2.ar(noiseOut, LFNoise2.kr(lfoFreq+5/20));

	Out.ar(transferBus, inOut*LagUD.kr(onOff, 0.1, 1)*env*pauseEnv*inOutVol);

	Out.ar(outBus, noiseOut*LagUD.kr(onOff, 0.1, 1)*env*pauseEnv*noiseVol);
}).add;

SynthDef("resonNoise4_mod", {arg inBus, outBus, transferBus, noiseVol=0, inOutVol=0, centerFreq, lfoFreq, rq = 0.1, onOff=1, gate=1, pauseGate=1;
	var env, in, noiseOut, inOut, pauseEnv, freq;

	in = In.ar(inBus, 1);

	freq = max(centerFreq+SinOsc.ar(lfoFreq, 0, centerFreq*0.8), 40);

	inOut = Resonz.ar(in, freq, rq);

	noiseOut = Resonz.ar(WhiteNoise.ar(1), freq, rq);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	noiseOut = PanAz.ar(4, noiseOut, LFNoise2.kr(lfoFreq+5/20));

	Out.ar(transferBus, inOut*LagUD.kr(onOff, 0.1, 1)*env*pauseEnv*inOutVol);

	Out.ar(outBus, noiseOut*LagUD.kr(onOff, 0.1, 1)*env*pauseEnv*noiseVol);
}).add;

SynthDef("resonNoise8_mod", {arg inBus, outBus, transferBus, noiseVol=0, inOutVol=0, centerFreq, lfoFreq, rq = 0.1, onOff=1, gate=1, pauseGate=1;
	var env, in, noiseOut, inOut, pauseEnv, freq;

	in = In.ar(inBus, 1);

	freq = max(centerFreq+SinOsc.ar(lfoFreq, 0, centerFreq*0.8), 40);

	inOut = Resonz.ar(in, freq, rq);

	noiseOut = Resonz.ar(WhiteNoise.ar(1), freq, rq);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	noiseOut = PanAz.ar(8, noiseOut, LFNoise2.kr(lfoFreq+5/20));

	Out.ar(transferBus, inOut*LagUD.kr(onOff, 0.1, 1)*env*pauseEnv*inOutVol);

	Out.ar(outBus, noiseOut*LagUD.kr(onOff, 0.1, 1)*env*pauseEnv*noiseVol);
}).add;

SynthDef("resonDelays2_mod", {arg inBusNum, outBus0, outBus1, delayTime, length;
	var in, in2, env, delayedSignal, buffer, out, bigEnv, volume, xStart, xEnd;

	in = In.ar(inBusNum, 1);

	env = Env.new([0.001,1,1,0.001], [1,length,1], 'linear');
	bigEnv = Env.new([0.001,1,1,0.001], [0.01,length+delayTime+1.98,0.01], 'linear');

	in2 = EnvGen.ar(env, doneAction: 0)*EnvGen.ar(bigEnv, doneAction: 2)*in;

	xStart = Rand(-1,1);
	xEnd = Rand(-1,1);

	delayedSignal = DelayL.ar(in2, 5, delayTime);
	out = Pan2.ar(delayedSignal, Line.kr(xStart, xEnd, length+2+delayTime));
	Out.ar(outBus0, out[0]);
	Out.ar(outBus1, out[1]);
}).add;


SynthDef("reverbDrone_mod", { arg out=0, inBus, volBus, delayBus, distBus, gate = 1, pauseGate = 1;
	var in, in2, outSig, trig, local, env, pauseEnv, vol, dist, delTime;

	vol = In.kr(volBus);
	delTime = In.kr(delayBus);
	dist = In.kr(distBus);

	env = EnvGen.kr(Env.asr(0,1,0.5), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in = In.ar(inBus,1)*2;

	in2 = CombC.ar(PitchShift.ar(in, 0.2, 0.25, 0, 0.1), 0.2, 0.2, 5);

	outSig = GVerb.ar(Mix.new(in), 100, 10, 0.5, 1, 0.5, 0, 0.1, 0.1);

	outSig = LPF.ar(outSig, 400);

	outSig = outSig+PitchShift.ar(outSig, 0.2, 0.5, 0, 0.1)+in2;
	outSig = outSig+ Resonz.ar(outSig, 100, 1);

	local = LocalIn.ar(2);
	local = OnePole.ar(local, 0.4);
	local = OnePole.ar(local, -0.08);

	local = Rotate2.ar(local[0], local[1], 0.2);

	local = DelayN.ar(local, 0.5, delTime);

	local = LeakDC.ar(local);
	local = ((local + outSig) * dist).softclip;

	LocalOut.ar(local);

	Out.ar(out, (local*0.1)*vol*env*pauseEnv);
}).add;


SynthDef("gVerb_mod", { arg inBus, outBus, roomSize, revTime, damping, inputBW, spread, dryLevel, earlyLevel, tailLevel, vol, pauseGate=1, gate=1;
	var in, pauseEnv, env, verb;

	in = In.ar(inBus);

	//in = Resonz.ar(Array.fill(4, {Dust.ar(2)}), 1760 * [1, 2, 4, 8], 0.01).sum * 10;

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:0);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);

	verb = GVerb.ar(
		in,
		roomSize,
		revTime,
		damping,
		inputBW,
		spread,
		dryLevel,
		earlyLevel,
		tailLevel,
		roomSize+1);

	Out.ar(outBus, verb*pauseEnv*env*vol);
}).add;


SynthDef("ringModStereo", {arg inBus0, inBus1, outBus, vol, lpFreq=2000, gate = 1, pauseGate = 1;
	var in0, in1, env, out, pauseEnv;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in0 = In.ar(inBus0, 8);
	in1 = In.ar(inBus1, 8);

	out = in0*in1*vol;

	out = LPF.ar(out, lpFreq)*20*env*pauseEnv;
	Out.ar(outBus, out, 0);
}).add;


SynthDef("sampleBankPlayerMono_mod", {arg bufnum, outBus, volBus, gate = 1, pauseGate = 1;
	var in0, in1, env, env2, out, vol, pauseEnv;

	env = EnvGen.kr(Env.new([0,1,1,0],[0.01, BufDur.kr(bufnum)-0.02, 0.01]), gate, doneAction:2);
	env2 = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	vol = In.kr(volBus);

	out = PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum), loop: 0);
	out = Pan2.ar(out, Rand(-1.0,1.0));
	Out.ar(outBus, out*env*env2*vol*pauseGate);
}).add;

SynthDef("sampleBankPlayerStereo_mod", {arg bufnum, outBus, volBus, gate = 1, pauseGate = 1;
	var in0, in1, env, env2, out, vol, pauseEnv;

	env = EnvGen.kr(Env.new([0,1,1,0],[0.01, BufDur.kr(bufnum)-0.02, 0.01]), gate, doneAction:2);
	env2 = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	vol = In.kr(volBus);

	out = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum), loop: 0);

	Out.ar(outBus, out*env*env2*vol*pauseGate);
}).add;


SynthDef(\sand_mod, { arg inBus, outBus, volBus, smallGate=1, pauseGate=1, gate=1;
	var inA1, inA2, chainA1, chainA2, inB, inC, inB1, inB2, inB3, chainB, chain1, chain2, chain3, chain4, amp, out, out1, out2, thresh;
	var smallEnv, env, pauseEnv, volume;

	volume = In.kr(volBus);

	smallEnv = EnvGen.kr(Env.asr(0.02,1,0.02), smallGate);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	inB = In.ar(inBus)*smallEnv;

	amp = LagUD.kr(Amplitude.kr(inB)*smallEnv*pauseEnv, 0.01, LFNoise2.kr(0.5, 1, 1.75));

	#inA1, inA2 = Dust.ar([3000,3000]*amp, 0.5);

	inC = Dust.ar([300,300]*amp, 0.5)*amp;

	inC = BPF.ar(inC, LFNoise2.kr(0.3, 1000, 8000), 0.2).dup.dup;

	inB = AllpassC.ar(inB, 0.5, LFNoise2.kr(1, 0.05, 0.1), 1.0)+AllpassC.ar(inB, 0.5, LFNoise2.kr(1, 0.05, 0.1), 1.0);

	chainA1 = FFT(LocalBuf(2048), inA1);
	chainA2 = FFT(LocalBuf(2048), inA2);
	chainB = FFT(LocalBuf(2048), inB);

	chain1 = PV_MagMul(chainA1, chainB);
	chain2 = PV_MagMul(chainA2, chainB);

	chain3 = PV_Copy(chain1, LocalBuf(2048));
	chain4 = PV_Copy(chain2, LocalBuf(2048));

	chain1 = PV_BrickWall(chain1, 0.05);
	chain2 = PV_BrickWall(chain2, 0.05);

	chain3 = PV_MagSmear(PV_BrickWall(chain3, -0.05), 10);
	chain4 = PV_MagSmear(PV_BrickWall(chain4, -0.05), 10);

	out1 = 0.5 * [IFFT(chain1), IFFT(chain2)];

	out2 = 0.5 * [IFFT(chain3), IFFT(chain4)];

	out = out1+DelayC.ar(out1, 0.05, LFNoise2.kr(1, 0.005, 0.025))+DelayC.ar(out2, 0.05, LFNoise2.kr(1, 0.005, 0.025));

	thresh = 0.1;

	out = LPF.ar((out+(inC*0.5)), 11000);


	env = EnvGen.kr(Env.asr(0.02,1,0.02), gate, doneAction: 2);
	Out.ar(outBus, out*volume*env);
}).add;


SynthDef("scaleShifterB2_mod", {arg inBusNum, outBus, inVolBus, outVolBus, largeEnvBusNum, length, gate0=0, ratio0=1, smallLength;
	var in, in2, env, env0, sig0, out, largeEnv, bigEnv, inVol, outVol, xStart, xEnd, delTime;

	inVol = In.kr(inVolBus);
	outVol = In.kr(outVolBus);

	env0 = EnvGen.kr(Env.sine(smallLength*5,1), 1);

	largeEnv = In.kr(largeEnvBusNum);
	in = (In.ar(inBusNum, 1)*env0*inVol)+(LocalIn.ar(1));

	env = EnvGen.kr(Env.new([0,1,1,0], [0.1,length,3], 'linear'), doneAction:2);

	xStart = Rand(-1,1);
	xEnd = Rand(-1,1);

	sig0 = PitchShift.ar(in, 0.1, ratio0, 0, 0.02);

	sig0 = LPF.ar(HPF.ar(sig0, 100), 15000);

	delTime = Rand(smallLength/3,smallLength/2);

	LocalOut.ar(DelayC.ar(sig0, delTime));

	out = Pan2.ar(sig0,
		Line.kr(xStart, xEnd, length))*largeEnv;
	Out.ar(outBus, out*outVol);
}).add;


SynthDef("scaleShifter2_mod", {arg inBusNum, outBus, volBus, largeEnvBusNum, length, gate0=0, gate1=0, gate2=0, gate3=0, ratio0=1, ratio1=1, ratio2=1, ratio3=1, smallLength;
	var in, in2, env, env0, env1, env2, env3, sig, sig0, sig1, sig2, sig3, buffer, out, largeEnv, bigEnv, volume, xStart, xEnd;

	volume = In.kr(volBus);

	largeEnv = In.kr(largeEnvBusNum);
	in = In.ar(inBusNum, 1);

	env = Env.new([0.001,1,1,0.001], [1,length,smallLength], 'linear');

	in2 = EnvGen.kr(env, doneAction: 2)*in*largeEnv;

	xStart = Rand(-1,1);
	xEnd = Rand(-1,1);

	env0 = EnvGen.kr(Env([0,1,1,0], [smallLength/3,smallLength/3,smallLength/3]), gate0);
	env1 = EnvGen.kr(Env([0,1,1,0], [smallLength/3,smallLength/3,smallLength/3]), gate1);
	env2 = EnvGen.kr(Env([0,1,1,0], [smallLength/3,smallLength/3,smallLength/3]), gate2);
	env3 = EnvGen.kr(Env([0,1,1,0], [smallLength/3,smallLength/3,smallLength/3]), gate3);

	sig0 = PitchShift.ar(in2, 0.1, ratio0, 0, 0.1)*env0;
	sig1 = PitchShift.ar(in2, 0.1, ratio1, 0, 0.1)*env1;
	sig2 = PitchShift.ar(in2, 0.1, ratio2, 0, 0.1)*env2;
	sig3 = PitchShift.ar(in2, 0.1, ratio3, 0, 0.1)*env3;

	out = Pan2.ar(sig0+sig1+sig2+sig3,
		Line.kr(xStart, xEnd, length));
	Out.ar(outBus, out*volume);
}).add;


SynthDef("signalSwither_mod", {arg inBus0, inBus1, outBus, whichSignal = 0, addSecondSignal=0, pulseRate0=0, onBypass=0, gate = 1, pauseGate = 1;
	var in0, in1, env, out, impulse, signal, pauseEnv;

	impulse = Impulse.kr(pulseRate0);

	signal = Lag.kr(Select.kr(whichSignal, [0, 1, Stepper.kr(impulse, 0, 0, 1, 1, 0)]), 0.001);

	in0 = In.ar(inBus0, 8);
	in1 = In.ar(inBus1, 8);

	out = (in0*(1-signal))+(in1*signal)+(Lag.kr(addSecondSignal, 0.001)*in1);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, out*env*pauseEnv);
}).add;


SynthDef("mixerSolo_mod", {arg inBus, outBus, gate=1, pauseGate=1;
	var env, pauseEnv;

	env = EnvGen.kr(Env.asr(0.01,1,0.01), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0.01,1,0.01), pauseGate, doneAction:1);

	Out.ar(outBus, In.ar(inBus,8)*env*pauseEnv);
}).add;


SynthDef("sinArray_mod", { |outBus, freq, vol, pan, volBus, gate = 1, localGate = 0, pauseGate = 1|
	var sin, inVol, env, pauseEnv, localEnv;

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	localEnv = EnvGen.kr(Env.asr(0,1,0), localGate, doneAction:1);

	inVol = In.kr(volBus);

	sin = SinOsc.ar(freq, 0, vol)*inVol;

	Out.ar(outBus, Pan2.ar(sin, pan)*env*pauseEnv*localEnv);

}).add;


SynthDef("spaceJunk_mod", {arg outBus, freq=10, vol=1, pan=0, t_trig;
	var dust, noise, sine, smallEnv, out0, out, verb;

	dust = t_trig;

	noise = WhiteNoise.ar(1);

	noise = BPF.ar(noise, TRand.kr(100, 10000, dust), TRand.kr(0.01, 0.1, dust));

	sine = SinOsc.ar(TRand.kr(1000, 2000, dust));

	smallEnv = Decay.kr(dust, LFNoise2.kr(4).range(0.01, 0.05));

	out0 = noise*sine*smallEnv;
	/*out = Pan2.ar(out0, TRand.kr(-1.0, 1.0, dust));*/

	out = Pan4.ar(out0, TRand.kr(-1.0, 1.0, dust), TRand.kr(-1.0, 1.0, dust));

	verb = GVerb.ar(out0*(TRand.kr(0.1, 0.7, dust)**2)*0.25, 80, 3, 0.41, 0.19, 0, -9.dbamp, -11.dbamp);

	out = ((out+([verb, verb].flatten))*16).softclip;

	Out.ar(outBus, Compander.ar(out, out, 0.8, 1, 0.5, 0.01, 0.01));
}).add;


SynthDef("specDelay_mod", { arg inBus,outBus,inVol=0,outVol=0,bufnum=0, dels0Buf=0, dels1Buf =0, fft0Buf=0, fft1Buf =0,fb0Buf=0, gate=1, pauseGate=1;
	var in, out, chain, chain1, chain2, chain3, env, pauseEnv;

	in = In.ar(inBus)*inVol;

	in = LPF.ar(in, 3000);
	in = HPF.ar(in, 150);

	chain = FFT(fft0Buf, in, 0.25);

	chain = PV_PartialSynthF(chain, 5, 6, 0);

	chain1 = PV_Copy(chain, fft1Buf);

	chain = PV_BinDelay(chain, 5, dels0Buf, fb0Buf, 0.25);
	chain1 = PV_BinDelay(chain1, 5, dels1Buf, fb0Buf, 0.25);

	env = EnvGen.kr(Env.asr(0.1,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	out = [IFFT(chain), IFFT(chain1)];

	Out.ar(outBus, out*env*pauseEnv*outVol );
}).add;


SynthDef("starDust_mod", { arg inBus, transferBus, largeEnvBus, inVol=1, pauseGate=1, gate=1, muteGate=1;
	var in, chain, chain2, chain3, amp, pauseEnv, env, muteEnv;

	in = In.ar(inBus)*inVol;
	amp = Amplitude.kr(in);

	chain = FFT(LocalBuf(2048), in);
	chain = PV_BrickWall(chain, 0.14);
	chain = PV_MagAbove(chain, LFNoise2.kr(1).range(0, 0.2));

	chain2 = PV_Copy(chain, LocalBuf(2048));
	chain3 = PV_Copy(chain, LocalBuf(2048));

	chain = PV_RandComb(chain, 0.9, Impulse.kr((LFNoise2.kr(0.5).range(15, 20)+LagUD.kr((amp*15), 0.1, 1))));
	chain2 = PV_RandComb(chain2, 0.9, Impulse.kr((LFNoise2.kr(0.5).range(15, 20)+LagUD.kr((amp*15), 0.1, 1))));
	chain3 = PV_RandComb(chain3, 0.9, Impulse.kr((LFNoise2.kr(0.5).range(15, 20)+LagUD.kr((amp*15), 0.1, 1))));

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:0);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);
	muteEnv = EnvGen.kr(Env.asr(1,1,0), muteGate, doneAction:0);

	Out.kr(largeEnvBus, pauseEnv);

	Out.ar(transferBus, [IFFT(chain), IFFT(chain2), IFFT(chain3)]*pauseEnv*env*muteEnv*4);
}).add;


SynthDef("starDustDelays_mod", {arg transferBus, outBus, largeEnvBus, xStart, xEnd, delayTime, length, volBus;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, bigEnv, volume, decayTime;

	volume = In.kr(volBus);

	in = In.ar(transferBus, 1);

	env = Env.new([0.001,1,1,0.001], [1,length,1], 'linear');


	in2 = EnvGen.ar(env, doneAction: 0)*in;

	decayTime = Rand(3.0,6.0);

	delayedSignal = AllpassC.ar(DelayL.ar(in2, 5, delayTime), 0.3, Rand(0.1,0.3), decayTime);

	out = Pan2.ar(delayedSignal, Line.kr(xStart, xEnd, length+2+delayTime+decayTime));

	bigEnv = EnvGen.ar(Env.new([0.001,1,1,0.001], [0.01,length+delayTime+1+decayTime,0.01], 'linear'), doneAction: 2);
	largeEnv = In.kr(largeEnvBus, 1);

	Out.ar(outBus, out*volume*largeEnv*bigEnv);

}).add;


SynthDef("largeEnvStraightDels_mod",{arg outBusNum, attack, decay, gate=1, pauseGate=1;
	var env, out, pauseEnv;

	pauseEnv = EnvGen.kr(Env.asr(0.5,1,0), pauseGate, doneAction:0);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction: 2);
	Out.kr(outBusNum, env*pauseEnv);
}).add;

SynthDef("straightDelays2_mod", {arg inBusNum, outBus, largeEnvBusNum, delayTime, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, bigEnv, volume, xStart, xEnd;

	xStart = Rand(-1,1);
	xEnd = Rand(-1,1);

	volume = In.kr(vol);

	largeEnv = In.kr(largeEnvBusNum, 1);
	in = In.ar(inBusNum, 1)*largeEnv;

	env = Env.new([0.001,1,1,0.001], [1,length,1], 'linear');
	bigEnv = Env.new([0.001,1,1,0.001], [0.01,length+delayTime+1.98,0.01], 'linear');

	in2 = EnvGen.ar(env, doneAction: 0)*EnvGen.ar(bigEnv, doneAction: 2)*in;

	delayedSignal = DelayL.ar(in2, 5, delayTime);
	out = Pan2.ar(delayedSignal, Line.kr(xStart, xEnd, length+2+delayTime));
	Out.ar(outBus, out*volume);
}).add;

SynthDef("straightDelays4_mod", {arg inBusNum, outBus, largeEnvBusNum, delayTime, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, bigEnv, volume, xStart, xEnd;

	xStart = Rand(-0.75,0.75);
	xEnd = Rand(-0.75,0.75);

	volume = In.kr(vol);

	largeEnv = In.kr(largeEnvBusNum, 1);
	in = In.ar(inBusNum, 1)*largeEnv;

	env = Env.new([0.001,1,1,0.001], [1,length,1], 'linear');
	bigEnv = Env.new([0.001,1,1,0.001], [0.01,length+delayTime+1.98,0.01], 'linear');

	in2 = EnvGen.ar(env, doneAction: 0)*EnvGen.ar(bigEnv, doneAction: 2)*in;

	delayedSignal = DelayL.ar(in2, 5, delayTime);
	out = PanAz.ar(4, delayedSignal, Line.kr(xStart, xEnd, length+2+delayTime));
	Out.ar(outBus, [out[0],out[1],out[3],out[2]]*volume);
}).add;

SynthDef("straightDelays8_mod", {arg inBusNum, outBus, largeEnvBusNum, delayTime, length, vol;
	var in, in2, env, delayedSignal, buffer, out, largeEnv, bigEnv, volume, xStart, xEnd;

	xStart = Rand(-0.6,0.6);
	xEnd = Rand(-0.6,0.6);

	volume = In.kr(vol);

	largeEnv = In.kr(largeEnvBusNum, 1);
	in = In.ar(inBusNum, 1)*largeEnv;

	env = Env.new([0.001,1,1,0.001], [1,length,1], 'linear');
	bigEnv = Env.new([0.001,1,1,0.001], [0.01,length+delayTime+1.98,0.01], 'linear');

	in2 = EnvGen.ar(env, doneAction: 0)*EnvGen.ar(bigEnv, doneAction: 2)*in;

	delayedSignal = DelayL.ar(in2, 5, delayTime);
	out = PanAz.ar(8, delayedSignal, Line.kr(xStart, xEnd, length+2+delayTime));
	Out.ar(outBus, [out[0],out[1],out[7],out[2],out[6],out[3],out[5],out[4]]*volume);
}).add;


SynthDef("sweepingNoise_mod", {arg outBus, volBus, lowRange, highRange, gate = 1, pauseGate = 1, localGate = 0;
	var noise, localEnv, pauseEnv, env, freq, volume;

	volume = In.kr(volBus);

	freq = LFTri.kr(0.03).exprange(lowRange, highRange);

	noise = MidEQ.ar([BrownNoise.ar(0.1)+WhiteNoise.ar(0.1)+LFClipNoise.ar(freq,0.1), BrownNoise.ar(0.1)+ WhiteNoise.ar(0.1)+LFClipNoise.ar(freq,0.1)], freq, 0.3, 48 ).softclip*0.5;

	localEnv = EnvGen.kr(Env.asr(0,1,0), localGate, doneAction:0);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	Out.ar(outBus, noise*localEnv*pauseEnv*env*volume);

}).add;


SynthDef(\swoopDown2_mod, {| inBus, outBus, volBus, bufnum, time, loopTime, bottom0, bottom1, bottom2, bottom3 |
	var trig, out, out0, out1, ampMod0, ampMod1, verb, env, bigEnv, vol;

	trig = Impulse.kr(1/loopTime);

	RecordBuf.ar(In.ar(inBus,2), bufnum,loop:0);

	out0 = PlayBuf.ar(2, bufnum, XLine.kr(1, bottom0, time)*BufRateScale.kr(bufnum), trig, 5000, 0);
	out1 = PlayBuf.ar(2, bufnum, XLine.kr(1, bottom1, time)*BufRateScale.kr(bufnum), trig, 5000, 0);

	out0 = Latch.ar(out0[0], Impulse.ar(XLine.kr(44100, bottom2, time)));
	out1 = Latch.ar(out1[1], Impulse.ar(XLine.kr(44100, bottom3,time)));

	ampMod0 = 1-Trig1.ar(Dust.kr(XLine.kr(5,25,time)), 0.1);
	ampMod1 = 1-Trig1.ar(Dust.kr(XLine.kr(5,30,time)), 0.1);

	env = EnvGen.kr(Env([1,1,0,0],[2*time/3, time/3, time/2], 'sine'), doneAction:2);

	out0 = out0*ampMod0*env;
	out1 = out1*ampMod1*env;

	verb = GVerb.ar(out1+out0, 80, 4.85, 0.41, 0.19, 0, 0, 0)*EnvGen.kr(Env([0,0,1],[time/6, 5*time/6]));

	bigEnv = EnvGen.kr(Env([0,1,1,0],[time/6, 2**time, time/6],'welch'));

	vol = In.kr(volBus);

	Out.ar(outBus, ([out0,out1]+verb)*bigEnv*vol);
}).add;
SynthDef(\swoopDown4_mod, {| inBus, outBus, volBus, bufnum, time, loopTime, bottom0, bottom1, bottom2, bottom3 |
	var trig, out, out0, out1, out2, out3, out4, ampMod0, ampMod1, verb0, verb1, env, bigEnv, vol;

	trig = Impulse.kr(1/loopTime);

	RecordBuf.ar(In.ar(inBus,2), bufnum,loop:0);

	out0 = PlayBuf.ar(2, bufnum, XLine.kr(1, bottom0, time)*BufRateScale.kr(bufnum), trig, 5000, 0);
	out1 = PlayBuf.ar(2, bufnum, XLine.kr(1, bottom1, time)*BufRateScale.kr(bufnum), trig, 5000, 0);

	out0 = Latch.ar(out0[0], Impulse.ar(XLine.kr(44100, bottom2, time)));
	out1 = Latch.ar(out1[1], Impulse.ar(XLine.kr(44100, bottom3,time)));

	ampMod0 = 1-Trig1.ar(Dust.kr(XLine.kr(5,25,time)), 0.1);
	ampMod1 = 1-Trig1.ar(Dust.kr(XLine.kr(5,30,time)), 0.1);

	env = EnvGen.kr(Env([1,1,0,0],[2*time/3, time/3, time/2], 'sine'), doneAction:2);

	out = [out0*ampMod0*env, out1*ampMod1*env];

	#out1, out3 = Pan2.ar(out[0], Line.kr(-1, 1, time));
	#out2, out4 = Pan2.ar(out[1], Line.kr(-1, 1, time));

	verb0 = GVerb.ar(out1+out2, 80, 4.85, 0.41, 0.19, 0, 0, 0)*EnvGen.kr(Env([0,0,1],[time/6, 5*time/6]));
	verb1 = GVerb.ar(out3+out4, 80, 4.85, 0.41, 0.19, 0, 0, 0)*EnvGen.kr(Env([0,0,1],[time/6, 5*time/6]));

	bigEnv = EnvGen.kr(Env([0,1,1,0],[time/6, 2**time, time/6],'welch'));

	vol = In.kr(volBus);

	Out.ar(outBus, [out1,out2,out3, out4]*bigEnv*vol);
	Out.ar(outBus, verb0);
	Out.ar(outBus+2, verb1);
}).add;
SynthDef(\swoopDown8_mod, {| inBus, outBus, volBus, bufnum, time, loopTime, bottom0, bottom1, bottom2, bottom3 |
	var trig, out, out0, out1, out2, out3, out4, out5, out6, out7, out8, ampMod0, ampMod1, verb0, verb1, verb2, verb3, env, bigEnv, vol;

	trig = Impulse.kr(1/loopTime);

	RecordBuf.ar(In.ar(inBus,2), bufnum,loop:0);

	out0 = PlayBuf.ar(2, bufnum, XLine.kr(1, bottom0, time)*BufRateScale.kr(bufnum), trig, 5000, 0);
	out1 = PlayBuf.ar(2, bufnum, XLine.kr(1, bottom1, time)*BufRateScale.kr(bufnum), trig, 5000, 0);

	out0 = Latch.ar(out0[0], Impulse.ar(XLine.kr(44100, bottom2, time)));
	out1 = Latch.ar(out1[1], Impulse.ar(XLine.kr(44100, bottom3,time)));

	ampMod0 = 1-Trig1.ar(Dust.kr(XLine.kr(5,25,time)), 0.1);
	ampMod1 = 1-Trig1.ar(Dust.kr(XLine.kr(5,30,time)), 0.1);

	env = EnvGen.kr(Env([1,1,0,0],[2*time/3, time/3, time/2], 'sine'), doneAction:2);

	out = [out0*ampMod0*env, out1*ampMod1*env];

	#out1, out3, out5, out7 = PanAz.ar(4, out[0], Line.kr(0, 1.5, time), orientation:0);
	#out2, out4, out6, out8 = PanAz.ar(4, out[1], Line.kr(0, 1.5, time), orientation:0);

	verb0 = GVerb.ar(out1+out2, 80, 4.85, 0.41, 0.19, 0, 0, 0)*EnvGen.kr(Env([0,0,1],[time/6, 5*time/6]));
	verb1 = GVerb.ar(out3+out4, 80, 4.85, 0.41, 0.19, 0, 0, 0)*EnvGen.kr(Env([0,0,1],[time/6, 5*time/6]));
	verb2 = GVerb.ar(out5+out6, 80, 4.85, 0.41, 0.19, 0, 0, 0)*EnvGen.kr(Env([0,0,1],[time/6, 5*time/6]));
	verb3 = GVerb.ar(out7+out8, 80, 4.85, 0.41, 0.19, 0, 0, 0)*EnvGen.kr(Env([0,0,1],[time/6, 5*time/6]));

	bigEnv = EnvGen.kr(Env([0,1,1,0],[time/6, 2**time, time/6],'welch'));

	vol = In.kr(volBus);

	Out.ar(outBus, [out1, out2, out3, out4, out5, out6, out7, out8]*bigEnv*vol);
	Out.ar(outBus, verb0);
	Out.ar(outBus+2, verb1);
	Out.ar(outBus+4, verb2);
	Out.ar(outBus+6, verb3);
}).add;


SynthDef("triggerDelays_mod", {arg input, outBus, volBus, trigDur, decayTime;
	var in, bigEnv, lilEnv, out, trig, shift, vol;

	in = In.ar(input);

	vol = In.kr(volBus);

	trig = Trig.kr(1, trigDur);
	lilEnv = EnvGen.kr(Env.asr(0.05,1,0.05), trig);

	bigEnv = EnvGen.kr(Env.new([0,4,4,0],[0.05, decayTime, 0.3]), doneAction:2);

	shift = (LFNoise2.kr(Rand(0.1, 0.4), 0.5)*Line.kr(0, 1, decayTime/4))+1;

	out = CombC.ar(in*lilEnv, 3, trigDur, decayTime);

	out = PitchShift.ar(out, 0.2, shift, 0.01);
	out = Pan2.ar(out, Line.kr(Rand(-1,1), Rand(-1, 1), decayTime+0.4));

	Out.ar(outBus, out*bigEnv*vol);
}).add;


SynthDef("tvFeedback_mod", {arg inBus0, inBus1, outBus, filterBoost=10, filterSpeed=0.1, rq = 0.1, onOff=1, gate=1, pauseGate=1;
	var env, in0, in1, pauseEnv, freq, chain, out, amp;

	in0 = Normalizer.ar(In.ar(inBus0));

	in1 = In.ar(inBus1)*10;

	amp = Amplitude.ar(in1);

	freq = SinOsc.kr(filterSpeed, 0).range(30, 10000);
	in0 = MidEQ.ar(in0, freq, rq, filterBoost);

	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	in0 = in0*env*pauseEnv;

	chain = FFT(LocalBuf(512), in0);

	out = IFFT(PV_BrickWall(chain, -0.5));

	Out.ar(outBus, [LPF.ar(LPF.ar(out, 8000), 8000), LPF.ar(LPF.ar(out, 8000), 8000), (in0*(1-min(amp*5, 1)))+in1]);

}).add;


SynthDef("sineUpDown2_mod", {arg outBus, volBus, startFreq, endFreq, time, gate=1, pauseGate = 1;
	var out, pauseEnv;

	out = SinOsc.ar(XLine.kr(startFreq, endFreq, time), Rand(0,2), 0.1);
	out = Pan2.ar(out, Line.kr(Rand(-1,1), Rand(-1, 1), time));

	out = out*EnvGen.kr(Env.new([0, 1, 1, 0],[time/6, (time/3), time/3], 'sine'), gate, doneAction:2);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, out*In.kr(volBus)*pauseEnv);
}).add;

SynthDef("sineUpDown4_mod", {arg outBus, volBus, startFreq, endFreq, time, gate=1, pauseGate = 1;
	var out, pauseEnv, lfo;

	out = SinOsc.ar(XLine.kr(startFreq, endFreq, time), Rand(0,2), 0.1);

	lfo = LFSaw.kr(Rand(0.1, 0.3), 2.0.rand);
	out = PanAz.ar(4, out, lfo);

	out = out*EnvGen.kr(Env.new([0, 1, 1, 0],[time/6, (time/3), time/3], 'sine'), gate, doneAction:2);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, out*In.kr(volBus)*pauseEnv);
}).add;

SynthDef("sineUpDown8_mod", {arg outBus, volBus, startFreq, endFreq, time, gate=1, pauseGate = 1;
	var out, pauseEnv, lfo;

	out = SinOsc.ar(XLine.kr(startFreq, endFreq, time), Rand(0,2), 0.1);

	lfo = LFSaw.kr(Rand(0.1, 0.3), 2.0.rand);
	out = PanAz.ar(8, out, lfo);

	out = out*EnvGen.kr(Env.new([0, 1, 1, 0],[time/6, (time/3), time/3], 'sine'), gate, doneAction:2);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);

	Out.ar(outBus, out*In.kr(volBus)*pauseEnv);
}).add;


SynthDef("neuwirthSine_mod", {arg freq, outBus, gate = 1, pauseGate = 1, sine0Gate = 0, sine1Gate = 0, sine2Gate = 0, sine3Gate = 0;
	var sine0, sine1, sine2, sine3, env, pauseEnv;

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	sine0 = SinOsc.ar(32.703, 0, 0.1)*EnvGen.kr(Env.asr(0.1,1,0.1), sine0Gate, doneAction:0);
	sine1 = SinOsc.ar(69.29, 0, 0.1)*EnvGen.kr(Env.asr(0.1,1,0.1), sine1Gate, doneAction:0);
	sine2 = SinOsc.ar(97.99, 0, 0.1)*EnvGen.kr(Env.asr(0.1,1,0.1), sine2Gate, doneAction:0);
	sine3 = SinOsc.ar(55, 0, 0.1)*EnvGen.kr(Env.asr(0.1,1,0.1), sine3Gate, doneAction:0);

	Out.ar(outBus, Mix.new([sine0, sine1, sine2, sine3]).dup*env*pauseEnv);
}).add;


SynthDef("wubSine_mod", {arg freq, outBus, gate = 1, pauseGate = 1, localGate = 0;
	var sine, env, pauseEnv;

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	sine = SinOsc.ar(freq, 0, 0.1);

	Out.ar(outBus, Pan2.ar(sine*AmpComp.kr(freq)*env*pauseEnv, Rand(-1, 1)));
}).add;


SynthDef("wubSine2_mod", {arg outBus, envGate0=0, envGate1=0, envGate2=0, whichFreq=0, gate = 1, pauseGate = 1;
	var sine, env, pauseEnv, localEnv, freq0, freq1, freq2, freq;

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(2,1,3), gate, doneAction:2);

	freq0 = EnvGen.kr(Env.new([68.5.midicps, 68.5.midicps, 76.midicps], [2, 50], 'exponential'), envGate0);
	//freq1 = EnvGen.kr(Env.new([80.midicps, 83.midicps], [11], 'exponential'), envGate1);
	//freq2 = EnvGen.kr(Env.new([988, 1109], [10], 'exponential'), envGate2);
	//XLine.kr(freq0, freq1, dur);

	//freq = Lag.kr(Select.kr(whichFreq, [freq0, freq1, freq2]), 0.3);

	sine = SinOsc.ar(freq0, 0, 0.1);

	Out.ar(outBus, Pan2.ar(sine*AmpComp.kr(freq)*env*pauseEnv, 0));
}).add;


SynthDef("blingerSine2_mod", {arg outBus, envGate0=0, envGate1=0, envGate2=0, whichFreq=0, gate = 1, pauseGate = 1;
	var sine, env, pauseEnv, localEnv, freq0, freq1, freq2, freq;

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(2,1,3), gate, doneAction:2);

	freq0 = EnvGen.kr(Env.new([50, 50, 50], [2, 50], 'exponential'), envGate0);
	//freq1 = EnvGen.kr(Env.new([80.midicps, 83.midicps], [11], 'exponential'), envGate1);
	//freq2 = EnvGen.kr(Env.new([988, 1109], [10], 'exponential'), envGate2);
	//XLine.kr(freq0, freq1, dur);

	//freq = Lag.kr(Select.kr(whichFreq, [freq0, freq1, freq2]), 0.3);

	sine = SinOsc.ar(freq0, 0, 0.8);

	Out.ar(outBus, Pan2.ar(sine*AmpComp.kr(freq)*env*pauseEnv, 0));
}).add;


SynthDef("plutaSine2_mod", {arg outBus, envGate0=0, envGate1=0, envGate2=0, whichFreq=0, gate = 1, pauseGate = 1;
	var sine, sine1, env, pauseEnv, localEnv, freq0, freq1, freq2, freq;

	pauseEnv = EnvGen.kr(Env.asr(0.01,1,0.01), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(2,1,3), gate, doneAction:2);

	freq0 = EnvGen.kr(Env.new([778, 778, 778], [2, 50], 'exponential'), envGate0);

	sine = SinOsc.ar(freq0, 0, 0.8);
	sine1 = SinOsc.ar(freq0+12, 0, 0.8);


	Out.ar(outBus, [sine, sine1]*AmpComp.kr(freq)*env*pauseEnv);
}).add;


SynthDef("rhythmicDelays_mod", {arg inBus, outBus, pauseGate = 1, gate = 1;
	var in, env, pauseEnv, out0, out1, out;

	in = In.ar(inBus, 1);

	out0 = Pan2.ar(CombC.ar(in, 3, 0.22727, 4), LFNoise2.kr(0.3).range(-1,1));
	out1 = Pan2.ar(CombC.ar(in, 3, 0.151515, 4), LFNoise2.kr(0.3).range(-1,1));

	out = SelectX.ar(LFNoise2.kr(0.3).range(0,2), [out0, out1]);

	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(3,1,3), gate, doneAction:2);

	Out.ar(outBus, out*env*pauseEnv);
}).add;


SynthDef("wubSine3_mod", {arg freq, outBus, vol=0, gate = 1, pauseGate = 1, localGate = 0;
	var sine, env, pauseEnv, localEnv;

	localEnv = EnvGen.kr(Env.asr(0.2,1,0.2), localGate, doneAction:0);
	pauseEnv = EnvGen.kr(Env.asr(0,1,0), pauseGate, doneAction:1);
	env = EnvGen.kr(Env.asr(0,1,0), gate, doneAction:2);

	sine = [SinOsc.ar(51.913087197493-1.5, 0, 0.25), SinOsc.ar(51.913087197493+1.5, 0, 0.25)];

	Out.ar(outBus, sine*AmpComp.kr(51.913087197493)*env*pauseEnv*localEnv*vol);
}).add;


SynthDef("fakeAutoTune_mod", {arg outBus, vol, freq, whichScale=0, onOff = 0;
	var osc, cScale, baseFreq, volume;

	baseFreq = freq.midicps;

	osc = SinOsc.ar(baseFreq, 0, 0.5);

	volume = Lag.kr(onOff, 0.01)*Lag.kr(vol, 0.05);

	Out.ar(outBus, osc.dup*volume);
}).add;


