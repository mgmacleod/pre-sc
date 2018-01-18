
FilterDelays_Mod : Module_Mod {
	var largeEnv, envGroup, synthGroup, largeEnvBus, nextTime, localRout, delayTime, length, filterStart, filterEnd, rqStart, rqEnd, filterVol, delayVar, waitVar;

	*initClass {
		StartUp.add {
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
		}
	}

	init {

		this.initControlsAndSynths(3);

		this.makeMixerToSynthBus;

		envGroup = Group.head(group);
		synthGroup = Group.tail(group);

		largeEnvBus = Bus.control(group.server);
		filterVol = Bus.control(group.server);

		filterVol.set(0);

		largeEnv = Synth("largeEnvFilt_mod", [\outBusNum, largeEnvBus.index, \attack, 4, \decay, 10, \gate, 1.0], envGroup);

		localRout = Routine.new({{
			delayTime = delayVar.rand+(delayVar/6);
			length = 2.0.rand + 5;

			filterStart = exprand(200,18000);
			filterEnd = exprand(200,18000);

			rqStart = rrand(0.025, 0.1);
			rqEnd = rrand(0.025, 0.1);

			switch(numChannels,
				2,{
					Synth("filterDelays2_mod", [\inBusNum, mixerToSynthBus.index, \outBus, outBus, \largeEnvBusNum, largeEnvBus.index, \filterStart, filterStart, \filterEnd, filterEnd, \rqStart, rqStart, \rqEnd, rqEnd, \delayTime, delayTime, \length, length, \vol, filterVol.index], synthGroup);
				},
				4,{
					Synth("filterDelays4_mod", [\inBusNum, mixerToSynthBus.index, \outBus, outBus, \largeEnvBusNum, largeEnvBus.index, \filterStart, filterStart, \filterEnd, filterEnd, \rqStart, rqStart, \rqEnd, rqEnd, \delayTime, delayTime, \length, length, \vol, filterVol.index], synthGroup);
				},
				8,{
					Synth("filterDelays8_mod", [\inBusNum, mixerToSynthBus.index, \outBus, outBus, \largeEnvBusNum, largeEnvBus.index, \filterStart, filterStart, \filterEnd, filterEnd, \rqStart, rqStart, \rqEnd, rqEnd, \delayTime, delayTime, \length, length, \vol, filterVol.index], synthGroup);
				}
			);
			(waitVar + ((waitVar/4).rand)).wait;
		}.loop});

		controls.add(QtEZSlider.new("vol", ControlSpec(0,8,'amp'),
			{|v|
				filterVol.set(v.value);
			}, 0, true, \horz));
		this.addAssignButton(0,\continuous);

		controls.add(QtEZSlider.new("length", ControlSpec(1,5,'linear'),
			{|v|
				delayVar = v.value;
			}, 3.0, true, \horz));
		this.addAssignButton(1,\continuous);

		controls.add(QtEZSlider.new("wait", ControlSpec(0.3,8,'linear'),
			{|v|
				waitVar = v.value;
			}, 0.55, true, \horz));
		this.addAssignButton(2,\continuous);

		//multichannel button
		numChannels = 2;
		controls.add(Button()
			.states_([["2", Color.black, Color.white],["4", Color.black, Color.white],["8", Color.black, Color.white]])
			.action_{|butt|
				switch(butt.value,
					0, {
						numChannels = 2;
					},
					1, {
						numChannels = 4;
					},
					2, {
						numChannels = 8;
					}
				)
			};
		);

		this.makeWindow("FilterDelays",Rect(718, 758, 380, 98));

		win.layout_(VLayout(
			HLayout(controls[0].layout,assignButtons[0].layout),
			HLayout(controls[1].layout,assignButtons[1].layout),
			HLayout(controls[2].layout, assignButtons[2].layout),
			controls[3].maxWidth_(60)
		));
		win.layout.spacing = 2;
		win.layout.margins = [0,0,0,0];


		SystemClock.play(localRout);
	}

	pause {
		largeEnv.set(\pauseGate, 0);
	}

	unpause {
		largeEnv.set(\pauseGate, 1);
	}

	setSpecialMidi {arg data, dataType, controlsIndex;
		3.do{arg i;
			this.setMidi([data[0],[7,12,10].at(i)], 0, i);
		}
	}

	killMeSpecial {
		largeEnv.set(\gate, 0);
		localRout.stop;
		largeEnvBus.free;
	}
}
