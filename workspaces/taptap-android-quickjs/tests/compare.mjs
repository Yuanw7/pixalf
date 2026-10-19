import fs from 'node:fs';import path from 'node:path';import vm from 'node:vm';import assert from 'node:assert/strict';import {spawnSync} from 'node:child_process';import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const assets=JSON.parse(fs.readFileSync(path.join(root,'game/legacy_rules/assets.json')));
const original=fs.readFileSync(path.join(root,'game/legacy_rules/rules.js'),'utf8');
const source='let testSeed=7;Math.random=()=>{testSeed=(Math.imul(testSeed,1664525)+1013904223)>>>0;return testSeed/4294967296};\n'+original.replace('window.nativeBridge=function(args){','window.nativeBridge=function(args){if(args.op==="test_stage"){trial=newTrial(args.stage);retryTrial();return nativeState(false)}');
let context;
const requests=[],expected=[];
function add(payload,boot=false){if(boot){context=vm.createContext({console});vm.runInContext(source,context);context.window=vm.runInContext("window",context);}requests.push({op:boot?'sim_boot':'sim_step',...(boot?{source}:{}),payload});expected.push(JSON.parse(JSON.stringify(context.window.nativeBridge(payload))));}
add({op:'boot',map:'catacombs',assets,render:false},true);
for(let stage=0;stage<4;stage++){
 add({op:'test_stage',stage});
 for(let i=0;i<300;i++)add({op:'step',dt:1/60,keys:i%180<90?['d','j']:['a','j'],actions:i%90===0?['e','k']:[],render:i%60===0});
}
add({op:'pause'});add({op:'step',dt:1/60,keys:['d'],render:false});add({op:'resume'});add({op:'retry'});
add({op:'boot',map:'forest',assets,render:false},true);
for(let i=0;i<60;i++)add({op:'step',dt:1/60,keys:['d','j'],render:false});
const run=spawnSync(path.join(root,'build/macos/runtime-cli'),{input:requests.map(v=>JSON.stringify(v)).join('\n')+'\n',encoding:'utf8',maxBuffer:128*1024*1024,timeout:60000});
assert.equal(run.status,0,run.stderr);const actual=run.stdout.trim().split('\n').map(JSON.parse);assert.equal(actual.length,expected.length);
function equal(a,b,p='root'){
 if(typeof a==='number'&&typeof b==='number'){assert.ok(Math.abs(a-b)<=1e-8*Math.max(1,Math.abs(b)),`${p}: ${a} != ${b}`);return;}
 if(a&&b&&typeof a==='object'&&typeof b==='object'){assert.deepEqual(Object.keys(a).sort(),Object.keys(b).sort(),p);for(const k of Object.keys(a))equal(a[k],b[k],p+'.'+k);return;}
 assert.equal(a,b,p);
}
for(let i=0;i<actual.length;i++)equal(actual[i],expected[i],'frame '+i);
const badRequests=['{',JSON.stringify({op:'sim_step',payload:{op:'state'}}),JSON.stringify({op:'sim_boot',source:'throw new Error("fixture failure")',payload:{}}),JSON.stringify({op:'sim_boot',source:original,payload:{op:'boot',map:'catacombs',assets,render:false}}),JSON.stringify({op:'sim_close'}),JSON.stringify({op:'sim_step',payload:{op:'state'}})];
const recovery=spawnSync(path.join(root,'build/macos/runtime-cli'),{input:badRequests.join('\n')+'\n',encoding:'utf8',maxBuffer:16*1024*1024});assert.equal(recovery.status,0,recovery.stderr);const answers=recovery.stdout.trim().split('\n').map(JSON.parse);
assert.ok(answers[0].error);assert.ok(answers[1].error);assert.match(answers[2].error,/fixture failure/);assert.equal(answers[3].mapId,'catacombs');assert.equal(answers[4].closed,true);assert.ok(answers[5].error);
const report={runtime:'QuickJS 2026-06-04',platform:process.platform,architecture:process.arch,comparedResponses:actual.length,numberTolerance:'relative 1e-8',cases:['4 stages / 1200 frames','LPC draw commands','pause/resume/retry','forest reboot / 60 frames','malformed JSON, failed boot, recovery, close'],result:'PASS',androidValidated:false};fs.writeFileSync(path.join(root,'reports/quickjs-comparison.json'),JSON.stringify(report,null,2)+'\n');console.log(report);
