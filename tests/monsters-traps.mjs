import assert from 'node:assert/strict';
import fs from 'node:fs';
import {boot} from './harness.mjs';
const assets=JSON.parse(fs.readFileSync('assets.js','utf8').slice(14,-1));
for(const n of ['00','01','02','03','09'])assert.ok(assets['Monster'+n]);
assert.equal(new Set(['00','01','02','03','09'].map(n=>assets['Monster'+n])).size,5);
assert.ok(!assets.WoodsBandit&&!assets.FireElemental&&!assets['Blood Monster_AIdle']);assert.ok(assets.Slime);
const g=boot();await g.ready();g.chooseMap('forest');g.click('#start');
for(const [t,expected]of [[0,['slime']],[6,['slime','scout']],[14,['slime','scout','wolf']],[22,['slime','scout','wolf','brute']],[30,['slime','scout','wolf','brute','treant']]]){
 g.fixture().spawnAt(t,15);assert.deepEqual([...new Set(g.status().enemies.map(e=>e.type))].sort(),expected.sort());assert.ok(g.status().spawnHistory.every(e=>e.x<0||e.x>2240||e.y<0||e.y>1440));
}
const pushes={};
for(const type of ['slime','scout','wolf','brute','treant']){g.fixture().quiet();g.fixture().health(2,0);g.fixture().place(0,1040,760);g.fixture().vulnerable();g.fixture().attackFrom(type,-30,0);g.steps(13);pushes[type]=g.status().heroes[0].x-1040;assert.ok(pushes[type]>35);}
assert.ok(pushes.brute>65&&pushes.treant>55&&pushes.wolf>48);
const early=g.fixture().pacing(0),late=g.fixture().pacing(90);assert.ok(late.batch>early.batch&&late.cap>early.cap&&late.interval<early.interval);
const q=boot();await q.ready();q.click('#start');q.fixture().stage(4);q.fixture().setTime(37);q.steps(1);assert.equal(q.status().enemies.filter(e=>e.type==='fire').length,0);q.fixture().setTime(38);q.steps(1);assert.equal(q.status().enemies.filter(e=>e.type==='fire').length,4);
// Real mechanisms with enemy spawning isolated; regular campaign tests cover their combination.
const a=boot();await a.ready();a.click('#start');a.fixture().stage(1);a.fixture().quiet();a.fixture().health(2,0);a.fixture().vulnerable();a.fixture().setTime(0);a.fixture().place(0,886,746);a.steps(1);assert.equal(a.status().heroes[0].hp,170);
a.fixture().setTime(3);a.steps(1);assert.ok(a.status().heroes[0].hp<170&&a.status().heroes[0].pushTime>0,'active spikes hurt and push');
a.key('r');a.fixture().quiet();a.fixture().health(2,0);a.fixture().vulnerable();a.key('e');a.steps(20);a.fixture().setTime(3);a.fixture().place(0,886,746);a.steps(1);assert.equal(a.status().heroes[0].hp,170,'airborne clears spikes');
a.key('r');a.fixture().quiet();a.fixture().health(2,0);a.fixture().vulnerable();a.fixture().setTime(0);a.fixture().place(0,1094,752);a.steps(1);assert.ok(a.status().heroes[0].hp<170,'saw hit');
a.key('r');a.fixture().quiet();a.fixture().health(2,0);a.fixture().vulnerable();a.fixture().place(0,1340,735);a.fixture().trapState('bow-corridor','solid',.01);a.steps(1);assert.ok(a.status().fireballs.some(b=>b.type==='arrow'));
a.key('p');const frozen=JSON.stringify(a.status().mechanisms);const bolts=JSON.stringify(a.status().fireballs);a.steps(120);assert.equal(JSON.stringify(a.status().mechanisms),frozen);assert.equal(JSON.stringify(a.status().fireballs),bolts);a.key('p');a.steps(40);assert.ok(a.status().heroes[0].hp<170,'arrow projectile hit');
a.fixture().stage(4);a.fixture().quiet();a.fixture().health(2,0);a.fixture().place(0,1696,1264);a.steps(1);assert.equal(a.status().mechanisms.find(t=>t.id==='crumble-east').phase,'cracking');a.steps(35);assert.notEqual(a.status().trial.phase,'falling');a.steps(10);assert.equal(a.status().trial.phase,'falling','standing on cracking plank drops into lava');
a.key('r');a.fixture().quiet();assert.equal(a.status().mechanisms.find(t=>t.id==='crumble-east').phase,'solid');assert.equal(a.status().fireballs.length,0);
a.fixture().trapState('crumble-east','down',.2);a.fixture().place(0,2112,1150);a.steps(15);assert.equal(a.status().mechanisms.find(t=>t.id==='crumble-east').phase,'solid');
console.log(JSON.stringify({actualPushPixels:pushes}));
console.log('Five distinct source sheets replace legacy enemies; slime retained; timed unlocks and growing pressure; lava demon late unlock; spike timing/airborne dodge, saw hits, moving arrows/pause, collapsing plank/fall/retry/restore verified.');
