import fs from 'node:fs';import vm from 'node:vm';import path from 'node:path';import assert from 'node:assert/strict';import {fileURLToPath} from 'node:url';import {spawnSync} from 'node:child_process';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const read=p=>fs.readFileSync(path.join(root,p),'utf8');
let original=read('game/legacy_rules/rules.js');const end=original.lastIndexOf('})();');
const source='let seed027=7;Math.random=()=>{seed027=(Math.imul(seed027,1664525)+1013904223)>>>0;return seed027/4294967296};\n'+original.slice(0,end)+read('game/combat_extension.js')+read('game/performance_extension.js')+read('game/appearance_extension.js')+read('game/test_fixtures/combat.js')+original.slice(end);
const context=vm.createContext({console});vm.runInContext(source,context);const bridge=vm.runInContext('window.nativeBridge',context);const requests=[],expected=[];let checks=0;
const check=(ok,label)=>{assert.ok(ok,label);checks++;};
function call(payload,boot=false){const result=JSON.parse(JSON.stringify(bridge(payload)));requests.push({op:boot?'sim_boot':'sim_step',...(boot?{source}:{}),payload});expected.push(result);return result;}
const step=(n=1,keys=[])=>{let s;for(let i=0;i<n;i++)s=call({op:'step',dt:1/60,keys,render:i===n-1});return s;};
call({op:'boot',map:'catacombs',assets:JSON.parse(read('game/legacy_rules/assets.json')),weapon:'kunai'},true);
let s=call({op:'fixture',weapon:'kunai'});let h=s.enemies[0].hp;
s=step(1,['j']);check(s.combat.shots.length===1&&s.enemies[0].hp===h,'shot is a travelling projectile, not instant damage');
check(s.combat.fx.some(e=>e.kind==='launch'),'launch FX');s=step(25);check(s.enemies[0].hp===h-s.heroes[0].damage,'one projectile deals damage once');check(s.combat.shots.length===0,'projectile consumed on hit');
s=step(1,['j']);s=step(25);check(s.kills===1&&s.combat.remains.length===1,'kill leaves one corpse');check(s.combat.fx.some(e=>e.kind==='hit'),'confirmed hit sparks');
call({op:'pause'});let age=s.combat.remains[0].age;s=step(30);check(s.combat.remains[0].age===age,'pause freezes corpse clocks');call({op:'resume'});
s=step(750);check(s.combat.remains.length===0,'remains expire after 12 seconds');
s=call({op:'fixture',weapon:'kunai',wall:true,distances:[140]});h=s.enemies[0].hp;step(1,['j']);s=step(20);check(s.enemies[0].hp===h&&s.combat.shots.length===0,'closed gate blocks projectile');
s=call({op:'fixture',weapon:'sword',distances:[60,180]});h=s.enemies[0].hp;s=step(1,['j']);check(s.enemies[0].hp<h&&s.enemies[1].hp===h,'melee only hurts within range');check(s.combat.fx.some(e=>e.kind==='slash'),'sword crescent');
s=call({op:'fixture',weapon:'spear',distances:[130,180]});h=s.enemies[0].hp;s=step(1,['j']);check(s.enemies[0].hp<h&&s.enemies[1].hp===h,'spear reach differs from sword');check(s.combat.fx.some(e=>e.kind==='thrust'),'spear line FX');
s=call({op:'fixture',weapon:'kunai',distances:[]});step(1,['j']);s=step(70);check(s.combat.shots.length===0,'unhit projectile expires');
call({op:'fixture',distances:[60,80,100]});s=call({op:'fixture_damage'});check(s.combat.remains.length===3,'multiple deaths retained');s=call({op:'fixture_damage'});check(s.combat.remains.length===3,'repeated damage cannot duplicate corpse');
s=call({op:'retry'});check(s.combat.remains.length===0&&s.combat.fx.length===0&&s.combat.shots.length===0,'retry clears combat state');
for(let i=0;i<45;i++){call({op:'fixture',distances:Array.from({length:50},(_,n)=>30+n)});s=call({op:'fixture_damage'});}
check(s.combat.remains.length===40&&s.combat.fx.length<=64,'bounded retained effects');
const run=spawnSync(path.join(root,'build/macos/runtime-cli'),{input:requests.map(v=>JSON.stringify(v)).join('\n')+'\n',encoding:'utf8',maxBuffer:128*1024*1024,timeout:60000});assert.equal(run.status,0,run.stderr);const actual=run.stdout.trim().split('\n').map(JSON.parse);assert.equal(actual.length,expected.length);
function equal(a,b,p='root'){if(typeof a==='number'&&typeof b==='number'){assert.ok(Math.abs(a-b)<=1e-8*Math.max(1,Math.abs(b)),p);return;}if(a&&b&&typeof a==='object'&&typeof b==='object'){assert.deepEqual(Object.keys(a).sort(),Object.keys(b).sort(),p);for(const k of Object.keys(a))equal(a[k],b[k],p+'.'+k);return;}assert.equal(a,b,p);}
for(let i=0;i<actual.length;i++)equal(actual[i],expected[i],'frame '+i);
const report={checks,comparedResponses:actual.length,result:'PASS'};fs.writeFileSync(path.join(root,'reports/combat-tests.json'),JSON.stringify(report,null,2)+'\n');console.log(report);
