import assert from 'node:assert/strict';
import {boot} from './harness.mjs';
const bootStage=async stage=>{const g=boot();await g.ready();g.click('#start');g.fixture().stage(stage);g.fixture().muteTraps();g.fixture().quiet();g.fixture().health(2,0);return g;};
const nearButton=g=>{const d=g.status().exit;g.fixture().place(0,d.button.x,d.button.y);};
const g=await bootStage(2);
const door=g.status().exit;
assert.equal(g.status().trial.completed,2);
g.fixture().place(0,door.x,door.y);g.steps(2);
assert.equal(g.status().trial.stage,2,'standing in the door cannot auto-clear');
g.fixture().place(0,1488,784);g.key('f');assert.equal(g.status().exit.activated,false,'remote F does nothing');
g.point(door.button.x,door.button.y);assert.equal(g.status().exit.activated,false,'remote button click only walks toward it');
nearButton(g);g.key('e');g.key('f');assert.equal(g.status().exit.activated,false,'airborne button input rejected');
g.steps(60);nearButton(g);g.key('p');g.key('f');assert.equal(g.status().exit.activated,false,'paused input rejected');g.key('p');
nearButton(g);g.point(door.button.x,door.button.y);
assert.equal(g.status().exit.activated,true,'nearby pointer input presses button');
assert.equal(g.status().trial.completed,3,'button press marks stage complete');
assert.equal(g.status().trial.stage,2,'button does not teleport immediately');
assert.equal(g.status().exit.open,false);
g.fixture().place(0,door.x-34,door.y);g.key('d');g.steps(10);g.key('d',true);
assert.ok(g.status().heroes[0].x<door.x-24,'opening door still blocks movement');
g.key('f');const before=g.status().exit.progress;g.key('p');g.steps(90);assert.equal(g.status().exit.progress,before,'pause freezes opening');g.key('p');
g.steps(55);assert.equal(g.status().exit.open,true);assert.equal(g.status().trial.stage,2,'open door still requires entry');
g.point(door.x,door.y);for(let i=0;i<90&&g.status().trial.stage===2;i++)g.steps(1);
assert.equal(g.status().trial.stage,3);assert.ok(Math.hypot(g.status().heroes[0].x-2150,g.status().heroes[0].y-752)<5,'door arrives at next checkpoint');
assert.equal(g.status().exit.activated,false);
// Arithmetic objective remains a separate prerequisite for the explicit button.
for(const stage of [0,3]){const a=await bootStage(stage);nearButton(a);a.key('f');assert.equal(a.status().trial.ready,false);assert.equal(a.status().exit.activated,false);assert.equal(a.status().trial.completed,stage);}
// Each traversal stage uses the same contract; retry clears completion and animation.
for(const stage of [1,2,4]){
 const a=await bootStage(stage);nearButton(a);a.key('f');a.steps(20);assert.equal(a.status().exit.activated,true);
 a.key('r');assert.equal(a.status().exit.activated,false);assert.equal(a.status().exit.progress,0);assert.equal(a.status().trial.completed,stage);assert.equal(a.status().exit.open,false);
 nearButton(a);a.key('f');a.steps(55);const d=a.status().exit;a.fixture().place(0,d.x,d.y);a.steps(1);
 if(stage===4){assert.equal(a.status().mode,'won');assert.equal(JSON.parse(a.records['thornbound.trials.v3']).cleared,5);}
 else assert.equal(a.status().trial.stage,stage+1);
}
console.log('Doors: explicit nearby F/click, puzzle prerequisite, grounded/alive/playing checks, completion on press, animated collision, pause, actual entry, next checkpoint, retry and final victory passed.');
