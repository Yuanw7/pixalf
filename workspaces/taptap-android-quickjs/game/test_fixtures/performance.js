// Benchmark-only setup and counters; not included in normal play.
let perfTimes={},perfCalls={};
function perfWrap(name,fn){return function(...args){const t=Date.now();const result=fn(...args);perfTimes[name]=(perfTimes[name]||0)+Date.now()-t;perfCalls[name]=(perfCalls[name]||0)+1;return result;};}
buildFlow=perfWrap('buildFlow',buildFlow);navigate=perfWrap('navigate',navigate);updateMechanisms=perfWrap('mechanisms',updateMechanisms);updateTrial=perfWrap('trial',updateTrial);drawTrials=perfWrap('drawTrials',drawTrials);draw=perfWrap('draw',draw);update=perfWrap('update',update);
const perfBridge=window.nativeBridge;
window.nativeBridge=function(args){
 if(args.op==='perf_setup'){
  trial=newTrial(args.stage??3);retryTrial();time=args.time??180;
  const lead=heroes[selected];lead.x=args.x??1100;lead.y=trial.stage===3?BEAM_Y:752;lead.inv=1e6;
  for(const h of heroes)if(h.active&&h.id!==selected){h.x=lead.x+28;h.y=lead.y;h.inv=1e6;}
  enemies=[];
  for(let i=0;i<(args.count??4);i++)enemies.push({...enemySpecs[i<4?'fire':'scout'],type:i<4?'fire':'scout',x:i<4?FIRE_SITES[i].x:800+i%12*24,y:i<4?FIRE_SITES[i].y:752,home:i<4?{...FIRE_SITES[i]}:null,habitat:i<4?i:undefined,maxHp:44,cool:999,attack:0,windup:0,anim:0,face:1,moving:false,entering:false,station:null,guardSlot:0});
  if(args.visible)for(let i=4;i<enemies.length;i++){enemies[i].x=360+i%14*12;enemies[i].y=BEAM_Y;enemies[i].hp=10000;enemies[i].maxHp=10000;}
  spawnClock=args.spawning?0:1e6;guardClock=1e6;flowTimer=0;perfTimes={};perfCalls={};
  return perfBridge({op:'state'});
 }
 if(args.op==='perf_stats')return {times:perfTimes,calls:perfCalls,enemies:enemies.length,particles:particles.length,spawnHistory:spawnHistory.length,fx:combatFX.length,remains:combatRemains.length};
 return perfBridge(args);
};
