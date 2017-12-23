/*
MIDI out




*/
MIDIClient.disposeClient
n = 4;
MIDIClient.init(n, n);


// m = MIDIOut(0);


(
~outPorts = nil!n;

n.do({ |i|
	var uuid;
	uuid = 84000+i;
	uuid = 0;
	~outPorts[i] = MIDIOut(i, uuid);

});



)


//

~outPorts.do({|p| [p, p.port, p.uid].postln });

