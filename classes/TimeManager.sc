/*
Time manager for the Pre project.


*/

PreTimeManager {
	var <>server;           // Server object
	var <>metroSynth;		// Metronome Synth
	var <oneBeat;			// Number of samples required for 1 beat at this tempo.
	var <beatCounter;		// Storage for total passed beats
	var <currentBeat;		// Current beat of the bar
	var <startRecBeat;		// The buffer beat at which recording started
	var <endRecBeat;		// The buffer beat at which recording stopped
	var <bufferBeat;		// Beat relative to the recording buffer
	var <totalRecBeats;		// Total beats used for recording
	var <totalLoopBeats;	// Total beats used for a loop;
	var <>cropFrame;		// Frame to crop at
	var <>tempo;			// Tempo
	var <>timeSig;			// Time Signature
	var <>recordingInsts;   // List of

}