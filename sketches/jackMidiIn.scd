// Learning JACK MIDI in
(
if(MIDIClient.initialized.not) {
	MIDIClient.init(4, 2, false);

} {
	// something if not
	"already init'ed".postln;
};
)




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


MIDIClient.disposeClient;

MIDIClient.sources.class
MIDIdef.freeAll;




(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, num, chan, src;
	[vel, num, chan, src].postln;
}, srcID: 1234567);

)



MIDIFunc.trace(false);
~inPorts

MIDIIn.findPort("SuperCollider", "out0").uid_(1234567);


SCJConnection.allports.do({|pp| [pp, pp.class].postln;});

c = SCJConnection.connect(