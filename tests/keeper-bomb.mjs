import assert from 'node:assert/strict';
import {boot} from './harness.mjs';
const state=g=>g.status().mechanisms.find(m=>m.id==='doll');
async function setup(){const g=boot();await g.ready();g.click('#start');g.fixture().stage(2);g.fixture().quiet();g.fixture().health(2,0);return g;}
const g=await setup();
assert.equal(state(g).asset,'Monster01');
g.fixture().place(0,1808,784);g.steps(1);assert.notEqual(state(g).phase,'fuse','not triggered before endpoint');
g.fixture().place(0,1968,752);g.steps(1);assert.equal(state(g).phase,'fuse');assert.equal(state(g).timer,3.5);
g.key('p');g.steps(240);assert.equal(state(g).timer,3.5,'paused fuse freezes');g.key('p');
g.fixture().vulnerable();const hp=g.status().heroes[0].hp;g.steps(180);assert.equal(g.status().heroes[0].hp,hp,'warning precedes damage');g.steps(32);assert.equal(state(g).phase,'blast');assert.equal(g.status().heroes[0].hp,hp-80,'lingering takes real blast damage');
g.steps(40);assert.equal(state(g).phase,'spent');const once=g.status().heroes[0].hp;g.steps(180);assert.equal(g.status().heroes[0].hp,once,'one explosion only');
g.key('r');assert.equal(state(g).phase,'green');assert.equal(g.status().exit.activated,false,'retry resets fuse and door');
const safe=await setup();safe.fixture().place(0,1968,752);safe.steps(1);safe.fixture().place(0,1968,912);safe.fixture().vulnerable();safe.steps(240);assert.equal(safe.status().heroes[0].hp,170,'outside blast radius is safe');
const run=await setup();const d=run.status().exit;
run.fixture().place(0,1968,784);run.steps(1);assert.equal(state(run).phase,'fuse');
run.point(d.button.x,d.button.y);
for(let i=0;i<200&&run.status().trial.stage===2;i++){
 const s=run.status();if(s.exit.canInteract&&!s.exit.activated)run.key('f');
 if(s.exit.open)run.point(d.x,d.y);
 run.steps(1);
}
assert.equal(run.status().trial.stage,3,'ordinary movement and switch escape before explosion');
assert.equal(run.status().heroes[0].hp,170);assert.equal(state(run).phase,'green','new stage clears bomb');
// All doors fill a real wall opening; side walls stay solid after opening.
for(const stage of [0,1,2,3,4]){
 const a=await setup();a.fixture().stage(stage);a.fixture().muteTraps();a.fixture().quiet();a.fixture().health(2,0);const e=a.status().exit;
 assert.equal(e.barrier,128);assert.ok(e.wallTop<=e.y-64&&e.wallBottom>=e.y+64);
 if(e.wallTop===e.y-64)continue;
 const y=e.y-84,x=e.x-e.direction*38;
 a.fixture().place(0,x,y);a.key(e.direction===1?'d':'a');a.steps(20);a.key(e.direction===1?'d':'a',true);
 assert.ok(Math.abs(a.status().heroes[0].x-e.x)>=25,'wall beside panel blocks bypass');
}
console.log('Keeper: source monster, endpoint transformation, 3.5s warning, pause/retry, one real blast, safe radius, switch escape and wall geometry passed.');
