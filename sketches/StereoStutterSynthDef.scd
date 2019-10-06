// Stereo stutter synthdef

// yoinked from http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Beat-Repeater-td7611362.html


(
SynthDef(\stereosampler_stutter, {| out = 0, amp=0.1, bufnum = 0, gate = 1, pos = 0, speed = 1, loop=0, doneAction=2, pan=0, reprate=4, envmix=1|

    var player,env;
    var trigger=1;
    trigger = Impulse.kr(reprate);
    env =  EnvGen.kr(\adsr.kr(Env.adsr(0.1,0.1,0.8,0.1)), gate, doneAction:doneAction);
    player = PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum) * speed, trigger, startPos: (pos*BufFrames.kr(bufnum)), doneAction:doneAction, loop: loop);
    player = Pan2.ar(player, pan, amp * 2);
    player = player * SelectX.kr(envmix, [1,env]);
    Out.ar(out, player);

}).store;
)