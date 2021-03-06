MantaBuffers_Mod : Module_Mod {
	var buffer, localRout, startPos, duration, vol, playRate, synthOutBus, buffer, dur, fade, trigRate, centerPos, center, width, yRange, recordGroup, playGroup, volBus, trigSpec, temp;

	var trigRates, durations;

	*initClass {
		StartUp.add {
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
		}
	}

	init {
		this.makeWindow("MantaBuffers", Rect(707, 393, 200, 60));
		this.initControlsAndSynths(50);

		this.makeMixerToSynthBus(1);

		dontLoadControls = [1];

		buffer = Buffer.alloc(group.server, group.server.sampleRate*10, 1);

		"bufnum".post; buffer.bufnum.postln;

		synths = List.newClear(2);

		recordGroup = Group.head(group);
		playGroup = Group.tail(group);

		trigSpec = ControlSpec(15, 120, \exp);

		trigRates = Array.fill(48,{0});
		durations = Array.fill(48,{0});

		synths.put(0, Synth("mantaBuffersRecord_mod", [\inBus, mixerToSynthBus.index, \bufnum, buffer.bufnum], recordGroup));

		yRange = 1;

		synths.put(1, Synth("mantaBuffersPlay_mod", [\bufnum, buffer.bufnum, \outBus, outBus, \vol, 1], playGroup));

		controls.add(QtEZSlider.new("vol", ControlSpec(0,1,'amp'),
			{|v|
				vol = v.value;
				synths[1].set(\vol, v.value);

		}, 0, true, \horz));
		this.addAssignButton(0,\continuous);

		/*		controls.add(QtEZSlider.new("playRate", ControlSpec(-4,4,'linear'),
		{|v|
		playRate = v.value;
		if(playRate ==0, {playRate = 0.05});
		if(playRate.abs<0.05, {playRate = 0.05*(playRate.sign)});
		synths[1].set(\playRate, playRate);
		}, 1, true, \horz));
		this.addAssignButton(4,\continuous);*/

		controls.add(Button()
			.states_([["rec", Color.red, Color.black],["lock", Color.red, Color.black]])
			.action_{arg butt;
				if(butt.value==1,{
					synths[0].set(\recordOn, 0);
					},{
						synths[0].set(\recordOn, 1);
				})
		});
		this.addAssignButton(1,\onOff, Rect(65, 5, 16, 16));

		controls.add(Button.new()
			.states_([ [ "A-Manta", Color.red, Color.black ] ,[ "C-Manta", Color.black, Color.red ] ])
			.action_{|v|
				if(v.value==1,{
					this.setManta;
					},{
						this.clearMidiOsc;
				})
		});

		win.layout_(
			VLayout(
				HLayout(controls[0].layout,assignButtons[0].layout),
				HLayout(controls[1],assignButtons[1].layout, controls[2])
			)
		);
	}

	setManta {
		var counter=0;

		(1..48).do{arg key, i;
			oscMsgs.put(i+1, "/manta/value/"++key.asString);
			//oscMsgs.put(i+48+1, "/manta/noteOff/"++key.asString);
			MidiOscControl.setControllerNoGui(group.server, oscMsgs[i+1],
				{arg val;
					temp = trigSpec.map(val/180);
					if(temp<16, {temp = 0});
					trigRates.put(i, temp);
					durations.put(i, 1/max(5, trigRates[i]/4));
					trigRates.postln;
					durations.postln;
					synths[1].set(\trigRates, trigRates, \durations, durations)
				},
				setups);
			/*MidiOscControl.setControllerNoGui(group.server, oscMsgs[i+48+1],
				{
					trigRates.put(i, 0);
					synths[1].set(\trigRates, trigRates)
				},
				setups);*/
			counter=counter+1;
		};

	}

	clearManta {
		(2..50).do{arg num;
			MidiOscControl.clearController(group.server, oscMsgs[num]); //send a message to clear the OSC data from the MidiOscControl
			oscMsgs.put(num, nil);
		}
	}

	save {
		var saveArray, temp;

		saveArray = List.newClear(0);

		saveArray.add(modName); //name first

		temp = List.newClear(0); //controller settings
		controls.do{arg item;
			temp.add(item.value);
		};

		saveArray.add(temp);  //controller messages
		saveArray.add(oscMsgs.copyRange(0,1));

		saveArray.add(win.bounds);

		this.saveExtra(saveArray);
		^saveArray
	}

/*	load {arg loadArray;
		loadArray.do{arg item; item.postln};
		loadArray[1].do{arg controlLevel, i;
			if(controls[i].value!=controlLevel, {controls[i].valueAction_(controlLevel)});
		};

		win.bounds_(loadArray[3]);
	}*/

}
