let facing='south',actorClock=0,actorAction='idle',lastX=0,lastY=0;
const oldSprite=sprite;
sprite=function(h,asset){if(h.id!==selected){oldSprite(h,asset);return;}ctx.lpc(h,trial?.phase==='falling'?Math.max(.15,trial.fall/.8):1,jumpHeight(h),facing,actorClock);};
function nativeState(render=true){
 if(render){ctx.reset();draw();}
 return {commands:render?ctx.commands:[],mode,mapId,mapOpen,time,trial,heroes:heroes.map(h=>({...h})),selected,enemies:enemies.map(e=>({...e})),mechanisms:window.gameStatus().mechanisms,hazards:mapId==='catacombs'?pendulums():[],fireballs,kills,buffs,camera:{...camera},records:{...records},title:$('#overlayTitle').textContent,description:$('#overlayText').textContent,button:$('#start').textContent,status:$('#status').textContent,challenge:$('#challengeText').textContent};
}
window.nativeBridge=function(args){
 if(args.op==='boot'){
  for(const key of Object.keys(records))delete records[key];Object.assign(records,args.records||{});
  for(const [id,info] of Object.entries(args.assets)){images[id]={id,width:info[0],height:info[1]};}
  loaded=true;chosen=0;selected=0;chosenMap=args.map==='forest'?'forest':'catacombs';applyMap(chosenMap);start();
  actorClock=0;actorAction='idle';facing='south';lastX=heroes[0].x;lastY=heroes[0].y;
  return {...nativeState(args.render!==false),background:{id:background.id,commands:background.context.commands},design:{rooms:dungeonRooms,corridors:dungeonCorridors,mechanisms:mechanismSpecs,boards:boardOrigins,beam:{y:BEAM_Y,gaps:BEAM_GAPS,segments:BEAM_SEGMENTS},forest:forestLayout}};
 }
 if(args.op==='step'){
  keys.clear();for(const key of (args.keys||[]))keys.add(key);
  for(const key of (args.actions||[]))listeners.keydown({key,repeat:false,preventDefault:noop});
  if(args.pointer)listeners['canvas:pointerdown']({button:0,clientX:args.pointer[0],clientY:args.pointer[1]});
  const dt=Math.min(.034,Math.max(0,args.dt||0));if(mode==='playing')update(dt);
  const lead=heroes[selected],dx=lead.x-lastX,dy=lead.y-lastY;
  if(Math.hypot(dx,dy)>.05)facing=Math.abs(dx)>Math.abs(dy)?(dx>0?'east':'west'):(dy>0?'south':'north');lastX=lead.x;lastY=lead.y;
  const action=lead.hp<=0?'hurt':lead.attack>0?'attack':lead.moving?'walk':'idle';if(action!==actorAction){actorClock=0;actorAction=action;}else if(mode==='playing')actorClock+=dt;
 }
 if(args.op==='pause'&&mode==='playing')pause();
 if(args.op==='resume'&&mode==='paused')pause();
 if(args.op==='retry'&&mapId==='catacombs')retryTrial();
 if(args.op==='continue'){$('#start').onclick();if(mode==='ready')start();}
 return nativeState(args.render!==false);
};
