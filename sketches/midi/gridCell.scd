// A cell in a grid of cells.

(
Window.closeAll;

// a window
w = Window.new;


~loc = 0@0;
~button = Button.new(w, Rect(~loc.x, ~loc.y, 86, 43)); // a Button
~inBus = [4,5]; // hardware input bus(es) to use
~outBus = [1,2];

~recBuf = Buffer.alloc(s, 60*s.sampleRate, ~inBus.size);
[~recBuf, ~recBuf.class].postln;

w.front;
)
(
var loc;
loc = 0@0;
[loc.x, loc.y].postln;
)
loc