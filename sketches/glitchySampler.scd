/*
«glitchySampler» by tigges-p
on 12 Aug'14 14:32 in samplerglitch

Hey guys! I used this code on my first release and some people asked for a look on it. It's basically a PlayBuf UGen whose arguments are modulated to a user-defined degree by several LFNoise UGens, thus leading to playback direction changes and retriggering with different starting points.

Cheers!

http://sccode.org/1-4Ws

*/


(
SynthDef(\glitchySampler, {
	|
	buffer,                //the buffer should contain a stereo file
	out          = 0,
	gate         = 1
	rate         = 1,      //buffer playback rate
	amp          = 0.5,
	att          = 0.01,   //attack time of the adsr envelope
	dec          = 0.4,    //decay time
	sust         = 0.7,    //sustain level
	rel          = 1,      //release time (synth is freed when the envelope finishes)
	lpf          = 20000,  //low pass filtering frequency
	hpf          = 20,     //high pass filtering frequency
	trigfreq     = 1,      //the frequency at which the PlayBuf UGen is triggered to jump to the start position
	trigrand     = 0,      //the actual trigger frequency is calculated by (\trigfreq * (2 to the power of (this * an LFNoise UGen with range -1 to 1))); setting this to 0 will result in a constant trigger frequency
	startmul     = 1,      // \trigfreq also controls the frequency of an LFNoise UGen which changes PlayBuf's starting point; this is a multiplier for that frequency; setting this to 0 will result in a constant starting point
	dirmul       = 1,      //same as above, but controlling the frequency of random playback direction changes
	randmul      = 1       //same as above, but for random trigger frequency changes
	|

	var start, direction, rand, trig, sig, env;

	start = {LFNoise1.kr(trigfreq*startmul, 0.5, 0.5)}!2; //modulating the starting point; different for left and right channel

	direction = {Select.kr(LFNoise1.kr(trigfreq*dirmul) > 0, [-1, 1])}!2; //modulating the direction; different for left and right channel

	rand = {LFNoise1.kr(trigfreq*randmul)}!2; //modulating the trigger frequency; different for left and right channel

	trig = Impulse.kr(trigfreq*pow(2, trigrand*rand)); //the trigger for PlayBuf

	sig = PlayBuf.ar(2, buffer, BufRateScale.kr(buffer)*rate*direction, trig, BufFrames.kr(buffer)*start, 1); //playing the (looping) stereo buffer

	env = Env.adsr(att, dec, sust, rel, amp);
	env = EnvGen.kr(env, gate, doneAction: 2); //simple adsr envelope which frees the synth when finished

	sig = LPF.ar(HPF.ar(sig*env, hpf), lpf); //basic filtering

	Out.ar(out, sig);
	}
).add;
)







//////////////////////////////////////////////////////////////////////////////////////////////
// If you want to test the above fast, here is basically what I used for the EP - not really interesting though
//////////////////////////////////////////////////////////////////////////////////////////////

b = Buffer.read(s, /*path to your stereo soundfile; I used recordings of a tuba, a western guitar and a panflute*/);
MIDIClient.init;
MIDIIn.connect(0, MIDIClient.sources[/*index of your device*/]);


(
var activenotes = nil!128;

var sustain = 0;

var sustained = false!128;

var releasefunction = {|index|

	if(activenotes[index].notNil)
	{
		activenotes[index].release;
		activenotes[index] = nil;
	};
};


MIDIIn.noteOn = { arg src,chan, midinote, velocity;

	releasefunction.value(midinote);

	activenotes[midinote] = Synth(\glitchySampler,[\buffer, b, \rel, velocity/20, \trigfreq, 0.15, \trigrand, 1, \rate, (midinote-60).midiratio, \amp, velocity/(127.0*8), \startmul, 2, \dirmul, 0.3, \randmul, 1, \lpf, 7000]);
	//Synth(\glitchySampler,[\buffer, b, \rel, velocity/20, \trigfreq, 2, \trigrand, 10, \rate, (midinote-60).midiratio, \amp, velocity/(127.0*8), \startmul, 2, \dirmul, 4, \randmul, 2, \lpf, 17000]);
	//Synth(\glitchySampler,[\buffer, b, \rel, velocity/20, \trigfreq, 0.4, \trigrand, 5, \rate, (midinote-60).midiratio, \amp, velocity/(127.0*8), \startmul, 1, \dirmul, 1, \randmul, 1, \lpf, 4000]);

};


MIDIIn.noteOff = { arg src,chan, midinote, velocity;

	if(sustain == 0)
	{
		releasefunction.value(midinote);
	}{
		sustained[midinote] = true;
	};
};

MIDIIn.control = {|uid,channel,cN,v|

	if(cN == 64/*64 is the sustain pedal*/)
	{
		sustain = v;

		if(sustain == 0)
		{
			sustained.do{|value, index|
				if(value)
				{
					sustained[index] = false;
					releasefunction.value(index);
				}
			}
		}
	};
};
)