////////////////////////////////////////////////////////////////////////////
// Quick example of side chaining via direct audio channels and with proxyspace
// by rukano
// http://sccode.org/1-55m

s.boot;

////////////////////////////////////////
// side chain compression w/o proxyspace

k = Bus.audio(s, 2); // channels for the kick
x = Bus.audio(s, 2); // channels for the pad

{ Out.ar(k, Decay2.ar(Impulse.ar(2), 0.01, 1) * SinOsc.ar(80).dup) }.play; // shitty kick
{ Out.ar(x, Splay.ar(Saw.ar([60, 62, 65, 67].midicps/2)) * 0.5) }.play; // shitty pads

// master out
(
z.free; // so you can change parameters and reexecute it w/o adding more fx on top of each other
z = {
	var kick = In.ar(k, 2); // get the kick signal
	var pads = In.ar(x, 2); // get the pads signal
	var thresh = 0.1; // this would be the amp threshold when the Compander should "do" something
	var compression = 0.0001; // the reduction ratio (reduction if below 1... expansion if above 1 !
	var attack = 0.01;
	var release = 0.1;
	var snd = Compander.ar(pads, kick, thresh, 1, compression, attack, release); // compressed signal with sidechain
	Out.ar(0, snd + kick); // add the kick to it, cause otherwise you will only have the compressed pads!
}.play(addAction: \addToTail); // add to tail to work as master effect
)

z.free;
x.free;
k.free;

/////////////////////////////
// side chain with proxy space:

// our favourite live coding environment:
p = ProxySpace.push(s);

~pads = { Splay.ar(Saw.ar([60, 62, 65, 67].midicps/2)) * 0.5 }; // shitty pads
~kick = { Decay2.ar(Impulse.ar(2), 0.01, 1) * SinOsc.ar(80).dup }; // shitty kicks

~master.play; // node proxy for everything (as a master effect)
(
~master = {
	// same arguments as the other example:
	var thresh = 0.1;
	var compression = 0.1;
	var attack = 0.01;
	var release = 0.1;
	// here you get the signals directly from the node proxies, not over audio channels... easier to read
	var snd = Compander.ar(~pads.ar, ~kick.ar, thresh, 1, compression, attack, release);
	snd + ~kick.ar // the proxy has it's own output. Alternatively you can ~kick.play to hear the kick directly, you won't have to add it here
}
)

// That's it