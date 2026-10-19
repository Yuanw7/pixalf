import {boot} from './harness.mjs';
import assert from 'node:assert/strict';

// The bot reads only window.gameStatus() and issues normal input (keys plus
// ground clicks). No fixture teleports, no health edits, no muted traps: this is
// the evidence that a normal-stat player can clear every stage with its hazards.
const near=(a,r,pad)=>Math.abs(a.x-r.x)<r.w/2+pad&&Math.abs(a.y-r.y)<r.h/2+pad;

// Live hazard footprints for the current stage, straight from the read-only status.
function liveDanger(s){
  const out=[];
  for(const m of s.mechanisms){
    if(m.stage!==s.trial.stage)continue;
    if(m.kind==='fan')continue; // wind pushes without damage
    if(m.kind==='spikerow'){
      m.rowPhases.forEach((p,i)=>{if(p==='rest')return;const o=(i-(m.cells-1)/2)*32;out.push({x:m.dir==='v'?m.x:m.x+o,y:m.dir==='v'?m.y+o:m.y,w:34,h:34,telegraph:p==='warning'});});
      continue;
    }
    if(m.kind==='saw'){out.push({x:m.position.x,y:m.position.y,w:62,h:62,telegraph:false});continue;}
    if(m.kind==='bomb'){if(m.phase==='fuse')out.push({x:m.x,y:m.y,w:m.radius*2,h:m.radius*2,telegraph:true});continue;}
    if(m.kind==='rockfall'){if(m.phase==='crack')out.push({x:m.x,y:m.y,w:m.radius*2,h:m.radius*2,telegraph:true});continue;}
    if(m.phase!=='active'&&m.phase!=='warning')continue;
    out.push({x:m.rect.x,y:m.rect.y,w:m.rect.w,h:m.rect.h,telegraph:m.phase==='warning'});
  }
  return out;
}

const results=[];
for(const leader of [0,1,2]){
const g=boot({randomSeed:7+leader*47});await g.ready();g.choose(leader);g.click('#start');
let previous='',crossing=null;const visited=new Set(),attempts=[],buttons=new Set();
// The lava beam kills on a single knockback by design, so the run is allowed to
// use the checkpoint retry the game itself offers; every attempt is reported.
for(let run=0;run<4;run++){
previous='';crossing=null;
for(let i=0;i<24000&&g.status().mode==='playing';i++){
 const s=g.status(),t=s.trial,h=s.heroes[s.selected];visited.add(t.stage);if(t.exit.activated)buttons.add(t.stage);
 g.key('j');if(i%60===0)g.key('k');
 const command=`${t.stage}:${t.phase}:${t.round}:${t.safe}`;
 if(command!==previous||i%6===0){
  previous=command;
  if(t.stage===4)g.point(h.x>2016&&Math.abs(h.y-1264)>8?2128:224,1264);
  else if(t.stage===2){/* the doll hall is steered every frame below */}
  else if(t.stage===1)g.point(1365,752);
  else if(t.ready)g.point(s.exit.button.x,s.exit.button.y);
  else if(t.phase==='idle')g.point(t.stage===0?416:2300,752);
  else if(t.phase==='question'||t.phase==='collapse')g.point((t.stage===3?2230:224)+t.safe%3*128+64,560+Math.floor(t.safe/3)*128+64);
 }
 if(t.stage===4){
  if(crossing){g.point(crossing[0]-24,1264);if(h.x<crossing[0]&&h.jumpTime===0&&h.jumpCooldown===0)crossing=null;}
  else{
   const gap=s.beam.gaps.find(([a,b])=>h.x>=b+14&&h.x<=b+42);
   if(gap&&h.y>=1252&&h.y<=1276){if(h.jumpCooldown===0&&h.jumpTime===0){crossing=gap;g.point(gap[0]-24,1264);g.key('e');}else g.point(gap[1]+34,1264);}
  }
 }
 // With the jump on cooldown a swing cannot be cleared, so give ground along the
 // plank and take it once the jump is back, instead of walking into the head.
 if(t.stage===4&&!crossing&&h.jumpTime===0&&h.jumpCooldown>0){
  const near=s.hazards.find(p=>p.stage===4&&Math.hypot(h.x-p.x,h.y-p.y)<150);
  if(near)g.point(near.px,1264); // the column under the axle is the one place a head never crosses
 }
 // Beam discipline: an off-centre run never advances west, it re-centres first,
 // which is what keeps a shove on the landing recoverable instead of fatal.
 if(t.stage===4&&h.x>320&&!crossing&&Math.abs(h.y-1264)>8)g.point(h.x>2016?2128:(h.x<1980?2016:h.x),1264);
 // Horizontal doll hall: stop at red, cross the curtains on green.
 if(t.stage===2&&!t.exit.activated){
  const doll=s.mechanisms.find(m=>m.id==='doll');
  if(doll&&doll.phase==='red')g.point(h.x,h.y);
  else g.point(s.exit.button.x,s.exit.button.y);
 }
 // Reactions a player has, and the reason the run is a fair test: a closing swing
 // or bolt is jumped, a gap jump is never traded for one, and a lit fuse is
 // walked out of. While a tile puzzle is being answered the player must stay
 // grounded, because an airborne player forfeits its tile at the deadline.
 const live=liveDanger(s),canJump=h.jumpCooldown===0&&h.jumpTime===0;
 const answering=t.phase==='prepare'||t.phase==='question'||t.phase==='collapse';
 const gapAhead=t.stage===4&&s.beam.gaps.some(([a,b])=>h.x>b&&h.x<b+180);
 const swing=s.hazards.some(p=>p.stage===t.stage&&Math.hypot(h.x-p.x,h.y-p.y)<(t.stage===4?110:95));
 const bolt=(t.stage===1||t.stage===4)&&s.fireballs.some(b=>Math.hypot(h.x-b.x,h.y-b.y)<95&&(h.x-b.x)*b.dx+(h.y-b.y)*b.dy>0);
 const sprung=t.stage!==4&&live.some(r=>!r.telegraph&&near(h,r,24));
 if(!answering&&canJump&&!gapAhead&&(swing||bolt||sprung))g.key('e');
 // A tail below the plank line is walked back to the mouth before heading west.
 if(t.stage===4&&h.y>1258&&h.x>2016)g.point(224,1264);
 // A fuse that is already lit cannot be out-jumped from inside the blast: walk out.
 const fuse=live.find(r=>r.telegraph&&near(h,r,58));
 if(t.stage!==4&&!answering&&fuse&&!canJump){const dx=h.x>=fuse.x?1:-1,dy=h.y>=fuse.y?1:-1;g.point(h.x+dx*95,h.y+dy*75);}
 if(t.ready&&(t.stage!==4||h.x<300)&&(t.exit.activated||Math.hypot(h.x-s.exit.button.x,h.y-s.exit.button.y)<115)){
   if(t.exit.activated&&!t.open)g.point(h.x,h.y);else g.point(t.exit.activated?s.exit.x:s.exit.button.x,t.exit.activated?s.exit.y:s.exit.button.y);
   if(s.exit.canInteract&&!t.exit.activated){g.key('f');if(g.status().exit.activated)buttons.add(t.stage);}
 }
 g.steps(1);
}
if(g.status().mode==='won')break;
console.error('checkpoint retry',JSON.stringify({leader,attempt:run+1,stage:g.status().trial.stage+1,time:g.status().time}));
attempts.push(g.status().trial.stage+1);
assert.equal(g.status().mode,'lost','bot must not silently restart an unfinished run');g.click('#start');
}
const s=g.status();results.push({leader,scenario:'normal stats; attack/skill, click navigation and status-driven hazard reactions; no fixture teleports or health changes; checkpoint retry allowed (reported per leader)',mode:s.mode,time:s.time,trial:s.trial,health:s.heroes.filter(h=>h.active).map(h=>h.hp),spawns:s.spawnHistory.length,visited:[...visited],retries:attempts,buttons:[...buttons]});
if(s.mode!=='won')console.log(JSON.stringify({leader,trial:s.trial,heroes:s.heroes,time:s.time,mechanisms:s.mechanisms.filter(m=>m.stage===s.trial.stage)},null,2));
assert.equal(s.mode,'won');assert.equal(visited.size,5);assert.equal(buttons.size,5,'all five doors require actual button input');assert.ok(s.spawnHistory.length>10);
}
console.log(JSON.stringify(results,null,2));
