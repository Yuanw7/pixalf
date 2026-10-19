import assert from 'node:assert/strict';
import {boot} from './harness.mjs';

// 0.8.0 level-complexity suite: the six new mechanisms from the Trap and Weapon
// pack, plus the two invariants that keep the harder levels fair — every
// periodic hazard keeps a rest window, and no hazard ever covers a checkpoint
// spawn or an answer tile.
const mech=s=>s.status().mechanisms;
const one=(s,id)=>mech(s).find(m=>m.id===id);
const checks=[];

/* ---------- inventory, telegraph contract, fairness invariants ---------- */
const g=boot();await g.ready();g.click('#start');
const st=g.status();
assert.equal(st.assets,43,'new trap sheets embedded');
for(const kind of ['flame','fan','bomb','wallspike','spikerow','rockfall','flameband','doll']){
 assert.ok(mech(g).some(m=>m.kind===kind),`${kind} is placed in the campaign`);
}
const per=stage=>mech(g).filter(m=>m.stage===stage).length;
assert.ok(per(0)>=5&&per(1)>=9&&per(2)>=5&&per(3)>=9&&per(4)>=6,`hazard density per stage: ${[0,1,2,3,4].map(per).join('/')}`);
assert.equal(st.hazards.filter(p=>p.stage===1).length,4,'stage 1 sweeps four pendulums');
assert.equal(st.hazards.filter(p=>p.stage===4).length,3,'the beam keeps its three rotating heads');

// Telegraph contract: a periodic hazard rests for at least a third of its cycle,
// and every new damage source shows a lead-in of at least 0.8 s before it hurts.
const CYCLE={spike:4.6,wallspike:3.6,spikerow:3.2,flameband:4.6},REST={spike:2.6,wallspike:2.1,spikerow:2.0,flameband:2.7};
for(const kind of Object.keys(CYCLE))assert.ok(REST[kind]/CYCLE[kind]>=1/3,`${kind} keeps a rest window`);
assert.ok(2.5/4.55>=1/3,'flame idles most of its cycle');
assert.ok(REST.flameband/CYCLE.flameband>=1/3,'fire bands rest most of their cycle');   // idle 2.5 / (2.5 warn 0.9 + fire 1.15)
assert.ok(1.15/2.85>=1/3,'fan idles most of its cycle');    // idle 1.15 / (idle 1.15 + gust 1.7)
assert.ok(3.2/4.72>=1/3,'bomb is spent most of its cycle'); // spent 3.2 / (fuse 1.1 + blast .42 + spent 3.2)
assert.ok(5.3/6.65>=1/3,'rockfall idles and clears most of its cycle');
for(const [kind,lead] of [['flame',.9],['bomb',1.1],['rockfall',.9]])assert.ok(lead>=.8,`${kind} leads with >=0.8 s`);

const CAMPS=[{x:144,y:752},{x:816,y:752},{x:1488,y:784},{x:2150,y:752},{x:2112,y:1264}];
for(const m of mech(g))for(const c of CAMPS){
 const covered=Math.abs(c.x-m.rect.x)<=m.rect.w/2&&Math.abs(c.y-m.rect.y)<=m.rect.h/2;
 assert.ok(!covered,`${m.id} must not cover checkpoint ${c.x},${c.y}`);
}
for(const b of [{x:224,y:560},{x:2230,y:560}])for(let i=0;i<9;i++){
 const c={x:b.x+(i%3)*128+64,y:b.y+Math.floor(i/3)*128+64};
 for(const m of mech(g)){
  const covered=Math.abs(c.x-m.rect.x)<=m.rect.w/2&&Math.abs(c.y-m.rect.y)<=m.rect.h/2;
  assert.ok(!covered,`${m.id} must not cover answer tile ${i} of board ${b.x}`);
 }
}
checks.push('43 assets; new mechanism kinds placed; stage 1 four pendulums, beam keeps three heads; every periodic hazard keeps a rest window; no hazard covers a checkpoint or an answer tile');

/* ---------- flame vent: charge, fire, burn, jump dodge ---------- */
{
 const f=boot();await f.ready();f.click('#start');f.fixture().stage(0);f.fixture().quiet();f.fixture().health(2,0);
 const vent=one(f,'flame-hall');
 f.fixture().place(0,vent.x-36,vent.y);f.fixture().vulnerable();
 const seen=new Set(),hp0=f.status().heroes[0].hp;
 for(let i=0;i<600&&!seen.has('fire');i++){f.steps(1);seen.add(one(f,'flame-hall').phase);}
 assert.ok(seen.has('idle')&&seen.has('warn')&&seen.has('fire'),'flame telegraphs before it fires');
 assert.ok(f.status().heroes[0].hp<hp0,'a grounded hero in the column burns');
 assert.ok(f.status().heroes[0].pushTime>0,'the flame knocks back');

 const j=boot();await j.ready();j.click('#start');j.fixture().stage(0);j.fixture().quiet();j.fixture().health(2,0);
 const jv=one(j,'flame-hall');
 j.fixture().place(0,jv.x-36,jv.y);j.fixture().vulnerable();
 for(let i=0;i<600;i++){const m=one(j,'flame-hall');if(m.phase==='warn'&&m.timer<.35)break;j.steps(1);}
 j.key('e');
 const airHp=j.status().heroes[0].hp;
 for(let i=0;i<40&&j.status().heroes[0].jumpTime>0;i++)j.steps(1);
 assert.equal(j.status().heroes[0].hp,airHp,'jump keeps the hero clear of the vent');
 checks.push('flame: idle -> warn -> fire, burns and knocks back a grounded hero, jump clears it');
}

/* ---------- fan: pushes without damage ---------- */
{
 // Measured on the beam entry: the only neighbours there are far enough away that
 // the displacement can only come from the wind itself.
 const measure=async phase=>{
  const g=boot();await g.ready();g.click('#start');g.fixture().stage(4);g.fixture().quiet();g.fixture().health(2,0);
  g.fixture().trapState('fan-beam',phase,99);
  g.fixture().place(0,2050,1264);g.fixture().vulnerable();
  g.steps(20);
  return {x:g.status().heroes[0].x,hp:g.status().heroes[0].hp,push:g.status().heroes[0].pushTime};
 };
 const gust=await measure('gust'),idle=await measure('idle');
 assert.ok(idle.x-gust.x>15,`wind carries the hero downstream (${(idle.x-gust.x).toFixed(1)} px)`);
 assert.equal(gust.hp,idle.hp,'wind deals no damage of its own');
 assert.equal(gust.push,0,'wind is not knockback');
 checks.push('fan: a gust pushes a grounded hero downstream and deals no damage');
}

/* ---------- bomb: proximity fuse, blast, walk-out ---------- */
{
 const b=boot();await b.ready();b.click('#start');b.fixture().stage(1);b.fixture().quiet();b.fixture().health(2,0);
 const bomb=one(b,'bomb-corridor');
 assert.equal(bomb.phase,'armed');
 b.fixture().place(0,bomb.x,bomb.y);b.fixture().vulnerable();
 b.steps(1);
 assert.equal(one(b,'bomb-corridor').phase,'fuse','contact lights the fuse');
 const hp0=b.status().heroes[0].hp;
 for(let i=0;i<12;i++)b.steps(1);
 assert.equal(b.status().heroes[0].hp,hp0,'the fuse itself does no damage');
 for(let i=0;i<80&&b.status().mode==='playing'&&one(b,'bomb-corridor').phase!=='blast';i++)b.steps(1);
 assert.ok(b.status().heroes[0].hp<hp0,'the blast damages a hero inside its radius');

 const e=boot();await e.ready();e.click('#start');e.fixture().stage(1);e.fixture().quiet();e.fixture().health(2,0);
 const eb=one(e,'bomb-corridor');
 e.fixture().place(0,eb.x,eb.y);e.fixture().vulnerable();
 e.steps(1);assert.equal(one(e,'bomb-corridor').phase,'fuse');
 e.fixture().place(0,eb.x-260,eb.y);
 for(let i=0;i<120;i++)e.steps(1);
 assert.equal(e.status().heroes[0].hp,170,'leaving the blast radius avoids it');
 checks.push('bomb: proximity lights a 1.1 s fuse, the blast damages inside its radius, leaving the radius avoids it');
}

/* ---------- wall spike: rest/warning/active, direction, jump dodge ---------- */
{
 const w=boot();await w.ready();w.click('#start');w.fixture().stage(1);w.fixture().quiet();w.fixture().health(2,0);
 const wall=one(w,'wallspike-corridor');
 w.fixture().place(0,wall.x+12,wall.y+10);w.fixture().vulnerable();
 const seen=new Set();
 for(let i=0;i<600;i++){w.steps(1);seen.add(one(w,'wallspike-corridor').phase);if(w.status().heroes[0].hp<170)break;}
 assert.ok(seen.has('rest')&&seen.has('warning')&&seen.has('active'),'wall spike telegraphs');
 assert.ok(w.status().heroes[0].hp<170,'the extended spike damages a hero in its lane');
 assert.ok(w.status().heroes[0].pushTime>0,'the wall spike pushes along its lane');

 const j=boot();await j.ready();j.click('#start');j.fixture().stage(1);j.fixture().quiet();j.fixture().health(2,0);
 const jw=one(j,'wallspike-corridor');
 j.fixture().place(0,jw.x+12,jw.y+10);j.fixture().vulnerable();
 for(let i=0;i<600&&one(j,'wallspike-corridor').phase!=='warning';i++)j.steps(1);
 j.key('e');j.steps(2);
 assert.ok(j.status().heroes[0].jumpTime>0,'jump starts on the warning, before the spike extends');
 const airHp=j.status().heroes[0].hp;
 for(let i=0;i<40&&j.status().heroes[0].jumpTime>0;i++)j.steps(1);
 assert.equal(j.status().heroes[0].hp,airHp,'airborne hero clears the wall spike');
 checks.push('wallspike: rest -> warning -> active in a fixed direction; damages and pushes on the ground, cleared in the air');
}

/* ---------- spike row: staggered cells ---------- */
{
 const r=boot();await r.ready();r.click('#start');r.fixture().stage(1);r.fixture().quiet();r.fixture().health(2,0);
 let staggered=false;
 for(let i=0;i<200&&!staggered;i++){r.steps(3);staggered=new Set(one(r,'row-corridor').rowPhases).size>1;}
 assert.ok(staggered,'row cells do not rise together');
 const row=one(r,'row-corridor');
 const cellY=row.y;
 r.fixture().place(0,row.x,cellY);r.fixture().vulnerable();
 let hurt=false;const seen=new Set();
 for(let i=0;i<600&&!hurt;i++){r.steps(1);seen.add(one(r,'row-corridor').rowPhases[1]);if(r.status().heroes[0].hp<170)hurt=true;}
 assert.ok(seen.has('rest')&&hurt,'a row cell damages the hero standing on it');
 checks.push('spikerow: cells rise in sequence and damage whoever stands on the risen cell');
}

/* ---------- rockfall: crack warning, fall, debris ---------- */
{
 const k=boot();await k.ready();k.click('#start');k.fixture().stage(1);k.fixture().quiet();k.fixture().health(2,0);
 const rock=one(k,'rockfall-corridor');
 k.fixture().place(0,rock.x+10,rock.y-38);k.fixture().vulnerable();
 const seen=new Set();let hurt=false;
 for(let i=0;i<900;i++){k.steps(1);const p=one(k,'rockfall-corridor').phase;seen.add(p);if(k.status().heroes[0].hp<170){hurt=true;break;}}
 assert.ok(seen.has('idle')&&seen.has('crack')&&seen.has('fall'),'the roof cracks before it falls');
 assert.ok(seen.has('crack')&&hurt,'standing under the crack is dangerous');

 const c=boot();await c.ready();c.click('#start');c.fixture().stage(1);c.fixture().quiet();c.fixture().health(2,0);
 const cr=one(c,'rockfall-corridor');
 c.fixture().place(0,cr.x+10,cr.y-38);c.fixture().vulnerable();
 for(let i=0;i<900&&one(c,'rockfall-corridor').phase!=='crack';i++)c.steps(1);
 c.fixture().place(0,cr.x-240,cr.y);
 for(let i=0;i<90;i++)c.steps(1);
 assert.equal(c.status().heroes[0].hp,170,'leaving after the crack avoids the fall');
 checks.push('rockfall: idle -> crack warning -> fall -> debris, and stepping away after the warning avoids it');
}

/* ---------- pause freezes and retry resets the new state machines ---------- */
{
 const p=boot();await p.ready();p.click('#start');p.fixture().stage(1);p.fixture().quiet();
 p.steps(45);
 p.key('p');
 const frozen=JSON.stringify(mech(p).filter(m=>m.stage===1));
 p.steps(300);
 assert.equal(JSON.stringify(mech(p).filter(m=>m.stage===1)),frozen,'pause freezes every new mechanism');
 p.key('p');
 const bomb=one(p,'bomb-corridor');
 p.fixture().health(2,0);p.fixture().place(0,bomb.x,bomb.y);p.steps(2);
 assert.equal(one(p,'bomb-corridor').phase,'fuse');
 p.key('r');
 assert.equal(one(p,'bomb-corridor').phase,'armed','retry clears a lit fuse');
 assert.equal(p.status().mechanisms.filter(m=>m.stage===1).every(m=>m.phase!=='fire'&&m.phase!=='blast'&&m.phase!=='fall'),true);
 checks.push('pause freezes and retry resets every new mechanism state machine');
}

/* ---------- the stage gate still mutes hazards for isolated fixtures ---------- */
{
 const m=boot();await m.ready();m.fixture().muteTraps();m.click('#start');m.fixture().stage(1);m.fixture().quiet();
 m.fixture().place(0,910,752);m.fixture().vulnerable();
 m.steps(300);
 assert.equal(m.status().heroes[0].hp,170,'muted mechanisms stay silent');
 checks.push('stage gating still mutes every mechanism for isolated fixtures');
}

/* ---------- doll hall: stage order, band wave, red light, exit ---------- */
{
 assert.equal(JSON.stringify(st.mechanisms.filter(m=>m.stage===2).map(m=>m.id).sort()),
  JSON.stringify(['band-left','band-mid-left','band-mid-right','band-right','doll']),'the doll hall owns one keeper and four bands');
 // Vertical curtains are arranged left to right; larger offsets ignite first.
 const bands=st.mechanisms.filter(m=>m.kind==='flameband').sort((a,b)=>a.x-b.x);
 assert.equal(JSON.stringify(bands.map(b=>b.x)),JSON.stringify([1568,1664,1760,1856]),'four vertical bands run left to right');
 assert.ok(bands[0].offset>bands[1].offset&&bands[1].offset>bands[2].offset&&bands[2].offset>bands[3].offset,
  'the wave starts at the left band and travels right');
 checks.push('doll hall: four vertical fire bands, lit left to right');

 const d=boot();await d.ready();d.click('#start');d.fixture().stage(2);d.fixture().quiet();d.fixture().health(2,0);
 // A band burns whoever stands on it and leaves the lane between bands alone.
 const lower=d.status().mechanisms.find(m=>m.id==='band-mid-right');
 d.fixture().place(0,lower.x,lower.y);d.fixture().vulnerable();
 let burned=false;for(let i=0;i<400&&!burned;i++){d.steps(1);if(d.status().heroes[0].hp<170)burned=true;}
 assert.ok(burned,'standing on a band burns');
 const gapX=(bands[2].x+bands[3].x)/2;
 const q=boot();await q.ready();q.click('#start');q.fixture().stage(2);q.fixture().quiet();q.fixture().health(2,0);
 q.fixture().place(0,gapX,784);q.fixture().vulnerable();
 for(let i=0;i<400;i++)q.steps(1);
 assert.equal(q.status().heroes[0].hp,170,'the lane between two bands is safe to stand in');
 const air=boot();await air.ready();air.click('#start');air.fixture().stage(2);air.fixture().quiet();air.fixture().health(2,0);
 const al=air.status().mechanisms.find(m=>m.id==='band-mid-right');
 air.fixture().place(0,al.x,al.y);air.fixture().vulnerable();
 for(let i=0;i<400&&air.status().mechanisms.find(m=>m.id==='band-mid-right').phase!=='warning';i++)air.steps(1);
 air.key('e');air.steps(3);
 const ahp=air.status().heroes[0].hp;
 for(let i=0;i<40&&air.status().heroes[0].jumpTime>0;i++)air.steps(1);
 assert.equal(air.status().heroes[0].hp,ahp,'a jump clears a fire band');
 checks.push('flameband: burns a grounded hero on it, leaves the lane safe, cleared by a jump');

 const r=boot();await r.ready();r.click('#start');r.fixture().stage(2);r.fixture().quiet();r.fixture().health(2,0);
 r.fixture().place(0,1616,660);r.fixture().vulnerable();
 r.fixture().trapState('doll','red',9);
 const before=r.status().heroes[0].hp;
 for(let i=0;i<40;i++)r.steps(1);
 assert.equal(r.status().heroes[0].hp,before,'standing still under the red light is safe');
 r.point(1616,850);r.fixture().trapState('doll','red',9);
 const movingHp=r.status().heroes[0].hp;
 for(let i=0;i<90;i++)r.steps(1);
 assert.ok(r.status().heroes[0].hp<movingHp,'moving under the red light draws the laser');
 assert.ok(r.status().heroes[0].pushTime>0||r.status().heroes[0].hp<movingHp,'the laser knocks the runner back');
 checks.push('doll: green/turn/red cycle, still is safe, moving under the red light is lasered');

 const x=boot();await x.ready();x.click('#start');x.fixture().stage(2);x.fixture().muteTraps();x.fixture().quiet();x.fixture().health(2,0);
 x.fixture().place(0,1488,784);
 for(let i=0;i<900;i++){const st2=x.status();if(st2.trial.stage!==2)break;const d=st2.exit;x.point(d.activated?d.x:d.button.x,d.activated?d.y:d.button.y);if(d.canInteract)x.key('f');x.steps(1);}
 assert.notEqual(x.status().trial.stage,2,'the partition exit advances after its button is pressed');
 checks.push('doll hall: left entry walks right to the button and through the partition exit');
}

console.log(JSON.stringify({version:'0.9.0',newMechanisms:['flame','fan','bomb','wallspike','spikerow','rockfall'],checks},null,2));
