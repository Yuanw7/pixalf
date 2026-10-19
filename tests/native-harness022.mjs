import fs from 'node:fs';import vm from 'node:vm';
export function boot({randomSeed=7}={}){
 const math=Object.create(Math);let seed=randomSeed;math.random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296};
 const context=vm.createContext({Math:math,console});vm.runInContext(fs.readFileSync('workshop/legacy_rules/rules.js','utf8'),context);
 context.window=vm.runInContext('window',context);
 const assets=JSON.parse(fs.readFileSync('workshop/legacy_rules/assets.json'));context.window.nativeBridge({op:'boot',map:'catacombs',assets});
 const held=new Set();let actions=[],pointer=null;
 return {async ready(){},choose(i){if(i!==0)throw Error('native modular protagonist uses base guardian stats')},click(){},key(k,up=false){if(up)held.delete(k);else{held.add(k);actions.push(k)}},point(x,y){const s=context.window.gameStatus();pointer=[x-s.camera.x,y-s.camera.y]},steps(n){for(let i=0;i<n;i++){context.window.nativeBridge({op:'step',dt:1/60,keys:[...held],actions,pointer});actions=[];pointer=null;}},status:()=>context.window.gameStatus()};
}
