/*
MIDI out




*/
MIDIClient.sources
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


(
i = 0;
r = Routine.new( {

	inf.do{
		var vel;
		var note;

		vel = [13, 14, 15, 12, 28, 63].choose;
		note = [112, 113, 114, 115].choose;
		~outPorts[0].noteOn(0, note, vel);
		0.25.wait;
		i = i + 1;
	}


});
)

TempoClock.default.sched(0.25, r);
TempoClock.default.stop;
t = TempoClock.default;
t.tempo = 145/60;
t.clear;

MIDIClient.disposeClient


~outPorts[0].noteOff(0, 115, 64)

m = MIDIOut(0);

m.noteOff(0, 112, 64);