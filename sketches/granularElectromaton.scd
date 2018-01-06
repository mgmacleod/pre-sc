// «Granular electromaton» by William Mox Drossard
// Hi to all SCaddicts, This is my first post here, hope you'll enjoy it. Rhythmic automaton with some nice hope so effects.
// http://sccode.org/1-4QN


(
Server.local.waitForBoot({
(
z.free;
z = Buffer.alloc(s, 512, 1);
z.sine1(1.0 / [1, 2, 3, 4], true, true, true);

 fork( { loop {
 SynthDef("g1",{ arg out=0,bufnum=0,dur=1,rate=1,pos=0,sdens=1,edens=1;
     var dens = Line.kr(sdens,edens,dur);
     var trig = [LFNoise0,SinOsc,Impulse,LFPulse,LFSaw].choose.ar(Line.kr(sdens,edens,dur));
     //var env = EnvGen.kr(Env.perc(0.0001.rrand(0.1),dur*0.5.rrand(2)),doneAction:2);
     var env = EnvGen.kr(Env.perc(0.0001.rrand(0.1),dur*(0.5.rrand(4))),doneAction:2);
     Out.ar(out,
         GrainBuf.ar(2,trig,1/dens,bufnum,rate,pos)*env;
         )
     }).add();
  [1,2,4,8,16,32].choose.postln.wait;
 }
 }
 );


a = Pbind(\instrument,\g1,\dur,Pseq([Pseq([0.25],32),Pseq([0.25,0.125,0.125],32),Pseq([0.125],32)],inf),\sdens,Pseq([9000,1000,500]/10,inf),\edens,Prand([Pseq([9000,1000,500]/10,4),Pseq([1],1)],inf),\rate,Pfunc({-10.0.rrand(10)}),\pos,Pfunc({1.0.rand}),\bufnum,z.bufnum);
b = Pbind(\instrument,\g1,\dur,Pseq([4],inf),\sdens,Pseq([9000,1000,500]/100,inf),\edens,Prand([Pseq([9000,1000,500]/10,1),Pseq([1],3)],inf),\rate,Pfunc({-10.0.rrand(10)}),\pos,Pfunc({-10.0.rrand(10)}),\bufnum,z.bufnum);
c = Pbind(\instrument,\g1,\dur,Pseq([4/3],inf),\sdens,Pseq([9000,1000,500,25],inf),\edens,Prand([Pseq([9000,1000,500,25],1),Pseq([1],4)],inf),\rate,Pfunc({-100.0.rrand(100)}),\pos,Pfunc({-10.0.rrand(10)}),\bufnum,z.bufnum);


a =a.play;
b =b.play;
c =c.play;

)
});
)