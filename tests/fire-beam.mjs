import assert from 'node:assert/strict';
import {boot} from './harness.mjs';
const g=boot();await g.ready();g.fixture().muteTraps();g.click('#start');g.fixture().stage(4);g.fixture().quiet();
assert.equal(g.status().beam.right-g.status().beam.left,1696);assert.equal(g.status().beam.gaps.length,3);assert.equal(g.status().lavaFlowSpeed,1.5);
for(const [a,b] of g.status().beam.gaps){
 g.key('r');g.fixture().quiet();g.fixture().place(0,b+30,1264);g.key('e');g.key('a');g.steps(55);g.key('a',true);assert.equal(g.status().mode,'playing');assert.equal(g.status().heroes[0].jumpTime,0);assert.ok(g.status().heroes[0].x<a);
 g.key('r');g.fixture().quiet();g.fixture().place(0,b+5,1264);g.key('a');g.steps(5);g.key('a',true);assert.equal(g.status().trial.phase,'falling');
}
// Isolate fireball travel and hit at a safe landing: a real enemy windup fires it.
g.key('r');g.fixture().quiet();g.fixture().vulnerable();g.fixture().place(0,2112,1264);g.fixture().place(2,2140,1320);g.fixture().attackFrom('fire',-100,-48);g.steps(1);assert.equal(g.status().fireballs.length,1);assert.equal(g.status().heroes[0].hp,170);assert.ok(g.status().enemies[0].hp>0,'fire floats above lava');
g.key('p');const frozen=JSON.stringify(g.status().fireballs);g.steps(30);assert.equal(JSON.stringify(g.status().fireballs),frozen);g.key('p');g.steps(75);assert.ok(g.status().heroes[0].hp<170);assert.ok(g.status().heroes[0].x>2147,'fireball produces directional knockback');assert.equal(g.status().fireballs.length,0);
g.key('r');assert.equal(g.status().fireballs.length,0);assert.equal(g.status().heroes[0].pushTime,0);
// Jump clears an incoming bolt. It travels on, not an unavoidable targeted damage tick.
g.fixture().quiet();g.fixture().vulnerable();g.fixture().place(0,2112,1264);g.fixture().place(2,2140,1320);g.fixture().attackFrom('fire',-100,-48);g.steps(1);g.key('e');g.steps(46);assert.equal(g.status().heroes[0].hp,170);assert.equal(g.status().heroes[0].pushTime,0);
// A grounded rotating hammer starts an impulse, which can push the player off the beam.
g.key('r');g.fixture().quiet();g.fixture().vulnerable();g.fixture().setTime(0);g.fixture().place(0,904,1264);g.steps(1);assert.ok(g.status().heroes[0].pushTime>0);g.steps(15);assert.equal(g.status().trial.phase,'falling');
// Fire residents emerge inside the lava rather than walking in from outside.
g.fixture().setTime(40);g.key('r');g.fixture().place(0,2112,1264);g.steps(250);assert.ok(g.status().spawnHistory.some(e=>e.type==='fire'&&e.side==='lava'));
console.log('Extended beam: 1696 px, three gaps each jumpable and lethal on foot; fire flies, fires travelling bolts, damages/pushes, pause/retry clears/freeze; airborne dodge; hammer knockback can cause lava fall; fire spawns inside lava.');
