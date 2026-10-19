import assert from 'node:assert/strict';
import {boot} from './harness.mjs';
const checks=[];
function exit(g){const d=g.status().exit;g.fixture().place(g.status().selected,d.button.x,d.button.y);g.key('f');assert.equal(g.status().trial.exit.activated,true);g.steps(55);assert.equal(g.status().trial.open,true);g.fixture().place(g.status().selected,d.x,d.y);g.steps(1);}
const tickUntil=(g,p,max=1200)=>{for(let n=0;n<max&&!p(g.status());n++)g.steps(1);assert.ok(p(g.status()),'state not reached');};
const tile=(t,i)=>({x:(t.stage===3?2230:224)+i%3*128+64,y:560+Math.floor(i/3)*128+64});
function solve(g){tickUntil(g,s=>s.trial.phase==='question');let s=g.status(),p=tile(s.trial,s.trial.safe);g.fixture().place(s.selected,p.x,p.y);g.steps(181);assert.equal(g.status().trial.phase,'collapse');g.steps(92);}
const g=boot();await g.ready();g.fixture().muteTraps();
for(let i=0;i<3;i++){g.choose(i);g.click('#start');assert.equal(g.status().heroes.filter(h=>h.active&&h.hp>0).length,2);assert.equal(g.status().selected,i);g.key('1');assert.equal(g.status().selected,i);g.fixture().finish(true);g.click('#start');}
checks.push('exactly one selected player and one living companion, no in-run character switching');
g.choose(0);g.click('#start');g.fixture().quiet();g.fixture().place(0,680,752);g.key('d');g.key(' ');g.steps(30);g.key('d',true);assert.ok(g.status().heroes[0].x<704);assert.equal(g.status().trial.stage,0);
checks.push('first locked gate blocks walking and dash');
g.fixture().place(0,416,752);tickUntil(g,s=>s.trial.phase==='question');let s=g.status();const unique=new Set(s.trial.numbers);assert.equal(unique.size,9);assert.ok(unique.has(s.trial.answer));assert.equal(s.trial.timer,3);
g.key('p');const frozen=JSON.stringify(g.status().trial);g.steps(400);assert.equal(JSON.stringify(g.status().trial),frozen);g.key('p');
let wrong=tile(s.trial,(s.trial.safe+1)%9);g.fixture().place(0,wrong.x,wrong.y);g.steps(170);assert.equal(g.status().trial.phase,'question');g.steps(12);assert.equal(g.status().trial.phase,'falling');g.steps(50);assert.equal(g.status().mode,'lost');g.click('#start');assert.equal(g.status().trial.stage,0);assert.equal(g.status().trial.round,0);assert.equal(g.status().mode,'playing');
checks.push('unique answers; full three-second deadline; pause freezes; wrong tile falls with animation; retry resets current stage');
g.fixture().quiet();g.fixture().place(0,416,752);solve(g);assert.equal(g.status().trial.round,1);solve(g);assert.equal(g.status().trial.ready,true);assert.equal(g.status().trial.open,false);assert.equal(g.status().trial.round,2);
g.fixture().place(0,810,752);g.steps(1);assert.equal(g.status().trial.stage,0,'crossing old boundary does not clear a stage');exit(g);assert.equal(g.status().trial.stage,1);assert.equal(g.status().trial.checkpoint,1);
g.key('r');assert.equal(g.status().trial.stage,1);assert.equal(g.status().heroes[0].hp,170);g.fixture().quiet();
// Sweeping corridor must inflict real damage while waiting inside its sweep.
g.fixture().place(0,992,752);g.steps(180);assert.ok(g.status().heroes[0].hp<170);g.key('r');g.fixture().quiet();g.steps(9300);assert.equal(g.status().mode,'playing');assert.ok(g.status().time>150);
checks.push('two answers enable first button; corridor checkpoint retry; pendulum damages; dungeon never auto-wins at 150 seconds');
g.fixture().place(0,1364,752);g.steps(1);assert.equal(g.status().trial.stage,1);exit(g);assert.equal(g.status().trial.stage,2);g.fixture().quiet();g.fixture().endurance();
// Horizontal hall: reaching the keeper alone does not advance.
g.fixture().place(0,1980,784);g.steps(1);assert.equal(g.status().trial.stage,2);exit(g);assert.equal(g.status().trial.stage,3);
g.fixture().quiet();g.fixture().endurance();
g.fixture().place(0,2760,752);g.steps(30);assert.equal(g.status().mode,'playing','the trials exit cannot bypass the puzzle');
g.fixture().place(0,2300,752);solve(g);solve(g);solve(g);assert.equal(g.status().trial.ready,true);assert.equal(g.status().trial.open,false);assert.equal(g.status().mode,'playing');exit(g);assert.equal(g.status().trial.stage,4);assert.equal(g.status().mode,'playing');g.fixture().place(0,160,1264);g.steps(1);assert.equal(g.status().mode,'playing','final exit requires its own button');exit(g);assert.equal(g.status().mode,'won');assert.equal(JSON.parse(g.records['thornbound.trials.v3']).cleared,5);assert.equal(g.records['thornbound.v1'],'{"version":1,"best":24}');
checks.push('final three answers required, exit cannot bypass puzzle, trials exit advances to the beam checkpoint; final exit writes the five-stage campaign record');
const lava=boot();await lava.ready();lava.fixture().muteTraps();lava.click('#start');lava.fixture().quiet();lava.fixture().place(0,416,752);tickUntil(lava,s=>s.trial.phase==='question');s=lava.status();let safe=tile(s.trial,s.trial.safe);lava.fixture().place(0,safe.x,safe.y);lava.steps(181);assert.equal(lava.status().trial.phase,'collapse');lava.fixture().place(0,100,752);lava.steps(1);assert.equal(lava.status().trial.phase,'falling');checks.push('stepping off surviving tile during collapse also falls');
console.log(JSON.stringify({version:'0.9.0-doors',checks},null,2));
