// Learning JACK MIDI in
// But all JACK MIDI input ports appear to have the same uid and other identifying properties, so are essentially the same port

// this code currently uses ALSA (I'm assuming) to establish direct connections; connections on the jack graph have no effect.

// TODO: figure out if the JACK ports are truly indistinguishable.
// They report unique uids, but registering a MIDIdef or Func on them produces nothing

/*
JACK MIDI

Input ports:
----------------------
Supercollider's JACK midi inputs are accessible and they report unique uids.  However, when we
do a MIDIFunc.trace, we see all jack midi input coming from a single uid regardless of port; moreover the
uid of this port is not any of those reported by MIDIClient for SC's ports.


Output ports:
------------------------------

On G/L, MIDIOut(pn), where pn is the number of the jack out port, assuming they are indexed starting at 0
(i.e., MIDIOut(0) is the first added to the JACK graph) -- wow, what a long-winded explanation! Just tell them
it's a fucking JACK MIDI output.

*/

MIDIClient.destinations
(
if(MIDIClient.initialized.not) {
	MIDIClient.init(4, 2, false);

} {
	// something if not
	"already init'ed".postln;
};
)


MIDIFunc.trace(true);

(
~inPorts = IdentityDictionary.new;
~outPorts = IdentityDictionary.new;

MIDIClient.sources.do({
	arg item;

	if(item.device == "SuperCollider") {
		~outPorts.put(item.name.asSymbol, item.uid);
	};

});

MIDIClient.destinations.do({
	arg item;
	if(item.device == "SuperCollider") {
		~inPorts.put(item.name.asSymbol, item.uid);
	};
});
)

MIDIIn.connectAll;
MIDIClient.disposeClient;

MIDIClient.sources.class
MIDIdef.freeAll;




(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, num, chan, src;
	[vel, num, chan, src].postln;
}, srcID: 0);

)

m = MIDIIn.findPort("SuperCollider", "out1");
m.uid
MIDIFunc.trace(false);
~inPorts
~outPorts

MIDIIn.findPort("SuperCollider", "out0").uid = 0;


SCJConnection.allports.do({|pp| [pp, pp.class].postln;});

MIDIClient.sources.select({arg item, i; (item.device == "SuperCollider" && item.name == "out1")});