// Learning JACK MIDI in
// But all JACK MIDI input ports appear to have the same uid and other identifying properties, so are essentially the same port

// this code currently uses ALSA (I'm assuming) to establish direct connections; connections on the jack graph have no effect.

// TODO: figure out if the JACK ports are truly indistinguishable.
// They report unique uids, but registering a MIDIdef or Func on them produces nothing

/*
JACK MIDI
TODO: report findings or die trying
*/


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

MIDIIn.findPort("SuperCollider", "out0").uid = 0;


SCJConnection.allports.do({|pp| [pp, pp.class].postln;});

MIDIClient.sources.select({arg item, i; (item.device == "SuperCollider" && item.name == "out1")});