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


b.free


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



