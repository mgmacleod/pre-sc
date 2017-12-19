/*
==========================================================
DX490a - Summer 2010
Instructor: Stelios Manousakis
==========================================================
Class 3.1:
Timing in SuperCollider
Contents:
• Clocks
- SystemClock
- TempoClock
- AppClock
==========================================================
[http://modularbrains.net/dx490a/DX490A_su2010_03.1_[Timing|Clocks].html]
*/

// ================= CLOCKS =================
// In order to time processes, you need a class that can parse time: a Clock
// There are three different clocks in SC.

// ====== SystemClock ======
// In SC there is a global clock, called SystemClock. This is the most accurate option if you want to measure time in seconds. Notice that SystemClock is global, or a singleton; that is, only one instance can exist at a time inside SC (which makes a lot of sense since it's the 'system' clock)

// let's create a syntdef to use in this entire file:
s.boot;

(
SynthDef(\gray, {arg outBus = 0, freq = 400, amp = 1, dur = 1;
	var env, src, fdbin, fdbout;
	env = EnvGen.kr(Env([0, 1, 0], [0.05, 0.95], \sin), timeScale: dur, levelScale: amp, doneAction: 2);
	src = LPF.ar(GrayNoise.ar(amp), freq, env);
	Out.ar(outBus, Pan2.ar(src, Rand.new(-0.7, 0.7)));
}).load(s);
)

// now, play it once after half a second using the system clock.
(
SystemClock.sched(
	0.5, // time delay from evaluation
	{Synth(\gray)} // what you want your clock to do; Attention: Must be a function!
);
)

// now let's create a few repeating noise bursts:
(
SystemClock.sched(
	0.5, // time delay from evaluation
	{Synth(\gray); // function for the clock to perform
		0.75} // repeat every 0.75 secs
);
)

// you can manually stop it with Command-period, or:
SystemClock.clear;

// Yes, either way will clear ALL running SystemClocks...

// let's try to make it a bit more interesting
(
b = Array.series(7, 0.125, 0.125).reverse; // use this to create a bit more complex timing
SystemClock.sched(
	0.5, // time delay from evaluation
	{Synth(\gray, ([\freq, 1200.rrand(400) , \amp, 1.rrand(0.5)])); // function for the clock to perform, made slightly more interesting
		b.choose}  // pick any value from that array
);
)

// now let's trigger a 10 second gesture  by pressing spacebad
(
b = Array.series(7, 0.125, 0.125).reverse; // use this to create a bit more complex timing
w = SCWindow.new("press space to start a 10sec gesture");
w.view.keyDownAction = { arg view, char, modifiers, unicode, keycode;
	if (unicode == 32, {
		t = Main.elapsedTime;
		"elapsed time is: ".post; t.postln;
		SystemClock.sched(
			1, // time delay from evaluation
			{Synth(\gray, ([\freq, 1200.rrand(400) , \amp, 1.rrand(0.5)])); // function for the clock to perform, made slightly more interesting
				b.choose}  // pick any value from that array
		);
		SystemClock.sched(11, {SystemClock.clear}) // after 10 seconds, stop the clock
})};
w.front;
)

// The .sched method uses relative timing, counting from when the code was evaluate
// But, you can also time things to happen in a specific time after SC loads, using the .schedAbs method. The following example gives the same exact results, but with a different method:

(
b = Array.series(7, 0.125, 0.125).reverse; // use this to create a bit more complex timing
w = SCWindow.new("press space to start a 10sec gesture");
w.view.keyDownAction = { arg view, char, modifiers, unicode, keycode;
	if (unicode == 32, {
		t = Main.elapsedTime;
		("SC has been open for "++ t.asString++" seconds").postln;
		SystemClock.schedAbs(
			t +1, // time delay from evaluation
			{Synth(\gray, ([\freq, 1200.rrand(400) , \amp, 1.rrand(0.5)])); // function for the clock to perform, made slightly more interesting
				b.choose}  // pick any value from that array
		);
		SystemClock.schedAbs(t + 11, {SystemClock.clear})
})};
w.front;
)

// ====== TempoClock ======
// Another option for timing is to use TempoClock. This clock measures time in beats-per-second (not beats-per-minute) and is as stable as the SystemClock; besides tempo related time, it can give you the elapsed time too. It is also NOT a singleton, so you can have many instances running at the same time - and you can stop each one individually. It has many more methods than SystemClock.

// Here's an example we saw with SystemClock, but using TempoClock instead:

(
c = TempoClock(1.5); // create a new clock with 1.5 beats-per-second, ie: 1.5 * 60 = 90bpm
c.schedAbs(
	1, // time delay from evaluation (in beats)
	{
		arg ...args;
		[c.bar, args[0], args[1]].postln; // post current bar, current beat nr and elapsed time
		Synth(\gray); // make some sound
		2.0
}); // repeat every second beat
)

c.tempo_(3); // double the tempo
c.elapsedBeats.postln; // you can also ask what the current beat nr is
c.elapsedBeats.ceil; // or get the next beat
c.stop; //stop the clock

// some polyrthythm: 4/4 on 7/4
(
c = TempoClock(6);
c.schedAbs(1, {arg beat, sec;
	if (beat % 4 == 0, {Synth(\gray, ([freq:5000.rrand(8000), amp:0.25]))});
	if (beat % 4 == 2, {Synth(\gray, ([freq:4000.rrand(5000), amp:0.3]))});
	if (beat % 7 == 0, {Synth(\gray, ([freq:400.rrand(800), amp:0.6]))});
	if (beat % 7 == 2, {Synth(\gray, ([freq:800.rrand(1000), amp:0.55]))});
	if (beat % 7 == 4, {Synth(\gray, ([freq:1000.rrand(3000), amp:0.35]))});
	0.5});
)

c.tempo_(3)
c.stop

// You can have two clocks running at the same time.

(
m = Main.elapsedTime; // use this to synchronize them
c = TempoClock(2, 0, m + 1); // create a new clock with 1.5 beats-per-second, ie: 1.5 * 60 = 90bpm
c.schedAbs( 0, // time delay from evaluation (in beats)
	{arg ...args;
		"clock one is here: ".post;
		[c.bar, args[0], args[1]].postln; // post current bar, current beat nr and elapsed time
		Synth(\gray, ([freq:500, amp:0.6])); // make some sound
		2.0}); // repeat every second beat

d = TempoClock(3.5, 0, m + 1); // create a new clock with 1.5 beats-per-second, ie: 1.5 * 60 = 90bpm
d.schedAbs( 1, // time delay from evaluation (in beats)
	{arg ...args;
		"clock two is here: ".post;
		[c.bar, args[0], args[1]].postln; // post current bar, current beat nr and elapsed time
		Synth(\gray, ([freq:5000, amp:0.25])); // make some sound
		1.0}); // repeat every second beat
)


// ====== AppClock ======

// Finally, AppClock is another singleton clock, very similar in functionality to SystemClock - but less reliable because it runs on a lower priority thread. This is because AppClock is the clock to use for dealing with graphics, which in SuperCollider 3 have to run on a lower priority.
// If you do something and get a post like "cannot be called from this process", you need to replace the clock you're using with the AppClock, OR put your GUI code inside a function running on a lower priority thread by using the .defer method:

{//GUI code

}.defer

// This will actually reassign the function to the AppClock for you behind the scenes. So this:

(
var w, r;
w = Window.new("trem", Rect(200, 200, Window.screenBounds.width * 0.5, Window.screenBounds.height * 0.5));
w.front;
r = Routine({ arg time;
	60.do({ arg i;
		0.05.yield;
		w.bounds = w.bounds.moveBy(10.rand2, 10.rand2);
		w.alpha = cos(i*0.1pi)*0.5+0.5;
	});
	1.yield;
	w.close;
});
AppClock.play(r);
)

// Is the same as this:
(
var w, r;
w = Window.new("trem", Rect(200, 200, Window.screenBounds.width * 0.5, Window.screenBounds.height * 0.5));
w.front;
r = Routine({ arg time;
	60.do({ arg i;
		0.05.yield;
		{// must enclose this in a defered loop!
			w.bounds = w.bounds.moveBy(10.rand2, 10.rand2);
			w.alpha = cos(i*0.1pi)*0.5+0.5;
		}.defer; // Notice the .defer here - otherwise it won't work!
	});
	1.yield;
	w.close;
});
SystemClock.play(r);
)
