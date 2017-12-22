(
if(MIDIClient.initialized.not) {
	MIDIClient.init(8, 8, false);

} {
	// something if not
	"already init'ed".postln;
};
)

(
~lpChan = 0;
~lpOut = MIDIOut(6);
~lpNoteNums = Array.fill([8,8], {|i,j| j+(i*16) });
~colours = [12, 13, 14, 15, 28, 60, 62, 63, 47];
)

(
var path = [
	~lpNoteNums[0][0], ~lpNoteNums[0][1], ~lpNoteNums[0][2], ~lpNoteNums[0][3], ~lpNoteNums[0][4], ~lpNoteNums[0][5], ~lpNoteNums[0][6], ~lpNoteNums[0][7],
	~lpNoteNums[1][7], ~lpNoteNums[2][7], ~lpNoteNums[3][7], ~lpNoteNums[4][7], ~lpNoteNums[5][7], ~lpNoteNums[6][7], ~lpNoteNums[7][7],
	~lpNoteNums[7][6], ~lpNoteNums[7][5], ~lpNoteNums[7][4], ~lpNoteNums[7][3], ~lpNoteNums[7][2], ~lpNoteNums[7][1], ~lpNoteNums[7][0],
	~lpNoteNums[6][0], ~lpNoteNums[5][0], ~lpNoteNums[4][0], ~lpNoteNums[3][0], ~lpNoteNums[2][0], ~lpNoteNums[1][0],
	~lpNoteNums[1][1], ~lpNoteNums[1][2], ~lpNoteNums[1][3], ~lpNoteNums[1][4], ~lpNoteNums[1][5], ~lpNoteNums[1][6],
	~lpNoteNums[2][6], ~lpNoteNums[3][6], ~lpNoteNums[4][6], ~lpNoteNums[5][6], ~lpNoteNums[6][6],
	~lpNoteNums[6][5], ~lpNoteNums[6][4], ~lpNoteNums[6][3], ~lpNoteNums[6][2], ~lpNoteNums[6][1],
	~lpNoteNums[5][1], ~lpNoteNums[4][1], ~lpNoteNums[3][1], ~lpNoteNums[2][1],
	~lpNoteNums[2][2], ~lpNoteNums[2][3], ~lpNoteNums[2][4], ~lpNoteNums[2][5],
	~lpNoteNums[3][5], ~lpNoteNums[4][5], ~lpNoteNums[5][5],
	~lpNoteNums[5][4], ~lpNoteNums[5][3], ~lpNoteNums[5][2],
	~lpNoteNums[4][2], ~lpNoteNums[3][2],
	~lpNoteNums[3][3], ~lpNoteNums[3][4],
	~lpNoteNums[4][4], ~lpNoteNums[4][3],
];
var i = 0;
r = Routine({
	inf.do{
		var velocity = ~colours.choose;
		path.do{|note, i|
			~lpOut.noteOn(~lpChan, note, velocity);
			0.015.wait;
			~lpOut.noteOff(~lpChan, note, velocity);
			i = i + 1;
		};

		velocity = ~colours.choose;

		path.reverse.do{|note, i|
			~lpOut.noteOn(~lpChan, note, velocity);
			0.015.wait;
			~lpOut.noteOff(~lpChan, note, velocity);
			i = i + 1;
		};

	}
});
TempoClock.default.sched(0, r);
)
r.stop;
t = TempoClock.default;

t.clear;

~lpOut.control(~lpChan, 104, 12);
~lpOut.noteOff(~lpChan, 96, 64);

~lpOut.noteOn(~lpChan, 113, 12);


~colours = [12, 13, 14, 15, 28, 60, 62, 63, 47];

MIDIClient.myinports;
MIDIClient.myoutports;
MIDIdef.freeAll
(
// this dog won't bark
MIDIdef.noteOn(\noteOnTest, {
	arg vel, num, chan, src;
	[vel, num, chan, src].postln;
}, srcID: ~lpIn.uid);




)


~lpOut.uid
