///////////////////////////////////////////////////////////////////////
// From the docs:

//// using FbNode:

// simple dub delay effect

b = Buffer.read(s,Platform.resourceDir ++ "/sounds/a11wlk01.wav")

(
{
	var in = PlayBuf.ar(1,b);
	var fbNode = FbNode(1,0.6);
	var signal = fbNode.delay; // read the feedback bus and delay the result.
		// The delay time defaults to the max delay time, 0.6 s in this case.

	// Add the input to the feedback signal, then filter and distort it.
	signal = BPF.ar(signal*0.8 + in, 2000, 3.8).distort;
	// for fun effects, try changing the 0.8 to something greater than one

	// write the signal to the feedback buffer
	fbNode.write(signal);

	DetectSilence.ar(signal ,doneAction:2);
	signal!2;
}.play;

)

// Karplus-Strong style plucked string algorithm (see also Pluck)
(
{
	var in = Impulse.ar(0)!2; // stereo input (although in this case both channels are the same)
	var freq = 200;
	var fbNode = FbNode(2, 0.1); // two channel feedback with a maximum delay time of 0.1 s

	var signal = fbNode.delay(1/freq);
	signal = LPF.ar(LeakDC.ar(signal),8000)*0.99 + in;

	fbNode.write(signal); // two channel signal being written into two-channel FbNode

	DetectSilence.ar(signal,doneAction:2);
	signal;

}.play

)

// basic usage without adding a delay line: self-modulating sine wave.
(
{
	var fbNode = FbNode(1);
	var signal = SinOsc.ar(100, fbNode * Line.kr(0,2,10) );
		// the FbNode is used to modulate the SinOsc's phase

	fbNode.write(signal);
	signal ! 2;
}.play;
)

// Two delay lines with cross talk. This would be quite awkward to do with Fb.
(
{
	var in = WhiteNoise.ar*Line.kr(1,0,0.1);

	// create two FbNodes with different delay times
	var fbNode1 = FbNode(1,9/8);
	var fbNode2 = FbNode(1,1);
	var sig1 = in + (fbNode1.delay * 0.8) + (fbNode2.delay * 0.1);
	var sig2 = in + (fbNode1.delay * 0.1) + (fbNode2.delay * 0.8);

	fbNode1.write(sig1);
	fbNode2.write(sig2);

	Pan2.ar(sig1, -0.8) + Pan2.ar(sig2, 0.8);
}.play;

)

// using the multi-tap delay feature
(
{
	var in = Saw.ar([100,102])*Line.kr(1,0,0.1); // stereo input signal
	var fbNode = FbNode(2, 1.0);

	var signal = Mix.fill(10,{fbNode.delay(1.0.rand)});

	fbNode.write(in + (signal*0.1));
	// if you want, you can use FbNode as a normal multi-tap delay, just by not adding in the
	// feedback signal here.

	signal;

}.play;

)


// How to create an array of many feedback delay lines.
// (This doesn't sound great, but it illustrates the technique.)
(
{
	var in = WhiteNoise.ar*Line.kr(1,0,0.05);
	var n = 10;
	var fbNodes = {FbNode( 1, rrand(0.1,1.0) )}!n;
		// create n mono FbNodes, each with a different max delay time.

	var signals = n.collect {
		arg i;
		// the nodes are arranged in a circle, with each one getting some feedthough from
		// the nodes on either side.
		var signal = in + (fbNodes[i].delay*0.4)
			+ (fbNodes[(i+1)%n].delay*0.3)
			+ (fbNodes[(i-1)%n].delay*0.3);
		fbNodes[i].write(signal);
	};

	Splay.ar(signals);
}.play;
)


//// using Fb

// simple dub delay effect
(
{
	var in = PlayBuf.ar(1,b);
	var out = in + Fb({
		arg feedback; // this will contain the delayed output from the Fb unit
		// filter and distort the feedback signal.
		// Note that the input signal is fed in here as well:
		BPF.ar(feedback*0.8 + in, 2000, 3.8).distort;
		// for fun effects, try changing the 0.8 to something greater than one

	},0.6);
	DetectSilence.ar(out,doneAction:2);
	out!2;
}.play;
)

// Karplus-Strong style plucked string algorithm (see also Pluck)
(
{
	var sig = Impulse.ar(0)!2; // stereo input - feedback will expand to two channels
	var freq = 200;
	sig = FbL({arg fb; LPF.ar(LeakDC.ar(fb),8000)*0.99+sig;},1/freq);
	DetectSilence.ar(sig,doneAction:2);
	sig;
}.play
)

// Multiple instances in one SynthDef: three Karplus-Strong style algorithms in a row
(
{
	var sig = Impulse.ar(0);
	sig = FbL({arg fb; LPF.ar(LeakDC.ar(fb),8000)*0.99+sig;},1/300);
	sig = FbL({arg fb; LPF.ar(LeakDC.ar(fb),8000)*0.99+sig;},1/400);
	sig = FbL({arg fb; LPF.ar(LeakDC.ar(fb),8000)*0.99+sig;},1/500);
	DetectSilence.ar(sig,doneAction:2);
	sig!2;
}.play
)

// You can nest feedback loops inside each other
(
{
	var sig = Decay.kr(Impulse.kr(1/2),0.6)*PinkNoise.ar(1!2);

	sig = FbL({
		arg fb1;
		sig = sig + FbL({
			arg fb2;
			(OnePole.ar(LeakDC.ar(0-fb2),0.2)*0.99*1)+(fb1*9) / 10;
		},1/250);
		OnePole.ar(sig,-0.01);
	},0.1);

	sig;
}.play;
)



/////////////////////////////////////////////////////////////////////////////
// from Re: Dub Echo with Ping Pong (http://sccode.org/1-1P4)

(
SynthDef(\dubecho,{|in, out, length = 1, fb = 0.8, sep = 0.012|
	var input = In.ar(in, 2);
	var output = input + Fb({ |feedback|

		var left, right;
		var magic = LeakDC.ar(feedback*fb + input);
		magic = HPF.ar(magic, 400); // filter's on the feedback path
		magic = LPF.ar(magic, 5000);
		magic = magic.tanh; // and some more non-linearity in the form of distortion
		#left, right = magic; // let's have named variables for the left and right channels
		magic = [DelayC.ar(left, 1, LFNoise2.ar(12).range(0,sep)), DelayC.ar(right, 1, LFNoise2.ar(12).range(sep,0))].reverse;

	},length);

	ReplaceOut.ar(out, output);
}).add;
)


// Example as effecet bus
~bus = Bus.audio(s, 2);
~echo = Synth(\dubecho, [\in, ~bus, \length, TempoClock.default.tempo*(3/8), \fb, 0.7, \sep, 0.0012], addAction: \addToTail);

// send something
play{ Out.ar(~bus, LFGauss.ar(1, 0.1, loop:0, doneAction:2) * Blip.ar(80, 8)) }

// turn it off
~echo.free;