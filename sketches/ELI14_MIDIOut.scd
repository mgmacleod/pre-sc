// ELI14: MIDIOut

// 1. Create an instance
m = MIDIOut(0);  // the 0th JACK output port


m.latency = 0;
s.latency = 0.001;
MIDIClient.destinations