/* jam_2017-12-29: assembling stuff while playing. An experiment. Hopefully, a PRE Recursive Experiment.

Equipment:
Guitar audio (stereo): (SC in 1, 2)

MIDI controllers
Launchpad S and Pro
Akai MPK 261
Softstep 2


Goal: wide-open long-tailed atmospherics.  Acoustic guitars, lots of delay and reverb units with feedback

*/



(
s.boot;

var tc = TempoClock.new(2); // 120 bpm


var guitInBus = Bus.audio(s, 2); // 2 chan input for guitar audio
var micInBus = Bus.audio(s, 1); // 1 chan input for a microphone
var revBuses = ();
var delayBuses = ();

)