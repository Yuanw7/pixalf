import assert from 'node:assert/strict';
import {boot} from './harness.mjs';
for(const leader of [0,1,2]){
 const g=boot();await g.ready();g.choose(leader);g.chooseMap('forest');g.click('#start');g.fixture().quiet();
 const mate=(leader+2)%3,base=[28,38,24],skills=[55,75,55];
 assert.equal(g.fixture().strike(leader),base[leader]);assert.equal(g.fixture().strike(mate),Math.round(base[mate]*.5));
 assert.equal(g.fixture().strike(leader,true),skills[leader]);assert.equal(g.fixture().strike(mate,true),Math.round(skills[mate]*.5));
}
const g=boot();await g.ready();g.chooseMap('forest');g.click('#start');g.fixture().quiet();g.fixture().place(0,1040,760);g.fixture().place(2,1050,760);
const hp=g.status().heroes[0].hp;g.steps(1);assert.equal(g.status().heroes[0].x,1034);assert.equal(g.status().heroes[0].hp,hp);g.steps(10);assert.equal(g.status().heroes[0].x,1034,'not every frame');
g.key('p');const frozen=JSON.stringify(g.status().heroes);g.steps(100);assert.equal(JSON.stringify(g.status().heroes),frozen);g.key('p');g.steps(50);g.fixture().place(0,1456,900);g.fixture().place(2,1440,900);g.steps(50);assert.ok(g.status().heroes[0].x<1460,'contact cannot push through river');
const l=boot();await l.ready();l.fixture().muteTraps();l.fixture().setTime(40);l.click('#start');l.fixture().setTime(40);l.fixture().stage(4);l.fixture().place(0,2112,1264);l.fixture().health(2,0);
let fires=l.status().enemies.filter(e=>e.type==='fire');assert.equal(fires.length,4);const starts=fires.map(e=>({...e}));let boltCount=0,shotFrames=0,moved=false;
for(let i=0;i<600;i++){
 l.fixture().health(0,170);l.fixture().place(0,2112,1264);l.steps(1);
 for(const e of l.status().enemies.filter(e=>e.type==='fire')){
  assert.ok(e.x>320&&e.x<2016&&Math.abs(e.y-1264)>12,'resident remains in lava');assert.ok(Math.abs(e.x-e.home.x)<=16.001&&Math.abs(e.y-e.home.y)<=8.001,'only a small patrol');
  if(Math.abs(e.x-starts[e.habitat].x)>2)moved=true;
 }
 if(l.status().fireballs.some(b=>b.life>2.36))shotFrames++;
 boltCount=Math.max(boltCount,l.status().fireballs.length);
}
assert.ok(moved);assert.ok(boltCount>0&&shotFrames>=4,'resident repeatedly shoots toward a player on shore');
l.fixture().removeFire(0);l.steps(1);assert.ok(!l.status().enemies.some(e=>e.habitat===0));
// Pause freezes the respawn deadline and lava residents too.
l.key('p');const frozenFire=JSON.stringify(l.status().enemies);l.steps(600);assert.equal(JSON.stringify(l.status().enemies),frozenFire);l.key('p');
l.fixture().place(0,2112,752);l.steps(60);assert.ok(!l.status().enemies.some(e=>e.habitat===0));l.steps(430);assert.ok(l.status().enemies.some(e=>e.habitat===0&&e.hp>0),'resident regenerates after eight seconds');l.key('r');assert.equal(l.status().enemies.filter(e=>e.type==='fire').length,4);assert.equal(l.status().fireballs.length,0);assert.equal(l.status().heroes[0].allyBump,0);
console.log('Companion: all three roles deal 50% as AI and full damage as leader; normal/skill damage, 6px gentle no-damage contact, cooldown/pause/wall collision. Fire: four lava homes, small continuous patrol, ranged fire, kill/respawn reset and pause.');
