import assert from 'node:assert/strict';
import {boot} from './harness.mjs';
async function opened(stage){const g=boot();await g.ready();g.click('#start');g.fixture().stage(stage);g.fixture().quiet();g.fixture().muteTraps();g.fixture().health(2,0);
 if(stage===0||stage===3){g.fixture().place(0,stage===3?2422:416,752);for(let n=0;n<(stage===3?3:2);n++){for(let i=0;i<600&&g.status().trial.phase!=='question';i++)g.steps(1);const t=g.status().trial;g.fixture().place(0,(stage===3?2230:224)+t.safe%3*128+64,560+Math.floor(t.safe/3)*128+64);g.steps(275);}}
 const d=g.status().exit;g.fixture().place(0,d.button.x,d.button.y);g.key('f');g.steps(55);assert.equal(g.status().exit.open,true);return g;}
for(const stage of [0,1,2,3,4])for(const offset of [-48,0,48])for(const action of ['walk','jump','dash']){
 const g=await opened(stage),d=g.status().exit;g.fixture().place(0,d.x-d.direction*40,d.y+offset);
 const key=d.direction===1?'d':'a';g.key(key);if(action==='jump')g.key('e');if(action==='dash')g.key(' ');g.steps(25);g.key(key,true);
 if(stage===4)assert.equal(g.status().mode,'won');else{assert.equal(g.status().trial.stage,stage+1,`${stage}/${offset}/${action}`);g.steps(60);assert.equal(g.status().trial.stage,stage+1,'only one transition');}
}
console.log('Door crossing: top/centre/bottom, both directions, walking/jump/dash, first-room puzzle and single transition passed.');
