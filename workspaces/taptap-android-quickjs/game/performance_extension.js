// 028: allocation-free hot collision queries. Geometry and gameplay stay unchanged.
// The archived rules remain intact; this extension is installed after combat_extension.
const perfFloorRects=[...dungeonRooms,...dungeonCorridors].map(q=>[q.x,q.y,q.x+q.w,q.y+q.h]);
function floorPoint(x,y){
 for(let i=0;i<perfFloorRects.length;i++){
  const r=perfFloorRects[i];if(x>=r[0]&&x<r[2]&&y>=r[1]&&y<r[3])return true;
 }
 return false;
}
dungeonFloor=function(x,y,r=0){
 return floorPoint(x-r,y-r)&&floorPoint(x+r,y-r)&&floorPoint(x-r,y+r)&&floorPoint(x+r,y+r);
};
const perfOldBlocked=blocked;
blocked=function(x,y,radius=13){
 if(mapId!=='catacombs'||radius>65)return perfOldBlocked(x,y,radius);
 if(x<20||y<20||x>WORLD_W-20||y>WORLD_H-20||!dungeonFloor(x,y,radius))return true;
 if(trial){
  if(trial.stage===0&&!trial.open&&Math.abs(x-720)<radius+16)return true;
  if(trial.stage<2&&Math.abs(x-1424)<radius+16)return true;
  if(trial.stage<3&&x>2080&&Math.abs(y-1040)<radius+12)return true;
 }
 // The classic dungeon has two pillars. Avoid building nine bucket keys and
 // a temporary obstacle array for every sample along every enemy sightline.
 for(let i=0;i<obstacles.length;i++){
  const o=obstacles[i];if(Math.hypot(o.x-x,o.y-y)<o.radius+radius)return true;
 }
 return false;
};
nearest=function(h){
 let best,minimum=Infinity;
 for(let i=0;i<enemies.length;i++){
  const e=enemies[i];if(e.hp<=0||e.entering)continue;
  const distance=dist(h,e);if(distance<minimum){minimum=distance;best=e;}
 }
 return best;
};
// The old nativeState asks gameStatus() for mechanisms, which also copies the
// entire lifetime spawn history and every enemy, only to discard those copies.
// Keep diagnostics available on demand, but assemble the live response directly.
nativeState=function(render=true){
 if(render){ctx.reset();draw();}
 return {commands:render?ctx.commands:[],mode,mapId,mapOpen,time,trial,
  heroes:heroes.map(h=>({...h})),selected,enemies:enemies.map(e=>({...e})),
  mechanisms:mechanismSpecs.map(t=>({...t,...mechanismState[t.id],phase:mechPhase(t),rect:mechRect(t),rowPhases:t.kind==='spikerow'?Array.from({length:t.cells},(_,i)=>rowPhase(t,i)):null,position:t.kind==='saw'?sawPosition(t):{x:t.x,y:t.y}})),
  hazards:mapId==='catacombs'?pendulums():[],fireballs,kills,buffs,camera:{...camera},records:{...records},
  title:$('#overlayTitle').textContent,description:$('#overlayText').textContent,button:$('#start').textContent,status:$('#status').textContent,challenge:$('#challengeText').textContent};
};
// Preserve the recorder's exact 8-samples/radian polygon, but send its ellipse
// parameters instead of hundreds of numeric coordinates per visible enemy.
const perfRecorder=Recorder.prototype;
const perfBeginPath=perfRecorder.beginPath,perfEllipse=perfRecorder.ellipse;
function expandPendingEllipse(recorder){
 if(!recorder.pendingEllipse)return;
 const parameters=recorder.pendingEllipse;recorder.pendingEllipse=null;perfEllipse.apply(recorder,parameters);
}
perfRecorder.beginPath=function(){this.pendingEllipse=null;perfBeginPath.call(this);};
perfRecorder.ellipse=function(...parameters){
 if(!this.path.length&&!this.pendingEllipse){this.pendingEllipse=parameters;return;}
 expandPendingEllipse(this);perfEllipse.apply(this,parameters);
};
for(const operation of ['moveTo','lineTo','rect']){
 const original=perfRecorder[operation];perfRecorder[operation]=function(...args){expandPendingEllipse(this);return original.apply(this,args);};
}
for(const operation of ['fill','stroke']){
 const original=perfRecorder[operation];perfRecorder[operation]=function(){
  if(!this.pendingEllipse)return original.call(this);
  this.emit('ellipse',[...this.pendingEllipse,operation==='fill',operation==='fill'?0:this.lineWidth],operation==='fill'?this.fillStyle:this.strokeStyle);
 };
}
