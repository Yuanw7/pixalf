// Test-only fixture. Loaded by tests/capture, never by a normal game boot.
const fixtureBridge=window.nativeBridge;
window.nativeBridge=function(args){
 if(args.op==='fixture'){
  combatReset();mode='playing';spawnClock=9999;guardClock=9999;time=0;kills=0;effects=[];fireballs=[];particles.length=0;
  for(const h of heroes){h.active=h.id===selected;h.hp=h.active?h.maxHp:0;h.cool=0;h.attack=0;h.inv=9999;h.combatFacing=null;}
  if(args.weapon)combatWeapon=args.weapon;
  let origin;
  for(let y=96;y<600&&!origin;y+=16)for(let x=96;x<650&&!origin;x+=16){
   if(!blocked(x,y,18)&&lineClear({x,y},{x:x+320,y})&& !blocked(x+320,y,18))origin={x,y};
  }
  if(!origin)throw Error('No fixture lane');
  const h=heroes[selected];Object.assign(h,origin);lastX=h.x;lastY=h.y;facing='east';
  if(args.wall){
   // Put the actor on the east bank of the actual stage-0 gate.
   h.x=660;h.y=768;lastX=h.x;lastY=h.y;origin={x:h.x,y:h.y};
   if(blocked(h.x,h.y,13)||blocked(h.x+140,h.y,13))throw Error('Invalid wall fixture');
  }
  enemies=(args.distances||[180]).map((d,i)=>({...enemySpecs.scout,type:'scout',x:origin.x+d,y:origin.y,home:{x:origin.x+d,y:origin.y},hp:args.hp||44,maxHp:args.hp||44,speed:0,cool:9999,attack:0,windup:0,anim:0,face:-1,moving:false,entering:false,station:null,guardSlot:i}));
  return fixtureBridge({op:'state'});
 }
 if(args.op==='fixture_damage'){
  for(const e of enemies)damage(e,args.amount||999,heroes[selected]);return fixtureBridge({op:'state'});
 }
 return fixtureBridge(args);
};
