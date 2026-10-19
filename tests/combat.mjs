import assert from 'node:assert/strict';
import {boot} from './harness.mjs';
const g=boot();await g.ready();g.chooseMap('forest');g.choose(0);g.click('#start');g.fixture().quiet();
assert.equal(g.status().assets,43);assert.equal(g.status().heroes.filter(h=>h.active).length,2);assert.ok(g.map().gates.every(p=>p.reachable));assert.ok(g.map().landmarks.every(p=>p.reachable));
const sites=g.status().pickups;assert.equal(new Set(sites.map(s=>s.region)).size,6);for(const a of sites)for(const b of sites)if(a!==b)assert.ok(Math.hypot(a.x-b.x,a.y-b.y)>=400);
for(const type of ['power','speed','health']){const p=sites.find(p=>p.type===type);g.fixture().place(0,p.x,p.y);if(type==='health')g.fixture().health(0,80);g.steps(1);if(type==='power')assert.equal(g.status().heroes[0].damage,45);if(type==='speed')assert.equal(g.status().heroes[0].speed,261);if(type==='health')assert.equal(g.status().heroes[0].hp,135);}
g.key('p');const buffs=JSON.stringify(g.status().buffs);g.steps(240);assert.equal(JSON.stringify(g.status().buffs),buffs);g.key('p');g.fixture().place(0,1040,760);g.steps(1500);assert.equal(g.status().buffs.power,0);assert.equal(g.status().buffs.speed,0);assert.ok(g.status().pickups.every(p=>p.available));
g.fixture().place(0,1540,1042);g.key('s');g.steps(90);g.key(' ');g.key('s',true);assert.ok(g.status().heroes[0].y<1086);
const save=boot({saved:'broken',denyWrite:true});await save.ready();save.chooseMap('forest');save.click('#start');save.fixture().finish(false);save.click('#start');assert.equal(save.status().mode,'ready');save.chooseMap('catacombs');save.click('#start');save.fixture().finish(true);assert.equal(save.status().mode,'won');
console.log('Forest regression: two characters, six separated reachable potion regions, effects/expiry/pause/respawn, river collision, damaged/denied storage recovery passed.');
