import vm from 'node:vm';import fs from 'node:fs';import assert from 'node:assert/strict';
const adapter=fs.readFileSync('scripts/legacy/adapter.js','utf8'),source=fs.readFileSync(fs.existsSync('builds/0.8.0/game/index.js')?'builds/0.8.0/game/index.js':'workshop/demo080/index.js','utf8'),generated=fs.readFileSync('workshop/legacy_rules/rules.js','utf8');
const assets=JSON.parse(fs.readFileSync('workshop/legacy_rules/assets.json'));
function engine(original=false,seed=7){
 const math=Object.create(Math);math.random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296};
 const context=vm.createContext({Math:math,console});
 if(original){
  vm.runInContext(adapter,context);
  vm.runInContext(`window.ASSETS=${JSON.stringify(Object.fromEntries(Object.keys(assets).map(k=>[k,k])))};const imageSizes=${JSON.stringify(assets)};class Image{set src(id){this.id=id;this.width=imageSizes[id][0];this.height=imageSizes[id][1];this.onload()}};`,context);
  const fixture=`window.testAPI={start(){start();draw()},step(args){keys.clear();for(const k of args.keys||[])keys.add(k);for(const key of args.actions||[])listeners.keydown({key,repeat:false,preventDefault:noop});if(args.pointer)listeners['canvas:pointerdown']({button:0,clientX:args.pointer[0],clientY:args.pointer[1]});if(mode==='playing')update(args.dt);draw()},stage(n){trial=newTrial(n);retryTrial()},snapshot(){return {mode,time,trial,heroes,enemies,fireballs,mechanismState}}};`;
  vm.runInContext(source.replace('window.gameStatus =',fixture+'window.gameStatus ='),context);
 }else vm.runInContext(generated.replace('window.nativeBridge=function(args){',`window.testAPI={stage(n){trial=newTrial(n);retryTrial()},snapshot(){return {mode,time,trial,heroes,enemies,fireballs,mechanismState}}};window.nativeBridge=function(args){`),context);
 context.window=vm.runInContext('window',context);
 return {context,boot:()=>vm.runInContext(`window.nativeBridge(${JSON.stringify({op:'boot',assets,map:'catacombs'})})`,context),run:a=>context.window.nativeBridge(a),status:()=>JSON.parse(JSON.stringify(context.window.gameStatus())),snapshot:()=>JSON.parse(JSON.stringify(context.window.testAPI.snapshot()))};
}
const old=engine(true),next=engine();await new Promise(r=>setImmediate(r));old.context.window.testAPI.start();next.boot();
let checks=0;
for(let stage=0;stage<4;stage++){
 old.context.window.testAPI.stage(stage);next.context.window.testAPI.stage(stage);
 for(let i=0;i<300;i++){
  const a={op:'step',dt:1/60,keys:i%180<90?['d','j']:['a','j'],actions:i%90===0?['e','k']:[]};
  old.context.window.testAPI.step(a);next.run(a);
  assert.deepEqual(next.snapshot(),old.snapshot(),`old rules equal at stage ${stage}, frame ${i}`);checks++;
 }
}
for(const name of ['dungeonFloor','blocked','move','updateMechanisms','updateTrial','newTrial','pendulums','jump','hurt','damage','attack','skill','advanceTrial','retryTrial','schedule','spawn','update']){
 const begin=source.indexOf('function '+name+'('),end=source.indexOf('\nfunction ',begin+1);const fn=source.slice(begin,end<0?source.length:end);
 assert.ok(generated.includes(fn),name+' unchanged');checks++;
}
const frame=next.run({op:'state'});assert.ok(frame.commands.some(c=>c[0]==='lpc'));assert.equal(frame.design,undefined);checks++;
console.log(`${checks} checks PASS: 1200 frames of original/new rule state identical; original gameplay functions unchanged; LPC draw command present.`);
