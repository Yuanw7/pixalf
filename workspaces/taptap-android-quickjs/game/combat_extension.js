// Installed inside the classic rules closure. The archived 0.8 rules remain unchanged.
let combatWeapon='sword', combatFX=[], combatShots=[], combatRemains=[], combatSerial=0,skillImpact=0;
const combatWeapons={none:{range:65,cool:.45},sword:{range:90,cool:.55},axe:{range:105,cool:.7},spear:{range:145,cool:.6},kunai:{range:460,cool:.38}};
function combatReset(){combatFX=[];combatShots=[];combatRemains=[];skillImpact=0;}
function combatEffect(kind,x,y,angle=0,r=0){combatFX.push({kind,x,y,angle,r,age:0,life:kind==='hit'?.26:.24,id:++combatSerial});if(combatFX.length>64)combatFX.shift();}
function combatCorpse(e){
 if(e.combatDead)return;e.combatDead=true;
 combatRemains.push({x:e.x,y:e.y,asset:e.asset,type:e.type,face:e.face||1,age:0,life:12,id:++combatSerial});
 if(combatRemains.length>40)combatRemains.shift();
}
const combatOldDamage=damage;
damage=function(e,n,attacker=null){
 if(e.hp<=0)return;combatOldDamage(e,n,attacker);
 combatEffect('hit',e.x,e.y-22,attacker?Math.atan2(e.y-attacker.y,e.x-attacker.x):0);
 e.combatFlash=.08;
 if(e.hp<=0)combatCorpse(e);
};
const combatOldAttack=attack;
attack=function(h,target){
 if(h.id!==selected)return combatOldAttack(h,target);
 if(h.cool>0||h.hp<=0)return;
 const spec=combatWeapons[combatWeapon];
 // Choose a visible target only; a hidden nearest enemy must not steal aim.
 target=enemies.filter(e=>e.hp>0&&!e.entering&&dist(h,e)<=spec.range&&lineClear(h,e)).sort((a,b)=>dist(h,a)-dist(h,b))[0];
 const fallback={east:0,south:Math.PI/2,west:Math.PI,north:-Math.PI/2}[facing];
 const angle=target?Math.atan2(target.y-h.y,target.x-h.x):fallback;
 const dx=Math.cos(angle),dy=Math.sin(angle);
 facing=Math.abs(dx)>Math.abs(dy)?(dx>0?'east':'west'):(dy>0?'south':'north');
 h.combatFacing=facing;h.cool=spec.cool;h.attack=.32;actorClock=0;beep(combatWeapon==='kunai'?680:300,.04);
 if(combatWeapon==='kunai'){
  combatShots.push({x:h.x,y:h.y,dx,dy,age:0,left:460,speed:620,damage:h.damage,owner:h.id});
  combatEffect('launch',h.x+dx*20,h.y+dy*20-20,angle);return;
 }
 combatEffect(combatWeapon==='spear'?'thrust':'slash',h.x,h.y-18,angle,spec.range);
 for(const e of enemies){
  if(e.hp<=0||e.entering||dist(h,e)>spec.range||!lineClear(h,e))continue;
  const d=Math.max(1,dist(h,e)),dot=((e.x-h.x)*dx+(e.y-h.y)*dy)/d;
  if(combatWeapon==='spear'?dot>.9:dot>-.15)damage(e,h.damage,h);
 }
};
const combatOldUpdate=update;
// K retains the original radius, damage and cooldown. Replace the slow ring with a snap cut.
const combatOldSkill=skill;
skill=function(h){
 if(h.id!==selected)return combatOldSkill(h);
 if(h.hp<=0||h.skill>0)return;
 const target=nearest(h),r=h.id===2?210:145;
 const angle=target&&dist(h,target)<r&&lineClear(h,target)?Math.atan2(target.y-h.y,target.x-h.x):{east:0,south:Math.PI/2,west:Math.PI,north:-Math.PI/2}[facing];
 facing=Math.abs(Math.cos(angle))>Math.abs(Math.sin(angle))?(Math.cos(angle)>0?'east':'west'):(Math.sin(angle)>0?'south':'north');
 h.combatFacing=facing;h.skill=7;h.attack=.22;h.inv=.5;actorClock=0;
 combatEffect('skill',h.x,h.y-18,angle,r);
 let hits=0;
 for(const e of enemies){
  if(e.hp<=0||e.entering||dist(h,e)>=r||!lineClear(h,e))continue;
  damage(e,h.id===1?75:55,h);e.combatFlash=.09;hits++;
  combatEffect('skill_hit',e.x,e.y-20,angle,0);
 }
 if(hits){skillImpact++;shake=Math.max(shake,3);}
 beep(700,.07);
};
update=function(dt){
 const before=enemies.slice();combatOldUpdate(dt);
 for(const e of before){if(e.hp<=0)combatCorpse(e);e.combatFlash=Math.max(0,(e.combatFlash||0)-dt);}
 if(mode!=='playing'){combatShots=[];return;}
 for(const p of combatShots){
  p.age+=dt;
  const travel=Math.min(p.left,p.speed*dt),steps=Math.max(1,Math.ceil(travel/4));
  for(let i=0;i<steps&&p.left>0;i++){
   p.x+=p.dx*travel/steps;p.y+=p.dy*travel/steps;p.left-=travel/steps;
   if(blocked(p.x,p.y,3)){combatEffect('wall',p.x,p.y-20);p.left=0;break;}
   const hit=enemies.find(e=>e.hp>0&&!e.entering&&Math.hypot(p.x-e.x,p.y-e.y)<18);
   if(hit){damage(hit,p.damage,heroes[p.owner]);p.left=0;break;}
  }
 }
 combatShots=combatShots.filter(p=>p.left>.01);
 for(const list of [combatFX,combatRemains])for(const e of list)e.age+=dt;
 combatFX=combatFX.filter(e=>e.age<e.life);combatRemains=combatRemains.filter(e=>e.age<e.life);
};
// Insert floor remnants after the map but before live actors. Air FX precede the minimap.
const combatOldTrials=drawTrials;
drawTrials=function(){combatOldTrials();ctx.emit('combat_floor',[combatRemains.map(e=>({...e}))]);};
const combatOldDraw=draw;
draw=function(){
 combatOldDraw();if(mapOpen||mapId==='catacombs')return;
 const index=ctx.commands.findIndex(c=>c[0]==='image'&&c[4]===background.id);
 if(index>=0)ctx.commands.splice(index+1,0,['combat_floor',ctx.commands[index][1].slice(),1,'#ffffff',combatRemains.map(e=>({...e})),null]);
};
const combatOldMinimap=minimap;
minimap=function(){
 if(!mapOpen){ctx.save();ctx.translate(-camera.x,-camera.y);ctx.emit('combat_air',[combatFX.map(e=>({...e})),combatShots.map(e=>({...e}))]);ctx.restore();}
 combatOldMinimap();
};
const combatOldSprite=sprite;
sprite=function(h,asset){
 combatOldSprite(h,asset);
 if(h.combatFlash>0&&h.hp>0){ctx.save();ctx.globalAlpha=h.combatFlash/.08*.8;ctx.fillStyle='#fff6da';ctx.fillRect(h.x-10,h.y-32,20,22);ctx.restore();}
};
const combatOldRetry=retryTrial;
retryTrial=function(){combatReset();combatOldRetry();};
const combatOldStart=start;
start=function(){combatReset();combatOldStart();};
const combatOldBridge=window.nativeBridge;
window.nativeBridge=function(args){
 if(args.weapon&&combatWeapons[args.weapon])combatWeapon=args.weapon;
 if(args.op==='boot')combatReset();
 const result=combatOldBridge(args);
 const lead=heroes[selected];if(lead?.attack>0&&lead.combatFacing)facing=lead.combatFacing;
 // Rendering in nativeBridge already happened; keep the LPC pose aligned with the hit.
 if(lead?.attack>0&&lead.combatFacing)for(const c of result.commands)if(c[0]==='lpc')c[12]=lead.combatFacing;
 return {...result,combat:{weapon:combatWeapon,skillImpact,shots:combatShots.map(p=>({...p})),fx:combatFX.map(e=>({...e})),remains:combatRemains.map(e=>({...e}))}};
};
