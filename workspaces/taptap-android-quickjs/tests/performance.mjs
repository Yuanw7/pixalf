import fs from 'node:fs';import vm from 'node:vm';import path from 'node:path';import assert from 'node:assert/strict';import {fileURLToPath} from 'node:url';import {spawnSync} from 'node:child_process';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'),read=p=>fs.readFileSync(path.join(root,p),'utf8');
const original=read('game/legacy_rules/rules.js'),end=original.lastIndexOf('})();');
const seed='let seed028=7;Math.random=()=>{seed028=(Math.imul(seed028,1664525)+1013904223)>>>0;return seed028/4294967296};\n';
const fixture=`
const verifyBridge=window.nativeBridge;
window.nativeBridge=function(args){
 if(args.op==='verify_recorder'){
  ctx.reset();ctx.beginPath();ctx.ellipse(10,20,17,7,.4,-.7,2.6);ctx.fill();ctx.stroke();
  ctx.beginPath();ctx.ellipse(0,0,12,12,0,0,7);ctx.lineTo(99,42);ctx.fill();
  ctx.beginPath();ctx.moveTo(4,8);ctx.ellipse(0,0,24,10,0,0,7);ctx.stroke();
  ctx.beginPath();ctx.ellipse(0,0,24,10,0,0,7);ctx.ellipse(10,20,5,3,.5,0,7);ctx.fill();
  ctx.beginPath();ctx.ellipse(1,2,5,6,0,0,7);ctx.rect(10,20,30,40);ctx.stroke();
  return {commands:ctx.commands};
 }
 if(args.op==='verify_geometry'){
  trial=newTrial(args.stage);trial.open=args.open;let count=0;
  function check(x,y,r){
   if(dungeonFloor(x,y,r)!==referenceFloor(x,y,r))throw Error('floor mismatch '+[x,y,r]);
   // Reference blocked resolves the new floor globally; floor equality is checked separately.
   if(blocked(x,y,r)!==referenceBlocked(x,y,r))throw Error('blocked mismatch '+[x,y,r]);count++;
  }
  for(let x=0;x<=2240;x+=32)for(let y=0;y<=1440;y+=32)for(const r of [0,3,8,13,16,32,65])check(x,y,r);
  for(const x of [20,64,704,720,768,1424,1472,2080,2176,2220])for(const y of [20,512,608,680,704,752,832,928,992,1040,1120,1264,1376,1420])for(const d of [-.001,0,.001])for(const r of [3,13,16])check(x+d,y+d,r);
  return {checked:count};
 }
 if(args.op==='verify_stage'){trial=newTrial(args.stage);retryTrial();time=180;for(const h of heroes)h.inv=1e6;return verifyBridge({op:'state'});}
 if(args.op==='verify_history'){for(let i=0;i<10000;i++)spawnHistory.push({type:'scout',x:64,y:752,time:i,side:'west',station:null});return verifyBridge({op:'state'});}
 return verifyBridge(args);
};
`;
const makeSource=optimized=>seed+original.slice(0,end)+read('game/combat_extension.js')+'\nconst referenceFloor=dungeonFloor,referenceBlocked=blocked;\n'+(optimized?read('game/performance_extension.js'):'')+fixture+original.slice(end);
const before=makeSource(false),after=makeSource(true);
const make=s=>{const c=vm.createContext({});vm.runInContext(s,c);return vm.runInContext('window.nativeBridge',c);};
let bridges=[make(before),make(after)],requests=[],expected=[],geometry=0,frames=0;
function expand(c){if(!Array.isArray(c)||c[0]!=='ellipse')return c;const [x,y,rx,ry,r,a,b]=c.slice(4,11),span=Math.min(Math.PI*2,b-a),count=Math.max(8,Math.ceil(Math.abs(span)*8)),points=[];for(let i=0;i<=count;i++){const t=a+span*i/count,dx=Math.cos(t)*rx,dy=Math.sin(t)*ry;points.push([x+dx*Math.cos(r)-dy*Math.sin(r),y+dx*Math.sin(r)+dy*Math.cos(r)]);}return ['poly',c[1],c[2],c[3],points,c[11],c[12],c.at(-1)];}
function equal(a,b,p='root'){a=expand(a);b=expand(b);if(typeof a==='number'&&typeof b==='number'){assert.ok(Math.abs(a-b)<=1e-8*Math.max(1,Math.abs(b)),p+': '+a+' != '+b);return;}if(a&&b&&typeof a==='object'&&typeof b==='object'){assert.deepEqual(Object.keys(a).sort(),Object.keys(b).sort(),p);for(const k of Object.keys(a))equal(a[k],b[k],p+'.'+k);return;}assert.equal(a,b,p);}
function call(payload,boot=false){if(boot)bridges=[make(before),make(after)];const results=bridges.map(f=>JSON.parse(JSON.stringify(f(payload))));equal(...results);frames++;requests.push({op:boot?'sim_boot':'sim_step',...(boot?{source:after}:{}),payload});expected.push(results[1]);return results[1];}
const assets=JSON.parse(read('game/legacy_rules/assets.json'));
call({op:'boot',map:'catacombs',assets,records:{},weapon:'kunai'},true);
call({op:'verify_recorder'});
for(let stage=0;stage<4;stage++)for(const open of [false,true])geometry+=call({op:'verify_geometry',stage,open}).checked;
for(let stage=0;stage<4;stage++){
 call({op:'verify_stage',stage});
 for(let i=0;i<240;i++)call({op:'step',dt:1/60,keys:i%120<60?['a','j']:['d','j'],actions:i%75===0?['e','k']:[],render:i%30===0});
 call({op:'pause'});call({op:'step',dt:.016,keys:['d']});call({op:'resume'});
}
call({op:'verify_history'});call({op:'step',dt:.016,keys:['j']});call({op:'retry'});
call({op:'boot',map:'forest',assets,records:{},weapon:'spear'},true);
for(let i=0;i<180;i++)call({op:'step',dt:1/60,keys:['d','j'],render:i%30===0});
const run=spawnSync(path.join(root,'build/macos/runtime-cli'),{input:requests.map(v=>JSON.stringify(v)).join('\n')+'\n',encoding:'utf8',maxBuffer:128*1024*1024,timeout:60000});assert.equal(run.status,0,run.stderr);const native=run.stdout.trim().split('\n').map(JSON.parse);assert.equal(native.length,expected.length);for(let i=0;i<native.length;i++)equal(native[i],expected[i],'native frame '+i);
const result={result:'PASS',geometryComparisons:geometry,baselineVsOptimizedResponses:frames,quickjsVsNodeResponses:native.length};fs.writeFileSync(path.join(root,'reports/028/equivalence.json'),JSON.stringify(result,null,2)+'\n');console.log(result);
