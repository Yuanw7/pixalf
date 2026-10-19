'use strict';
(() => {
const $ = s => document.querySelector(s);
const canvas = $('#game'), ctx = canvas.getContext('2d');
ctx.imageSmoothingEnabled = false;
const VIEW_W = 960, VIEW_H = 600, WORLD_W = 2240, WORLD_H = 1440, CELL = 32;
const COLS = WORLD_W / CELL, ROWS = WORLD_H / CELL, DAWN = 150;
const mapNames = { forest: '低语森林', catacombs: '烛火地宫' };
let chosenMap = 'catacombs', mapId = 'forest';
let trial = null;
let fireballs = [];
const COMPANION_DAMAGE=.5;
let fireRespawnAt=[0,0,0,0];
const LAVA_FLOW_SPEED=1.5; // world pixels / second; no rapid color cycling
const trialNames = ['算术熔岩厅','摆锤长廊','熔火试炼','熔岩独木桥'];
const boardOrigins = [{x:224,y:560},{x:1600,y:560}];
let failureReason = '';
const buffs = { power: 0, speed: 0 }, particles = [], pickupHistory = [], tintedSheets = {};
let guardClock = 3, trailClock = 0;
const keys = new Set(), images = {}, camera = { x: 0, y: 0 };
const specs = [
  { name: '艾尔 · 守卫', asset: 'Soldier', role: '剑盾先锋', ability: '回旋斩', description: '攻守平衡，近身守护伙伴', color: '#d9c78b', hp: 170, damage: 28, range: 78, speed: 180 },
  { name: '格鲁 · 战斧', asset: 'Orc', role: '兽人战士', ability: '震地猛击', description: '生命充沛，战斧横扫林地', color: '#a9ce7b', hp: 215, damage: 38, range: 75, speed: 165 },
  { name: '烬 · 焰灵', asset: 'Demon_A', role: '恶魔游侠', ability: '烈焰新星', description: '灵活迅捷，以火焰远程迎敌', color: '#dc9281', hp: 135, damage: 24, range: 195, speed: 205 }
];
const enemySpecs = {
  slime: { asset:'Slime', name:'溪地史莱姆', hp:38, damage:7, speed:74, range:34, cooldown:1.6, push:380, color:'#81c6d9' },
  scout: { asset:'Monster03', name:'骨面斥候', hp:44, damage:8, speed:118, range:36, cooldown:1.5, push:420, color:'#bbcb85' },
  wolf: { asset:'Monster00', name:'铁甲兽', hp:72, damage:11, speed:96, range:44, cooldown:1.7, push:480, color:'#a1b8bf' },
  brute: { asset:'Monster02', name:'沼泽巨怪', hp:110, damage:14, speed:62, range:48, cooldown:2.2, push:650, color:'#a1bf59' },
  treant: { asset:'Monster01', name:'枯木守卫', hp:95, damage:12, speed:78, range:50, cooldown:2, push:560, color:'#b49b73' },
  fire: { asset:'Monster09', name:'熔岩炎魔', hp:60, damage:12, speed:24, range:330, cooldown:3.4, push:500, color:'#ffad3b', flying:true }
};
const ENEMY_UNLOCKS=[['slime',0],['scout',6],['wolf',14],['brute',22],['treant',30],['fire',38]];
// Large packs keep their pressure through numbers while individual hits allow a response.
for(const enemy of Object.values(enemySpecs))enemy.damage=Math.max(4,Math.round(enemy.damage*.75));
const lootSpecs = {
  health: { name: '血药', asset: 'potionHealth', color: '#ff779a', duration: 0 },
  power: { name: '武力', asset: 'potionPower', color: '#ffb65d', duration: 18 },
  speed: { name: '速度', asset: 'potionSpeed', color: '#7ce7b4', duration: 16 }
};
let heroes = [], enemies = [], effects = [], texts = [], spawnHistory = [];
let selected = 0, chosen = 0, mode = 'ready', time = 0, kills = 0, spawnClock = 2, serial = 0;
let shake = 0, sound = false, audio, loaded = false, best = 0, saveError = '';
let mapOpen = false, moveTarget = null, moveFlow = null;
let flow = null, flowTimer = 0, flowCell = -1, background;
const dist = (a, b) => Math.hypot(a.x - b.x, a.y - b.y);
const clamp = (n, a, b) => Math.max(a, Math.min(b, n));
const clockText = t => `${Math.floor(t / 60)}:${String(Math.floor(t % 60)).padStart(2, '0')}`;
// v1 kill records are retained untouched; v2 stores survival duration separately.
try {
  const record = JSON.parse(localStorage.getItem('thornbound.v2') || 'null');
  if (record?.version === 2 && Number.isFinite(record.bestSeconds) && record.bestSeconds >= 0) best = record.bestSeconds;
} catch { saveError = '战绩无法读取，本局仍可游玩。'; }
$('#best').textContent = best ? clockText(best) : '尚无记录';

// Stable terrain seed: map and collision share the same world coordinates.
let seed = 83921;
function terrainRandom() { seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0; return seed / 4294967296; }
const camp = { x: 1040, y: 760 };
const bridges = [{ x: 1432, y: 330, w: 224, h: 112 }, { x: 1432, y: 986, w: 224, h: 112 }];
const gates = [
  { x: 400, y: -70, tx: 400, ty: 100, side: 'north' },
  { x: WORLD_W + 70, y: 700, tx: WORLD_W - 100, ty: 700, side: 'east' },
  { x: 900, y: WORLD_H + 70, tx: 900, ty: WORLD_H - 100, side: 'south' },
  { x: -70, y: 600, tx: 100, ty: 600, side: 'west' }
];
const pathSegments = [
  [400, 0, 400, 400], [400, 400, 1040, 760], [0, 600, 600, 600], [600, 600, 1040, 760],
  [900, 1440, 900, 1050], [900, 1050, 1040, 760], [1040, 760, 1300, 760],
  [1300, 760, 1360, 385], [1360, 385, 1900, 385], [1300, 760, 1360, 1042],
  [1360, 1042, 1900, 1042], [1900, 385, 1940, 700], [1900, 1042, 1940, 700],
  [1940, 700, 2240, 700], [400, 400, 950, 320], [950, 320, 1360, 385], [600, 600, 420, 1080], [420, 1080, 900, 1050]
];
function segmentDistance(x, y, p) {
  const [ax, ay, bx, by] = p, dx = bx - ax, dy = by - ay;
  const t = clamp(((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy), 0, 1);
  return Math.hypot(x - ax - t * dx, y - ay - t * dy);
}
function isPath(x, y) { return pathSegments.some(p => segmentDistance(x, y, p) < 48); }
function isWater(x, y, padding = 0) {
  if (mapId === 'catacombs') return false;
  return x > 1472 - padding && x < 1616 + padding && !bridges.some(b => y > b.y + padding && y < b.y + b.h - padding);
}
const trees = [], rocks = [], walls = [], herbs = [];
const dungeonRooms = [
  {x:64,y:512,w:640,h:480}, {x:768,y:608,w:640,h:320}, {x:1472,y:512,w:704,h:480}, {x:64,y:1120,w:2112,h:256}
];
const dungeonCorridors = [{x:0,y:704,w:2240,h:128},{x:2080,y:928,w:96,h:336}];
const BEAM_Y=1264, BEAM_LEFT=320, BEAM_RIGHT=2016, BEAM_EXIT=160, JUMP_DURATION=.9;
const BEAM_GAPS=[[560,640],[992,1080],[1456,1552]];
const FIRE_SITES=[{x:1908,y:1168},{x:1380,y:1336},{x:1040,y:1192},{x:440,y:1336}];
const BEAM_SEGMENTS=[[320,560],[640,992],[1080,1456],[1552,2016]];
// Mechanism frame contracts, all uncropped sheets from the Trap and Weapon pack:
// TrapFireBox 16x32 x13, TrapFire 16x16 x4, TrapFan 32x16 x8, TrapBomb 32x32 x5,
// TrapRock 32x32 x12, TrapBrick 32x32 x8, TrapSpikes 32x32 x10,
// TrapWall = three pieces: 4-way (0,0,32,32), vertical (32,0,16,32), horizontal (48,0,32,16).
const mechanismSpecs=[
  // Stage 0 - arithmetic hall: hazards ring the answer board, never on a tile.
  {id:'spike-entry',kind:'spike',stage:0,x:650,y:852,w:56,h:56,offset:0},
  {id:'flame-hall',kind:'flame',stage:0,x:686,y:768,dir:'w',length:74,offset:.4},
  {id:'row-hall',kind:'spikerow',stage:0,x:736,y:752,dir:'v',cells:3,offset:.8},
  {id:'bomb-hall',kind:'bomb',stage:0,x:656,y:592,radius:74,offset:0},
  {id:'wallspike-hall',kind:'wallspike',stage:0,x:646,y:918,dir:'w',reach:44,offset:1.4},
  // Stage 1 - pendulum corridor: sweep plus wind, bombs and ceiling collapse.
  {id:'spike-corridor-a',kind:'spike',stage:1,x:886,y:746,w:64,h:72,offset:.4},
  {id:'spike-corridor-b',kind:'spike',stage:1,x:1278,y:748,w:64,h:72,offset:2.4},
  {id:'saw-corridor',kind:'saw',stage:1,x:1094,y:752,travel:94,offset:0},
  {id:'bow-corridor',kind:'bow',stage:1,x:1340,y:628,dx:0,dy:1,period:3.4,offset:1.1},
  {id:'bomb-corridor',kind:'bomb',stage:1,x:910,y:752,radius:74,offset:.6},
  {id:'rockfall-corridor',kind:'rockfall',stage:1,x:1032,y:790,radius:46,offset:.9},
  {id:'wallspike-corridor',kind:'wallspike',stage:1,x:1140,y:690,dir:'s',reach:54,offset:.2},
  {id:'row-corridor',kind:'spikerow',stage:1,x:1170,y:752,dir:'v',cells:3,offset:1.1},
  {id:'fan-corridor',kind:'fan',stage:1,x:1252,y:752,dir:'w',length:168,offset:.3},
  // Stage 2 - molten trials: flame vents and collapsing roof around the board.
  {id:'spike-final',kind:'spike',stage:2,x:1536,y:848,w:56,h:56,offset:1.6},
  {id:'bow-final',kind:'bow',stage:2,x:2048,y:540,dx:0,dy:1,period:3.1,offset:.4},
  {id:'bomb-trials',kind:'bomb',stage:2,x:1380,y:752,radius:74,offset:.5},
  {id:'row-trials',kind:'spikerow',stage:2,x:1452,y:752,dir:'v',cells:3,offset:.4},
  {id:'wallspike-trials',kind:'wallspike',stage:2,x:1490,y:690,dir:'s',reach:54,offset:.7},
  {id:'rockfall-gate',kind:'rockfall',stage:2,x:1380,y:800,radius:46,offset:1.8},
  {id:'rockfall-trials',kind:'rockfall',stage:2,x:2088,y:700,radius:44,offset:.9},
  {id:'flame-trials-a',kind:'flame',stage:2,x:1568,y:620,dir:'e',length:46,offset:0},
  {id:'flame-trials-b',kind:'flame',stage:2,x:1568,y:884,dir:'e',length:46,offset:1.5},
  // Stage 3 - lava beam. Plank x and head phases stay as in 0.7.0 on purpose: a
  // miss on this plank is already instantly lethal, so this pass adds a third
  // plank, a bomb and a wind vent rather than more heads.
  {id:'saw-stairs',kind:'saw',stage:3,x:2108,y:1204,travel:36,offset:1.5},
  {id:'crumble-east',kind:'crumble',stage:3,x:1696,y:BEAM_Y,w:56,h:24},
  {id:'crumble-mid',kind:'crumble',stage:3,x:1410,y:BEAM_Y,w:56,h:24},
  {id:'crumble-west',kind:'crumble',stage:3,x:704,y:BEAM_Y,w:56,h:24},
  {id:'bomb-beam',kind:'bomb',stage:3,x:1600,y:BEAM_Y,radius:58,offset:.4},
  {id:'fan-beam',kind:'fan',stage:3,x:2080,y:BEAM_Y,dir:'w',length:90,offset:.2}
];
// Telegraph contract: every periodic hazard must spend at least a third of its
// cycle resting, so a visible warning always precedes damage.
const CYCLE={spike:4.6,wallspike:3.6,spikerow:3.2};
const REST={spike:2.6,wallspike:2.1,spikerow:2.0};
let mechanismState={};
function resetMechanisms(){mechanismState=Object.fromEntries(mechanismSpecs.map(t=>[t.id,{timer:t.kind==='bow'?t.offset+1:(t.offset??0),phase:t.kind==='bomb'?'armed':['flame','fan','rockfall'].includes(t.kind)?'idle':'solid'}]));}
resetMechanisms();
function spikePhase(t){const c=(time+t.offset)%CYCLE.spike;return c<REST.spike?'rest':c<REST.spike+.7?'warning':'active';}
function wallPhase(t){const c=(time+t.offset)%CYCLE.wallspike;return c<REST.wallspike?'rest':c<REST.wallspike+.5?'warning':'active';}
function rowPhase(t,i){const c=(time+t.offset+i*.26)%CYCLE.spikerow;return c<REST.spikerow?'rest':c<REST.spikerow+.4?'warning':'active';}
function sawPosition(t){return {x:t.x,y:t.y+Math.sin(time*1.25+t.offset)*t.travel,vx:0,vy:Math.cos(time*1.25+t.offset)*t.travel*1.25};}
function dirVector(dir){return dir==='e'?[1,0]:dir==='w'?[-1,0]:dir==='s'?[0,1]:[0,-1];}
function onPlate(h,t){return Math.abs(h.x-t.x)<=t.w/2&&Math.abs(h.y-t.y)<=t.h/2;}
function inRect(h,r){return Math.abs(h.x-r.x)<=r.w/2&&Math.abs(h.y-r.y)<=r.h/2;}
function flameRect(t){const [dx,dy]=dirVector(t.dir),x=t.x+dx*t.length/2,y=t.y+dy*t.length/2;return {x,y,w:dx?t.length:26,h:dy?t.length:26};}
function fanRect(t){const [dx,dy]=dirVector(t.dir),x=t.x+dx*t.length/2,y=t.y+dy*t.length/2;return {x,y,w:dx?t.length:86,h:dy?t.length:86};}
function spikeRect(t){const [dx,dy]=dirVector(t.dir),r=t.reach;return {x:t.x+dx*r/2,y:t.y+dy*r/2,w:dx?r:30,h:dy?r:30};}
function rowCell(t,i){const o=(i-(t.cells-1)/2)*32;return t.dir==='v'?{x:t.x,y:t.y+o}:{x:t.x+o,y:t.y};}
function mechRect(t){
  if(t.kind==='flame')return flameRect(t);
  if(t.kind==='fan')return fanRect(t);
  if(t.kind==='wallspike')return spikeRect(t);
  if(t.kind==='spike'||t.kind==='crumble')return {x:t.x,y:t.y,w:t.w,h:t.h};
  if(t.kind==='bomb'||t.kind==='rockfall')return {x:t.x,y:t.y,w:(t.radius??60)*2,h:(t.radius??60)*2};
  if(t.kind==='spikerow'){const a=rowCell(t,0),b=rowCell(t,t.cells-1);return {x:(a.x+b.x)/2,y:(a.y+b.y)/2,w:t.dir==='h'?(Math.abs(b.x-a.x)+32):32,h:t.dir==='v'?(Math.abs(b.y-a.y)+32):32};}
  return {x:t.x,y:t.y,w:32,h:32};
}
function mechPhase(t){
  if(t.kind==='spike')return spikePhase(t);
  if(t.kind==='wallspike')return wallPhase(t);
  if(t.kind==='spikerow')return rowPhase(t,0);
  return mechanismState[t.id]?.phase??'solid';
}
function collapsedBridge(x,y){return mechanismSpecs.some(t=>t.kind==='crumble'&&mechanismState[t.id].phase==='down'&&onPlate({x,y},t));}
// All hazard damage funnels through hurt(), so invulnerability and the jump
// dodge stay in one place and mechanisms never bypass them.
function trapHurt(t,h,n,r,push,note,dx,dy){
  if(!h.active||h.hp<=0||jumpHeight(h)>=20||!inRect(h,r))return false;
  const hit=hurt(h,n,{type:t.kind,x:t.x,y:t.y,dx,dy,push});
  if(hit&&h.id===selected){shake=Math.max(shake,4);if(note)$('#status').textContent=note;}
  return hit;
}
function trapEnemies(t,r,n,key){
  for(const e of enemies)if(!e.entering&&e.hp>0&&inRect(e,r)&&time-(e[key]??-10)>.7){damage(e,n);e[key]=time;}
}
function updateMechanisms(dt){
  if(mapId!=='catacombs'||trial.phase==='falling')return;
  for(const t of mechanismSpecs){
    if(t.stage!==trial.stage)continue;
    const state=mechanismState[t.id];
    if(t.kind==='crumble'){
      if(state.phase==='solid'&&heroes.some(h=>h.active&&h.hp>0&&h.jumpTime<=0&&onPlate(h,t))){state.phase='cracking';state.timer=.7;}
      else if(state.phase!=='solid'){state.timer-=dt;if(state.timer<=0){state.phase=state.phase==='cracking'?'down':'solid';state.timer=state.phase==='down'?3.5:0;}}
      continue;
    }
    if(t.kind==='bow'){
      state.timer-=dt;if(state.timer<=0){state.timer=t.period;fireballs.push({type:'arrow',x:t.x,y:t.y+18,dx:t.dx*210,dy:t.dy*210,life:2.3,damage:12,push:420});beep(340,.06);}
      continue;
    }
    if(t.kind==='spike'){
      if(spikePhase(t)==='active'){const r={x:t.x,y:t.y,w:t.w,h:t.h};for(const h of heroes)trapHurt(t,h,12,r,320,'地刺升起！等待收回，或跳跃通过。');trapEnemies(t,r,18,'lastSpike');}
      continue;
    }
    if(t.kind==='saw'){
      const p=sawPosition(t),r={x:p.x,y:p.y,w:62,h:62};
      for(const h of heroes)if(h.active&&h.hp>0&&jumpHeight(h)<20&&dist(h,p)<31){
        const hit=hurt(h,16,{...p,type:'saw',push:440,dx:p.vx,dy:p.vy});
        if(hit&&h.id===selected){shake=Math.max(shake,4);$('#status').textContent='锯轮击中！跳跃或绕过机关。';}
      }
      trapEnemies(t,{x:p.x,y:p.y,w:56,h:56},22,'lastSaw');
      continue;
    }
    if(t.kind==='wallspike'){
      const r=spikeRect(t),active=wallPhase(t)==='active';
      if(active){for(const h of heroes)trapHurt(t,h,13,r,340,'墙刺弹出！看到预警再绕开。');trapEnemies(t,r,20,'lastWall');}
      continue;
    }
    if(t.kind==='spikerow'){
      for(let i=0;i<t.cells;i++){
        if(rowPhase(t,i)!=='active')continue;
        const c=rowCell(t,i),r={x:c.x,y:c.y,w:32,h:32};
        for(const h of heroes)trapHurt(t,h,12,r,330,'连排地刺依次升起！跟着节奏通过。');
        trapEnemies(t,r,18,'lastRow');
      }
      continue;
    }
    if(t.kind==='flame'){
      state.timer-=dt;
      if(state.phase==='idle'&&state.timer<=0){state.phase='warn';state.timer=.9;beep(300,.06);}
      else if(state.phase==='warn'&&state.timer<=0){state.phase='fire';state.timer=1.15;beep(210,.12);}
      else if(state.phase==='fire'&&state.timer<=0){state.phase='idle';state.timer=2.5;}
      if(state.phase==='fire'){const r=flameRect(t);for(const h of heroes)trapHurt(t,h,10,r,300,'火焰柱喷射！火箱闪亮后离开火线。');trapEnemies(t,r,20,'lastFlame');}
      continue;
    }
    if(t.kind==='fan'){
      state.timer-=dt;
      if(state.phase==='idle'&&state.timer<=0){state.phase='gust';state.timer=1.7;beep(480,.1);}
      else if(state.phase==='gust'&&state.timer<=0){state.phase='idle';state.timer=1.15;}
      if(state.phase==='gust'){
        const [dx,dy]=dirVector(t.dir),r=fanRect(t);
        for(const h of heroes)if(h.active&&h.hp>0&&jumpHeight(h)<=8&&inRect(h,r))move(h,dx*78*dt,dy*78*dt);
      }
      continue;
    }
    if(t.kind==='bomb'){
      state.timer-=dt;
      if(state.phase==='armed'){
        if(heroes.some(h=>h.active&&h.hp>0&&h.jumpTime<=0&&dist(h,t)<30)){state.phase='fuse';state.timer=1.1;beep(520,.07);}
      }else if(state.phase==='fuse'){
        if(state.timer<=0){
          state.phase='blast';state.timer=.42;shake=Math.max(shake,7);beep(120,.25);burst(t.x,t.y,'#ff9b3c',34);
          for(const h of heroes)if(h.active&&h.hp>0&&dist(h,t)<t.radius)hurt(h,22,{type:'bomb',x:t.x,y:t.y,push:560});
          for(const e of enemies)if(!e.entering&&e.hp>0&&dist(e,t)<t.radius)damage(e,45);
          if(heroes.some(h=>h.active&&h.hp>0&&h.id===selected&&dist(h,t)<t.radius))$('#status').textContent='炸弹爆炸！引信闪烁时撤出范围。';
        }
      }else if(state.phase==='blast'&&state.timer<=0){state.phase='spent';state.timer=3.2;}
      else if(state.phase==='spent'&&state.timer<=0){state.phase='armed';state.timer=0;}
      continue;
    }
    if(t.kind==='rockfall'){
      state.timer-=dt;
      if(state.phase==='idle'&&state.timer<=0){state.phase='crack';state.timer=.9;beep(200,.07);}
      else if(state.phase==='crack'&&state.timer<=0){
        state.phase='fall';state.timer=.45;shake=Math.max(shake,6);beep(150,.2);burst(t.x,t.y,'#c9a06a',26);
        for(const h of heroes)if(h.active&&h.hp>0&&dist(h,t)<t.radius)hurt(h,18,{type:'rockfall',x:t.x,y:t.y,push:340});
        for(const e of enemies)if(!e.entering&&e.hp>0&&dist(e,t)<t.radius)damage(e,36);
        if(heroes.some(h=>h.active&&h.hp>0&&h.id===selected&&dist(h,t)<t.radius))$('#status').textContent='拱顶塌落！看到地面裂缝就离开。';
      }
      else if(state.phase==='fall'&&state.timer<=0){state.phase='rubble';state.timer=2.2;}
      else if(state.phase==='rubble'&&state.timer<=0){state.phase='idle';state.timer=3.1;}
      continue;
    }
  }
}
function drawMechanisms(){
  for(const t of mechanismSpecs){
    if(t.stage!==trial.stage)continue;
    const state=mechanismState[t.id];
    if(t.kind==='spike'){
      const phase=spikePhase(t),frame=phase==='active'?4:phase==='warning'?1:0;
      ctx.fillStyle='#292832';ctx.fillRect(t.x-t.w/2,t.y-t.h/2,t.w,t.h);
      for(let y=t.y-t.h/2;y<t.y+t.h/2;y+=28)ctx.drawImage(images.TrapSpikes,frame*32,0,32,32,t.x-t.w/2,y-10,t.w,40);
      ctx.fillStyle=phase==='warning'?'#f7c26b':phase==='active'?'#d87969':'#71878a';ctx.fillRect(t.x-t.w/2,t.y+t.h/2-3,t.w,3);
    }else if(t.kind==='saw'){
      const p=sawPosition(t);ctx.fillStyle='#39323c';ctx.fillRect(t.x-12,t.y-10,24,20);
      ctx.drawImage(images.TrapSaw,Math.floor(time*12)%8*32,0,32,32,p.x-30,p.y-32,60,60);
    }else if(t.kind==='bow'){
      const frame=state.timer<.7?2:0;ctx.drawImage(images.TrapBow,frame*16,0,16,16,t.x-24,t.y-24,48,48);
    }else if(t.kind==='spikerow'){
      for(let i=0;i<t.cells;i++){
        const c=rowCell(t,i),phase=rowPhase(t,i),frame=phase==='active'?6:phase==='warning'?2:0;
        ctx.fillStyle='#292832';ctx.fillRect(c.x-16,c.y-16,32,32);
        ctx.drawImage(images.TrapSpikes,frame*32,0,32,32,c.x-16,c.y-20,32,40);
        ctx.fillStyle=phase==='warning'?'#f7c26b':phase==='active'?'#d87969':'#71878a';ctx.fillRect(c.x-16,c.y+13,32,3);
      }
    }else if(t.kind==='wallspike'){
      const phase=wallPhase(t),grow=phase==='active'?1:phase==='warning'?.38:0;
      ctx.fillStyle='#2b2229';ctx.fillRect(t.x-16,t.y-16,32,32);
      if(grow>0){
        ctx.globalAlpha=phase==='warning'?.7:1;
        if(t.dir==='e'||t.dir==='w'){
          const len=t.reach*grow,cx=t.dir==='e'?t.x+len/2:t.x-len/2;
          ctx.drawImage(images.TrapWall,48,0,32,16,cx-len/2,t.y-15,len,30);
        }else{
          const len=t.reach*grow,cy=t.dir==='s'?t.y+len/2:t.y-len/2;
          ctx.drawImage(images.TrapWall,32,0,16,32,t.x-15,cy-len/2,30,len);
        }
        ctx.globalAlpha=1;
      }
      ctx.fillStyle=phase==='active'?'#d87969':phase==='warning'?'#f7c26b':'#71878a';ctx.fillRect(t.x-4,t.y-4,8,8);
    }else if(t.kind==='flame'){
      const [dx,dy]=dirVector(t.dir),box=state.phase==='idle'?12:state.phase==='warn'?(8+Math.floor((.9-state.timer)/.9*5))%13:7;
      if(state.phase==='fire'){
        for(let d=0;d<t.length;d+=16){
          const fx=t.x+dx*(d+8),fy=t.y+dy*(d+8);
          ctx.globalAlpha=.92;ctx.drawImage(images.TrapFire,Math.floor(time*14)%4*16,0,16,16,fx-12,fy-12,24,24);ctx.globalAlpha=1;
        }
      }else if(state.phase==='warn'){
        ctx.fillStyle='#ffb45455';ctx.beginPath();ctx.arc(t.x,t.y,18+Math.sin(time*20)*4,0,7);ctx.fill();
      }
      ctx.drawImage(images.TrapFireBox,box*16,0,16,32,t.x-16,t.y-30,32,60);
    }else if(t.kind==='fan'){
      const gust=state.phase==='gust';
      ctx.save();ctx.translate(t.x,t.y);
      if(t.dir==='w')ctx.rotate(-Math.PI/2);else if(t.dir==='e')ctx.rotate(Math.PI/2);else if(t.dir==='s')ctx.rotate(Math.PI);
      ctx.drawImage(images.TrapFan,Math.floor(time*12)%8*32,0,32,16,-24,-16,48,26);
      ctx.restore();
      if(gust){
        const [ux,uy]=dirVector(t.dir),[px,py]=[-uy,ux];
        ctx.strokeStyle='#bff2ff';ctx.lineWidth=2;ctx.globalAlpha=.55;
        for(let i=0;i<5;i++){
          const o=(i-2)*22,sx=t.x+px*o+ux*13,sy=t.y+py*o+uy*13,len=t.length*(.45+.12*i);
          ctx.beginPath();ctx.moveTo(sx,sy);ctx.lineTo(sx+ux*len,sy+uy*len);ctx.stroke();
        }
        ctx.globalAlpha=1;
      }else if(state.timer<.35){ctx.fillStyle='#9fe8ff66';ctx.beginPath();ctx.arc(t.x,t.y,18,0,7);ctx.fill();}
    }else if(t.kind==='bomb'){
      const radius=t.radius??74;
      if(state.phase==='blast'){
        const f=1-Math.max(0,state.timer)/.42;
        ctx.fillStyle='#ffb04a99';ctx.beginPath();ctx.arc(t.x,t.y,radius*(.45+f*.65),0,7);ctx.fill();
        ctx.fillStyle='#ffe9a6cc';ctx.beginPath();ctx.arc(t.x,t.y,Math.max(4,radius*.34*(1-f*.4)),0,7);ctx.fill();
        ctx.drawImage(images.TrapBomb,4*32,0,32,32,t.x-30,t.y-46,60,60);
      }else{
        if(state.phase==='fuse'&&Math.floor(time*12)%2){ctx.fillStyle='#ffcf6e44';ctx.beginPath();ctx.arc(t.x,t.y,radius,0,7);ctx.fill();}
        const frame=state.phase==='armed'?0:Math.min(4,1+Math.floor((1.1-state.timer)/1.1*3.4));
        ctx.globalAlpha=state.phase==='spent'?.4:1;
        ctx.drawImage(images.TrapBomb,frame*32,0,32,32,t.x-20,t.y-34,40,40);
        ctx.globalAlpha=1;
        ctx.fillStyle=state.phase==='armed'?'#d87969':state.phase==='fuse'?Math.floor(time*12)%2?'#ffd06e':'#8a4a3a':'#61705c';
        ctx.fillRect(t.x-13,t.y+6,26,4);
      }
    }else if(t.kind==='rockfall'){
      const radius=t.radius??44;
      if(state.phase==='crack'){
        ctx.strokeStyle='#e9c27a';ctx.lineWidth=2;ctx.beginPath();ctx.arc(t.x,t.y,radius,0,7);ctx.stroke();
        ctx.fillStyle='#8a6a4a';ctx.fillRect(t.x-18,t.y-3,10,5);ctx.fillRect(t.x+4,t.y+2,12,4);
      }else if(state.phase==='fall'){
        ctx.drawImage(images.TrapRock,Math.min(5,Math.floor((.45-state.timer)/.45*5))%6*32,0,32,32,t.x-26,t.y-58,52,52);
        ctx.fillStyle='#c9a06a55';ctx.beginPath();ctx.arc(t.x,t.y,radius,0,7);ctx.fill();
      }else if(state.phase==='rubble'){
        ctx.drawImage(images.TrapBrick,Math.floor(time*10)%8*32,0,32,32,t.x-24,t.y-34,48,40);
        ctx.fillStyle='#6b5a4a';ctx.fillRect(t.x-20,t.y-4,40,8);
      }else{
        ctx.fillStyle='#3a2f2a';ctx.fillRect(t.x-16,t.y-5,32,9);
        ctx.fillStyle='#8a6a4a';ctx.fillRect(t.x-9,t.y-3,8,5);ctx.fillRect(t.x+3,t.y-2,7,4);
      }
    }else{
      if(state.phase==='down'){drawLava(t.x-t.w/2,t.y-12,t.w,24);continue;}
      const jitter=state.phase==='cracking'?Math.sin(time*45)*2:0;
      ctx.drawImage(images.TrapPlatform,Math.floor(time*8)%8*32,0,32,16,t.x-t.w/2+jitter,t.y-12,t.w,26);
      if(state.phase==='cracking'){ctx.fillStyle='#ffd17c';ctx.fillRect(t.x-18,t.y-4,22,3);ctx.fillRect(t.x+1,t.y-4,3,12);}
    }
  }
}
function beamLava(x,y){return mapId==='catacombs'&&x>BEAM_LEFT&&x<BEAM_RIGHT&&y>=1120&&y<=1376&&(Math.abs(y-BEAM_Y)>12||BEAM_GAPS.some(([a,b])=>x>a&&x<b)||collapsedBridge(x,y));}
function fireHome(x,y){return {x:clamp(x,BEAM_LEFT+40,BEAM_RIGHT-40),y:y<BEAM_Y?clamp(y,1152,BEAM_Y-48):clamp(y,BEAM_Y+48,1344)};}
function resetFireResidents(){fireRespawnAt=FIRE_SITES.map(()=>time);enemies=enemies.filter(e=>e.type!=='fire');populateFireResidents();}
function populateFireResidents(){
  if(mapId!=='catacombs'||trial?.stage!==3||time<38)return;
  FIRE_SITES.forEach((site,i)=>{
    if(time<fireRespawnAt[i]||enemies.some(e=>e.type==='fire'&&e.habitat===i&&e.hp>0))return;
    enemies.push({...enemySpecs.fire,type:'fire',x:site.x,y:site.y,home:{...site},habitat:i,maxHp:enemySpecs.fire.hp,cool:2+i*.45,attack:0,windup:0,target:null,anim:i*1.7,face:-1,moving:false,entering:false,station:null});
    spawnHistory.push({type:'fire',x:site.x,y:site.y,time,side:'lava',station:null});burst(site.x,site.y,'#ff9a34',16);
  });
}
function companionContact(dt){
  const lead=heroes[selected];lead.allyBump=Math.max(0,lead.allyBump-dt);
  if(lead.hp<=0||lead.allyBump>0||jumpHeight(lead)>8||trial?.phase==='falling')return;
  const mate=heroes.find(h=>h.active&&h.id!==selected&&h.hp>0&&jumpHeight(h)<=8&&dist(h,lead)<24);
  if(!mate)return;
  const dx=lead.x-mate.x,dy=lead.y-mate.y,d=Math.hypot(dx,dy),n=Math.min(6,24-d);
  move(lead,d?dx/d*n:lead.face*n,d?dy/d*n:0);lead.allyBump=.8;
}
function jumpHeight(h){return h.jumpTime>0?Math.sin(Math.PI*(1-h.jumpTime/JUMP_DURATION))*64:0;}
function jump(h){if(h.hp<=0||h.jumpTime>0||h.jumpCooldown>0||trial?.phase==='falling')return;h.jumpTime=JUMP_DURATION;h.jumpCooldown=1.05;burst(h.x,h.y,'#cbd9c5',8);beep(470,.08);}
function groundCheck(h){
  if(mapId!=='catacombs'||trial?.stage!==3||h.flying||h.jumpTime>0||!beamLava(h.x,h.y))return false;
  if(h.id===selected)beginFall('没有落在木梁上，坠入熔岩。按 E 跳过断口，并保持在木梁中央。');
  else if(h.id!==undefined){const lead=heroes[selected];h.x=lead.x;h.y=lead.y;h.jumpTime=lead.jumpTime;h.pushTime=0;}
  else h.hp=0;
  return true;
}
function dungeonFloor(x,y,r=0) {
  return [[x-r,y-r],[x+r,y-r],[x-r,y+r],[x+r,y+r]].every(([px,py]) => [...dungeonRooms,...dungeonCorridors].some(q=>px>=q.x&&px<q.x+q.w&&py>=q.y&&py<q.y+q.h));
}

for (let y = 70; y < WORLD_H - 40; y += 78) for (let x = 65; x < WORLD_W - 30; x += 78) {
  const px = x + terrainRandom() * 35, py = y + terrainRandom() * 35;
  const edge = x < 140 || x > WORLD_W - 150 || y < 140 || y > WORLD_H - 160;
  if (!isWater(px, py, 65) && !isPath(px, py) && dist({ x: px, y: py }, camp) > 150 && terrainRandom() < (edge ? .92 : .48)) trees.push({ x: px, y: py, radius: 25, kind: 'tree' });
}
for (let i = 0; i < 36; i++) {
  const x = 120 + terrainRandom() * 1950, y = 140 + terrainRandom() * 1160;
  if (!isWater(x, y, 55) && !isPath(x, y) && dist({ x, y }, camp) > 160 && !trees.some(t => dist(t, { x, y }) < 45)) rocks.push({ x, y, radius: 24, kind: 'rock' });
}
// Broken ruin walls leave wide doors and a walkable courtyard.
for (let x = 740; x <= 1124; x += 32) {
  if (x < 900 || x > 980) walls.push({ x, y: 220, radius: 23, kind: 'wall' });
  if (x < 850 || x > 1010) walls.push({ x, y: 452, radius: 23, kind: 'wall' });
}
for (let y = 252; y <= 420; y += 32) { if (y < 305 || y > 380) { walls.push({ x: 740, y, radius: 23, kind: 'wall' }); walls.push({ x: 1124, y, radius: 23, kind: 'wall' }); } }
// Keep the ruin courtyard free of randomly placed trunks and boulders.
for (const list of [trees, rocks]) for (let i = list.length - 1; i >= 0; i--) if (list[i].x > 700 && list[i].x < 1170 && list[i].y > 180 && list[i].y < 490) list.splice(i, 1);
const obstacles = [...trees, ...rocks, ...walls];
const forestLayout = { camp: {...camp}, bridges: bridges.map(b=>({...b})), gates: gates.map(g=>({...g})), obstacles: obstacles.map(o=>({...o})) };
let stationFlows = [], obstacleBuckets = null;
function nearbyObstacles(x,y) {
  if (!obstacleBuckets) return obstacles;
  const result=[]; const bx=Math.floor(x/128),by=Math.floor(y/128);
  for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++)result.push(...(obstacleBuckets.get((bx+dx)+','+(by+dy))||[]));
  return result;
}

function blocked(x, y, radius = 13) {
  if (x < 20 || y < 20 || x > WORLD_W - 20 || y > WORLD_H - 20 || isWater(x, y, radius) || (mapId === 'catacombs' && !dungeonFloor(x,y,radius))) return true;
  if(mapId==='catacombs'&&trial){if(trial.stage===0&&!trial.open&&Math.abs(x-720)<radius+16)return true;if(trial.stage<2&&Math.abs(x-1424)<radius+16)return true;if(trial.stage<3&&x>2080&&Math.abs(y-1040)<radius+12)return true;}
  return nearbyObstacles(x,y).some(o => Math.hypot(o.x - x, o.y - y) < o.radius + radius);
}
const walkable = new Uint8Array(COLS * ROWS);
for (let y = 0; y < ROWS; y++) for (let x = 0; x < COLS; x++) walkable[y * COLS + x] = +!blocked(x * CELL + 16, y * CELL + 16, 16);
function applyMap(id) {
  mapId=id; obstacleBuckets=null; obstacles.length=0; bridges.length=0; gates.length=0; herbs.length=0;
  if(id==='forest') {
    trial=null;
    Object.assign(camp,forestLayout.camp); obstacles.push(...forestLayout.obstacles.map(o=>({...o}))); bridges.push(...forestLayout.bridges.map(b=>({...b}))); gates.push(...forestLayout.gates.map(g=>({...g})));
    [[400,600,'power','西部密林'],[1000,350,'speed','北部遗迹'],[1900,400,'power','东北林地'],[1840,1040,'health','东南岩地'],[420,1180,'speed','西南林地'],[1060,1056,'health','南部河岸']].forEach(([x,y,type,region],i)=>herbs.push({id:i,x,y,type,region,readyAt:0,cycle:0}));
  } else {
    trial = newTrial(0);resetMechanisms(); Object.assign(camp,{x:144,y:752});
    for(const [x,y]of[[954,680],[1190,842]])obstacles.push({x,y,radius:25,kind:'pillar'});
    gates.push({x:-70,y:752,tx:96,ty:752,side:'west'},{x:2310,y:752,tx:2144,ty:752,side:'east'},{x:2310,y:BEAM_Y,tx:2130,ty:BEAM_Y,side:'east'},{x:-70,y:BEAM_Y,tx:BEAM_EXIT,ty:BEAM_Y,side:'west'});
    [[112,560,'health','起点壁龛'],[656,944,'power','第一关出口'],[832,656,'speed','摆锤入口'],[1344,880,'health','摆锤出口'],[1536,544,'power','终关入口'],[2128,944,'speed','第四关楼梯'],[2112,1180,'health','独木桥入口'],[160,1168,'power','独木桥出口']].forEach(([x,y,type,region],i)=>herbs.push({id:i,x,y,type,region,readyAt:0,cycle:0}));
  }
  obstacleBuckets=new Map(); for(const o of obstacles){const k=Math.floor(o.x/128)+','+Math.floor(o.y/128);if(!obstacleBuckets.has(k))obstacleBuckets.set(k,[]);obstacleBuckets.get(k).push(o);}
  for(let y=0;y<ROWS;y++)for(let x=0;x<COLS;x++)walkable[y*COLS+x]=+!blocked(x*CELL+16,y*CELL+16,16);
  for(const site of herbs) { if(blocked(site.x,site.y,20)){let best=Infinity;for(let i=0;i<walkable.length;i++)if(walkable[i]){const x=i%COLS*CELL+16,y=Math.floor(i/COLS)*CELL+16,d=dist(site,{x,y});if(d<best){best=d;site.safe={x,y};}}Object.assign(site,site.safe);} }
  stationFlows=herbs.map(site=>buildFlow(site)); flow=null;flowCell=-1;flowTimer=0;initHeroes();
  if(loaded)paintBackground();
}
function selectMap(id) {
  if(mode!=='ready'||!mapNames[id])return;
  chosenMap=id; applyMap(id); updateUI();
}
function cellAt(x, y) { return clamp(Math.floor(y / CELL), 0, ROWS - 1) * COLS + clamp(Math.floor(x / CELL), 0, COLS - 1); }
function buildFlow(target) {
  let start = cellAt(target.x, target.y);
  if (!walkable[start]) {
    let closest = Infinity;
    for (let i = 0; i < walkable.length; i++) if (walkable[i]) { const d = Math.hypot((i % COLS) * CELL + 16 - target.x, Math.floor(i / COLS) * CELL + 16 - target.y); if (d < closest) { closest = d; start = i; } }
  }
  const costs = new Int16Array(walkable.length); costs.fill(-1); costs[start] = 0;
  const queue = new Int32Array(walkable.length); queue[0] = start; let head = 0, tail = 1;
  while (head < tail) {
    const at = queue[head++], x = at % COLS, y = Math.floor(at / COLS);
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const nx = x + dx, ny = y + dy, n = ny * COLS + nx;
      if (nx >= 0 && nx < COLS && ny >= 0 && ny < ROWS && walkable[n] && costs[n] < 0) { costs[n] = costs[at] + 1; queue[tail++] = n; }
    }
  }
  return costs;
}
function lineClear(a, b) {
  const d = dist(a, b), n = Math.ceil(d / 18);
  for (let i = 1; i <= n; i++) if (blocked(a.x + (b.x - a.x) * i / n, a.y + (b.y - a.y) * i / n, 8)) return false;
  return true;
}
function move(h, dx, dy) {
  // Substeps prevent a dash from tunnelling through a river or wall.
  const steps = Math.max(1, Math.ceil(Math.hypot(dx, dy) / 8)); let moved = false;
  for (let i = 0; i < steps; i++) {
    if(h.id===selected&&trial?.phase==='falling')break;
    const x = clamp(h.x + dx / steps, 22, WORLD_W - 22), y = clamp(h.y + dy / steps, 22, WORLD_H - 22);
    if (!blocked(x, y)) { moved ||= x !== h.x || y !== h.y; h.x = x; h.y = y; }
    else { if (!blocked(x, h.y)) { moved ||= x !== h.x; h.x = x; } if (!blocked(h.x, y)) { moved ||= y !== h.y; h.y = y; } }
    if(groundCheck(h))break;
  }
  if (dx) h.face = dx > 0 ? 1 : -1;
  h.moving = moved;
}
function navigate(h, goal, stop, dt, routeFlow = flow) {
  const d = dist(h, goal); if (d <= stop) return;
  if (lineClear(h, goal)) { move(h, (goal.x - h.x) / d * h.speed * (h.id !== undefined && buffs.speed > 0 ? 1.45 : 1) * dt, (goal.y - h.y) / d * h.speed * (h.id !== undefined && buffs.speed > 0 ? 1.45 : 1) * dt); return; }
  const at = cellAt(h.x, h.y), cx = at % COLS, cy = Math.floor(at / COLS);
  let next = -1, cost = routeFlow?.[at] ?? -1;
  for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
    const nx = cx + dx, ny = cy + dy, n = ny * COLS + nx;
    if (nx < 0 || nx >= COLS || ny < 0 || ny >= ROWS) continue;
    if (routeFlow?.[n] >= 0 && (cost < 0 || routeFlow[n] < cost)) { next = n; cost = routeFlow[n]; }
  }
  if (next >= 0) {
    // Align with the current cell before turning around a corner.
    const tx = next % COLS === cx ? cx * CELL + 16 : next % COLS * CELL + 16;
    const ty = Math.floor(next / COLS) === cy ? cy * CELL + 16 : Math.floor(next / COLS) * CELL + 16;
    const point = lineClear(h, { x: tx, y: ty }) ? { x: tx, y: ty } : { x: cx * CELL + 16, y: cy * CELL + 16 };
    const n = dist(h, point); if (n > .1) move(h, (point.x - h.x) / n * Math.min(h.speed * (h.id !== undefined && buffs.speed > 0 ? 1.45 : 1) * dt, n), (point.y - h.y) / n * Math.min(h.speed * (h.id !== undefined && buffs.speed > 0 ? 1.45 : 1) * dt, n));
  }
}
function newTrial(stage=0) {
  return {stage,phase:'idle',round:0,required:stage===2?3:2,timer:0,open:stage===1||stage===3,question:'',answer:0,numbers:[],safe:-1,fall:0,completed:stage,checkpoint:stage,cleared:false};
}
function rebuildNavigation(){
  for(let y=0;y<ROWS;y++)for(let x=0;x<COLS;x++)walkable[y*COLS+x]=+!blocked(x*CELL+16,y*CELL+16,16);
  stationFlows=herbs.map(buildFlow);flow=null;flowCell=-1;flowTimer=0;
  if(moveTarget)moveFlow=buildFlow(moveTarget);
}
function board(){return boardOrigins[trial.stage===2?1:0];}
function tileIndex(h){const b=board(),x=Math.floor((h.x-b.x)/128),y=Math.floor((h.y-b.y)/128);return x>=0&&x<3&&y>=0&&y<3?y*3+x:-1;}
function askQuestion(){
  const a=1+Math.floor(Math.random()*5),b=1+Math.floor(Math.random()*4),subtract=Math.random()<.5;
  trial.answer=subtract?a+b-a:a+b;trial.question=subtract?`${a+b} − ${a} = ?`:`${a} + ${b} = ?`;
  trial.numbers=Array.from({length:9},(_,i)=>i+1);
  for(let i=8;i>0;i--){const j=Math.floor(Math.random()*(i+1));[trial.numbers[i],trial.numbers[j]]=[trial.numbers[j],trial.numbers[i]];}
  trial.safe=trial.numbers.indexOf(trial.answer);trial.timer=3;trial.phase='question';beep(680,.1);
}
function beginFall(reason){
  if(trial.phase==='falling'||mode!=='playing')return;
  failureReason=reason;trial.phase='falling';trial.fall=.8;moveTarget=null;keys.clear();shake=8;
  burst(heroes[selected].x,heroes[selected].y,'#ff873f',40);beep(90,.3);
}
function pendulums(){
  const clocks=time;
  // Two pendulums per stage-1 lane were too thin; every arm keeps a distinct
  // phase and amplitude so the corridor reads as overlapping sweeps, not a wall.
  const arm=(px,amp,phase,r)=>{const a=clocks*2+phase;return {x:px+Math.sin(a)*amp,y:752+Math.sin(a)*130,px,amp,phase,py:580,r,stage:1,vx:Math.cos(a)*amp*2,vy:Math.cos(a)*260};};
  return [
    arm(992,26,0,35),
    arm(1090,24,1.1,33),
    arm(1216,26,2.2,35),
    arm(1330,16,3.3,30),
    {x:1810+Math.sin(clocks*1.7)*120,y:740+Math.cos(clocks*1.7)*120,px:1810,py:500,r:30,stage:2,vx:Math.cos(clocks*1.7)*204,vy:-Math.sin(clocks*1.7)*204},
    ...[{px:820,amp:84,phase:0,r:27},{px:1240,amp:84,phase:2.3,r:27},{px:1800,amp:84,phase:4.6,r:27}]
      .map(h=>{const a=clocks*2+h.phase;return {x:h.px+Math.cos(a)*h.amp,y:BEAM_Y+Math.sin(a)*h.amp,px:h.px,amp:h.amp,phase:h.phase,py:BEAM_Y,r:h.r,stage:3,vx:-Math.sin(a)*h.amp*2,vy:Math.cos(a)*h.amp*2};})
  ];
}
function advanceTrial(stage){
  trial=newTrial(stage);resetMechanisms();fireballs=[];moveTarget=null;moveFlow=null;keys.clear();
  const lead=heroes[selected];Object.assign(camp,{x:stage===3?2112:stage===1?816:1520,y:stage===3?BEAM_Y:752});
  for(const h of heroes)if(h.active){h.hp=Math.min(h.maxHp,h.hp+55);if(h.id!==selected){h.x=lead.x-34;h.y=lead.y+28;}h.inv=1.2;}
  resetFireResidents();rebuildNavigation();burst(lead.x,lead.y,'#c5e5ac',32);beep(900,.2);
}
function retryTrial(){
  const stage=trial.checkpoint;trial=newTrial(stage);resetMechanisms();failureReason='';
  Object.assign(camp,{x:[144,816,1520,2112][stage],y:stage===3?BEAM_Y:752});initHeroes();selected=chosen;
  heroes.forEach(h=>{if(h.active){h.x=camp.x+(h.id===selected?0:24);h.y=camp.y+(h.id===selected?0:28);h.inv=2;}});
  enemies=[];fireballs=[];particles.length=0;effects=[];texts=[];buffs.power=0;buffs.speed=0;spawnClock=1;
  herbs.forEach(h=>h.readyAt=0);moveTarget=null;moveFlow=null;keys.clear();mapOpen=false;mode='playing';
  resetFireResidents();rebuildNavigation();$('#overlay').classList.add('hidden');canvas.focus();updateUI();
}
function finishTrial(win){
  mode=win?'won':'lost';keys.clear();moveTarget=null;
  if(win){trial.completed=4;trial.cleared=true;try{localStorage.setItem('thornbound.trials.v2',JSON.stringify({version:2,cleared:4,seconds:Math.round(time),leader:chosen}));}catch{saveError='本次通关无法写入浏览器记录。';}}
  $('#characterSelect').classList.add('hidden');$('#mapSelect').classList.add('hidden');
  show(win?'穿越熔火，四关通行':`第 ${trial.stage+1} 关挑战失败`,win?`你与随从抵达地牢出口。用时 ${clockText(time)}。${saveError}`:`${failureReason||'主角倒下了。'} 可以从本关入口重试，已通过的关卡保留。`,win?'返回选择 →':'重试当前关 →');
  $('#status').textContent=win?'地牢四关已通关。':'检查点已保留；R 重试本关，Esc 返回选择。';updateUI();
}
function updateTrial(dt){
  const lead=heroes[selected];
  if(trial.phase==='falling'){trial.fall-=dt;if(trial.fall<=0)end(false);return;}
  for(const p of pendulums())if(p.stage===trial.stage){
    for(const h of heroes)if(h.active&&h.hp>0&&jumpHeight(h)<20&&dist(h,p)<p.r+13){const hit=hurt(h,22,{...p,type:'hammer',push:420,dx:p.vx,dy:p.vy});if(hit&&h.id===selected){shake=5;$('#status').textContent='摆锤命中！受到击退！E 跳过锤头，留意落脚位置。';}}
    for(const e of enemies)if(!e.entering&&e.hp>0&&dist(e,p)<p.r+12&&time-(e.lastPendulum??-10)>.7){damage(e,25);e.lastPendulum=time;}
  }
  if(trial.stage===3){
    for(const h of heroes)if(h.active&&h.hp>0)groundCheck(h);
    for(const e of enemies)if(!e.entering&&e.hp>0)groundCheck(e);
    if(trial.phase!=='falling'&&lead.x<BEAM_EXIT+64&&Math.abs(lead.y-BEAM_Y)<65&&lead.jumpTime<=0)end(true);
    return;
  }
  if(trial.stage===1){if(lead.x>=1344){advanceTrial(2);}return;}
  if(trial.open){
    if(trial.stage===0&&lead.x>=800)advanceTrial(1);
    else if(trial.stage===2&&lead.x>=2110&&Math.abs(lead.y-752)<65)advanceTrial(3);
    return;
  }
  if(trial.phase==='idle'&&tileIndex(lead)>=0){trial.phase='prepare';trial.timer=1;}
  else if(trial.phase==='prepare'||trial.phase==='rest'){
    trial.timer-=dt;if(trial.timer<=0)askQuestion();
  }else if(trial.phase==='question'){
    trial.timer=Math.max(0,trial.timer-dt);
    if(trial.timer<=0){
      trial.phase='collapse';trial.timer=1.5;trial.fall=0;moveTarget=null;moveFlow=null;keys.clear();shake=5;
      const safe=tileIndex(lead)===trial.safe&&lead.jumpTime<=0;
      for(const e of enemies)if(!e.entering&&tileIndex(e)>=0&&tileIndex(e)!==trial.safe){burst(e.x,e.y,'#e97838',8);e.hp=0;}
      if(!safe)beginFall('倒计时结束时未站在正确数字上，地砖坠入熔岩。');
      else {for(const h of heroes)if(h.active&&h.id!==selected){h.x=lead.x+15;h.y=lead.y+15;h.inv=1.5;}burst(lead.x,lead.y,'#a6edb7',20);beep(950,.15);}
    }
  }else if(trial.phase==='collapse'){
    trial.fall+=dt;trial.timer-=dt;
    if(tileIndex(lead)!==trial.safe&&lead.jumpTime<=0){beginFall('离开安全数字地砖，坠入熔岩。');return;}
    // A companion takes shelter with the player instead of chasing enemies into lava.
    for(const h of heroes)if(h.active&&h.id!==selected){h.x=lead.x+12;h.y=lead.y+12;}
    for(const e of enemies)if(!e.entering&&tileIndex(e)>=0&&tileIndex(e)!==trial.safe)e.hp=0;
    if(trial.timer<=0){trial.round++;if(trial.round>=trial.required){trial.open=true;trial.phase='cleared';rebuildNavigation();beep(1100,.2);}else{trial.phase='rest';trial.timer=1.2;}}
  }
}
function trialUI(){
  const stage=`第 ${trial.stage+1} / 4 关 · ${trialNames[trial.stage]}`;
  let hint=trial.stage===1?'绕过石柱 · 躲避地刺、锯轮与箭弩 · 前往右侧':'踏入数字地板，准备 3 秒算术挑战。';
  if(trial.phase==='prepare')hint='准备答题 · 观察九块数字地板';
  if(trial.phase==='question')hint=`${trial.question}   ${trial.timer.toFixed(1)} 秒 · 站到正确数字`;
  if(trial.phase==='collapse'||trial.phase==='falling')hint=`正确答案 ${trial.answer} · 错误地砖坠入熔岩`;
  if(trial.phase==='rest')hint='地砖复原 · 下一道题即将出现';
  if(trial.open&&trial.stage!==1)hint=trial.stage===0?'门已开启 · 向右进入摆锤长廊':trial.stage===3?'沿梁向左 · E 跳过断口 · 裂纹桥板会塌落':'机关已解除 · 向右下进入独木桥';
  if(trial.phase==='falling'&&trial.stage===3)hint='坠入熔岩 · 可以从独木桥入口重试';
  $('#missionTitle').textContent=stage;$('#challengeText').textContent=hint;
  $('#phase').textContent=mode==='paused'?'机关已暂停':mode==='ready'?'地牢 · 线性四关':stage;
  $('#daylight').textContent=trial.stage===3?'E 跳跃 · 落脚木梁':trial.stage===1?'穿越长廊':`${trial.round}/${trial.required} 道题`;
  $('#progress').style.width=(trial.stage+(trial.stage===3?clamp((BEAM_RIGHT-heroes[selected].x)/(BEAM_RIGHT-BEAM_EXIT),0,1):trial.stage===1?clamp((heroes[selected].x-800)/544,0,1):trial.open?1:trial.round/trial.required))/4*100+'%';
  $('#journey').textContent=mode==='won'?'四关通行':`检查点 ${trial.stage+1} · R 重试`;
  $('.map-label').innerHTML='THE LAVA GAUNTLET <span>算术 → 摆锤 → 熔火 → 独木桥</span>';
  $('#best').textContent=mode==='won'?clockText(time):'4 关';
}
function drawLava(x,y,w,h){
  ctx.save();ctx.beginPath();ctx.rect(x,y,w,h);ctx.clip();
  // User-provided rocky lava tile; one-pixel drift per 2/3 second.
  const size=192, drift=Math.floor(time*LAVA_FLOW_SPEED)%size;
  for(let yy=y-size+Math.floor(drift/3);yy<y+h;yy+=size)for(let xx=x-size+drift;xx<x+w;xx+=size)ctx.drawImage(images.LavaTexture,xx,yy,size,size);
  ctx.fillStyle='#4c121c22';ctx.fillRect(x,y,w,h);ctx.restore();
}
function drawBeam(){
  ctx.fillStyle='#53222a';ctx.fillRect(BEAM_LEFT-8,1116,BEAM_RIGHT-BEAM_LEFT+16,264);
  drawLava(BEAM_LEFT,1120,BEAM_RIGHT-BEAM_LEFT,256);
  for(const [x,end]of BEAM_SEGMENTS){
    const w=end-x;
    ctx.fillStyle='#24151b';ctx.fillRect(x,BEAM_Y-9,w,26);
    ctx.fillStyle='#3b241a';ctx.fillRect(x,BEAM_Y-12,w,24);
    ctx.fillStyle='#b78b50';ctx.fillRect(x,BEAM_Y-10,w,17);ctx.fillStyle='#e0bb77';ctx.fillRect(x,BEAM_Y-10,w,3);
    ctx.fillStyle='#6e472d';for(let a=x+8;a<end;a+=32)ctx.fillRect(a,BEAM_Y-7,3,15);
    ctx.fillStyle='#ddbc7f';for(const edge of [x,end-4]){ctx.fillRect(edge,BEAM_Y-9,4,5);ctx.fillRect(edge,BEAM_Y+2,4,5);}
  }
  ctx.font='bold 13px system-ui';ctx.textAlign='center';ctx.fillStyle='#ffe0a3';
  for(const [a,b]of BEAM_GAPS)ctx.fillText('断口 · E', (a+b)/2, BEAM_Y-40);
  ctx.fillStyle='#477961';ctx.fillRect(BEAM_EXIT-24,BEAM_Y-48,48,96);ctx.strokeStyle='#b6ecd0';ctx.lineWidth=3;ctx.strokeRect(BEAM_EXIT-20,BEAM_Y-44,40,88);ctx.fillStyle='#e5e9bf';ctx.fillText('出口',BEAM_EXIT,BEAM_Y-60);
  if(trial.stage<3){ctx.fillStyle='#a2744e';for(let x=2080;x<2176;x+=16)ctx.fillRect(x,1032,8,16);}
}

function drawTrials(){
  for(let bi=0;bi<2;bi++){
    const b=boardOrigins[bi],current=trial.stage===(bi===0?0:2),collapsed=current&&(trial.phase==='collapse'||trial.phase==='falling');
    ctx.fillStyle='#74241e';ctx.fillRect(b.x-8,b.y-8,400,400);
    drawLava(b.x,b.y,384,384);
    for(let i=0;i<9;i++){
      const x=b.x+i%3*128,y=b.y+Math.floor(i/3)*128,safe=current&&i===trial.safe;
      if(collapsed&&!safe){const fall=Math.min(1,trial.phase==='falling'?1-trial.fall/.8:trial.fall/.35);ctx.globalAlpha=1-fall;ctx.fillStyle='#655852';ctx.fillRect(x+4+fall*24,y+4+fall*35,120-fall*48,120-fall*48);ctx.globalAlpha=1;continue;}
      ctx.fillStyle=collapsed&&safe?'#427158':'#726753';ctx.fillRect(x+3,y+3,122,122);ctx.fillStyle='#393a39';ctx.fillRect(x+8,y+8,112,109);ctx.strokeStyle=collapsed&&safe?'#b8f7c7':'#aa9566';ctx.lineWidth=2;ctx.strokeRect(x+13,y+13,102,99);
      ctx.font='bold 38px monospace';ctx.textAlign='center';ctx.fillStyle='#f5df9c';ctx.fillText(current&&trial.numbers.length?trial.numbers[i]:i+1,x+64,y+79);
    }
  }
  for(const x of [720,1424]){
    const locked=x===720?trial.stage===0&&!trial.open:trial.stage<2;
    ctx.fillStyle=locked?'#713e36':'#477a60';ctx.fillRect(x-12,704,24,128);
    if(locked){ctx.fillStyle='#d19962';for(let y=710;y<830;y+=20)ctx.fillRect(x-16,y,32,6);}
  }
  ctx.fillStyle='#86d5a8';ctx.fillRect(1340,732,28,40);ctx.font='13px system-ui';ctx.textAlign='center';ctx.fillText('下一关',1354,716);
  ctx.fillStyle='#487e68';ctx.fillRect(2100,692,64,120);ctx.strokeStyle='#bcf4d3';ctx.lineWidth=4;ctx.strokeRect(2106,698,52,108);
  ctx.fillStyle='#e5e9bf';ctx.font='16px system-ui';ctx.textAlign='center';ctx.fillText('独木桥 ↓',2132,680);
  drawBeam();drawMechanisms();
  // Only the current stage's heads are drawn, matching the mechanism gate so a
  // neighbouring room's sweeps never bleed into this one.
  for(const p of pendulums()){
    if(p.stage!==trial.stage)continue;
    ctx.strokeStyle='#777d86';ctx.lineWidth=7;ctx.beginPath();ctx.moveTo(p.px,p.py);ctx.lineTo(p.x,p.y);ctx.stroke();
    ctx.fillStyle='#e9b879';for(let n=0;n<8;n++){const f=n/8;ctx.fillRect(p.px+(p.x-p.px)*f-3,p.py+(p.y-p.py)*f-3,6,6);}
    ctx.drawImage(images.TrapMace,Math.floor(time*5)%2*21,0,21,21,p.x-p.r,p.y-p.r,p.r*2,p.r*2);
  }
}
function drawTrialBanner(){
  ctx.fillStyle='#1b2028ed';ctx.fillRect(125,16,620,84);ctx.strokeStyle=trial.phase==='question'?'#ecb66d':'#737961';ctx.lineWidth=2;ctx.strokeRect(125,16,620,84);
  ctx.textAlign='center';ctx.fillStyle='#ddc58f';ctx.font='13px system-ui';ctx.fillText(`第 ${trial.stage+1} 关  ·  ${trialNames[trial.stage]}`,435,38);
  ctx.font=trial.phase==='question'?'bold 27px monospace':'bold 16px system-ui';ctx.fillStyle=trial.phase==='question'?'#fff0c2':'#e6ead5';
  ctx.fillText($('#challengeText').textContent,435,73);
}


function initHeroes() {
  heroes = specs.map((s, i) => ({ ...s, active:i===chosen||i===(chosen+2)%3, hp:(i===chosen||i===(chosen+2)%3)?s.hp:0, id: i, x: camp.x + (i - 1) * 48, y: camp.y + (i === 1 ? 0 : 36), maxHp: s.hp, cool: 0, skill: 0, dash: 0, jumpTime:0, jumpCooldown:0, allyBump:0, pushTime:0, pushX:0, pushY:0, inv: 0, anim: 0, attack: 0, moving: false, face: 1 }));
}
initHeroes();
$('#mapSelect').innerHTML = ['forest','catacombs'].map(id=>`<button class="map-choice" data-map="${id}" aria-pressed="${id===chosenMap}" aria-label="选择${mapNames[id]}"><canvas class="map-preview" data-map="${id}" width="112" height="72"></canvas><span><b>${mapNames[id]}</b><small>${id==='forest'?'溪流古桥 · 开阔绕行':'线性四关 · 跳跃与旋转锤'}</small></span></button>`).join('');
$('#mapSelect').onclick=e=>{const b=e.target.closest('[data-map]');if(b)selectMap(b.dataset.map);};
$('#heroes').innerHTML = specs.map((h, i) => `<button class="hero" data-hero="${i}" aria-label="队伍角色${h.name}"><span class="hero-key">${i + 1}</span><canvas class="portrait" width="46" height="48"></canvas><div class="hero-info"><div class="hero-name">${h.name}<small>待命</small></div><div class="hero-desc">${h.role}</div><div class="health"><div></div></div></div></button>`).join('');
$('#characterSelect').innerHTML = specs.map((h, i) => `<button class="character-choice" data-choice="${i}" aria-pressed="${i === 0}" aria-label="选择${h.name}作为领队"><span class="choice-badge"></span><canvas class="choice-portrait" width="65" height="65"></canvas><b>${h.name}</b><small>${h.role} · ${h.ability}<br>${h.description}</small></button>`).join('');
function select(i) {
  if(mode==='playing'||mode==='paused')return;
  if (!Number.isInteger(i) || !heroes[i] || heroes[i].hp <= 0) return;
  if (mode === 'ready' || mode === 'won' || mode === 'lost') {chosen = i;initHeroes();}
  selected = i; moveTarget=null; flowTimer = 0; flowCell = -1; updateUI();
}
$('#heroes').onclick = e => { const b = e.target.closest('[data-hero]'); if (b) select(+b.dataset.hero); };
$('#characterSelect').onclick = e => { const b = e.target.closest('[data-choice]'); if (b) { chosen = +b.dataset.choice; if (mode !== 'playing') { selected = chosen; initHeroes(); updateUI(); } } };
$('#sound').onclick = () => { sound = !sound; $('#sound').textContent = '声音：' + (sound ? '开' : '关'); if (sound) beep(440, .08); };
function beep(f, d) {
  if (!sound) return;
  try {
    audio ??= new (window.AudioContext || window.webkitAudioContext)(); audio.resume();
    const o = audio.createOscillator(), g = audio.createGain(); o.type = 'triangle'; o.frequency.value = f;
    g.gain.setValueAtTime(.035, audio.currentTime); g.gain.exponentialRampToValueAtTime(.001, audio.currentTime + d);
    o.connect(g); g.connect(audio.destination); o.start(); o.stop(audio.currentTime + d);
  } catch { sound = false; $('#sound').textContent = '声音：关'; }
}
function start() {
  if (!loaded) return;
  failureReason=''; mapOpen = false; moveTarget=null; moveFlow=null; applyMap(chosenMap); initHeroes(); enemies = []; fireballs = []; effects = []; texts = []; spawnHistory = []; selected = chosen;
  time = 0; resetMechanisms();kills = 0; serial = 0; buffs.power = 0; buffs.speed = 0; particles.length = 0; pickupHistory.length = 0; guardClock=2; trailClock=0; spawnClock = 2; flowTimer = 0; flowCell = -1; shake = 0;
  herbs.forEach(h => h.readyAt = 0); mode = 'playing'; keys.clear();
  $('#overlay').classList.add('hidden'); $('#characterSelect').classList.add('hidden'); $('#mapSelect').classList.add('hidden');
  $('#status').textContent = '敌潮正在逼近。药水散落点会反复刷新，靠近即可为全队补充力量。'; canvas.focus(); updateUI();
}
function prepareMenu() {
  mode = 'ready'; if(mapId==='catacombs')applyMap('catacombs'); mapOpen = false; moveTarget=null; moveFlow=null; keys.clear(); initHeroes(); selected = chosen;
  enemies = []; fireballs = []; effects = []; texts = []; time = 0; kills = 0;
  $('#characterSelect').classList.remove('hidden'); $('#mapSelect').classList.remove('hidden'); buffs.power=0;buffs.speed=0;particles.length=0; show('选择领队与目的地', '选择地图和领队，在敌潮中争夺补给。', '开始远征 →'); updateUI();
}
$('#start').onclick = () => { if (mode === 'paused') pause(); else if(mode==='lost'&&mapId==='catacombs')retryTrial(); else if (mode === 'won' || mode === 'lost') prepareMenu(); else start(); };
$('#pause').onclick = pause;
$('#map').onclick = toggleMap;
function toggleMap() {
  if (mode !== 'playing' && mode !== 'paused') return;
  mapOpen = !mapOpen; mode = mapOpen ? 'paused' : 'playing'; keys.clear();
  $('#overlay').classList.add('hidden'); canvas.focus(); updateUI();
}
function show(title, text, button) { $('#overlayTitle').textContent = title; $('#overlayText').textContent = text; $('#start').textContent = button; $('#overlay').classList.remove('hidden'); }
function pause() {
  if (mode === 'playing') { mode = 'paused'; $('#characterSelect').classList.add('hidden'); show('远征暂停', '战斗与机关已暂停，随从会在原地等你。', '继续远征'); }
  else if (mode === 'paused') { mapOpen = false; mode = 'playing'; $('#overlay').classList.add('hidden'); canvas.focus(); }
  keys.clear(); updateUI();
}
function end(win) {
  if(mapId==='catacombs'){finishTrial(win);return;}
  mode = win ? 'won' : 'lost'; keys.clear(); best = Math.max(best, Math.floor(time));
  try { localStorage.setItem('thornbound.v2', JSON.stringify({ version: 2, bestSeconds: best, last: { seconds: Math.floor(time), leader: chosen, map: chosenMap, win } })); }
  catch { saveError = '浏览器未允许保存战绩。'; }
  $('#best').textContent = clockText(best); $('#characterSelect').classList.add('hidden');
  show(win ? (mapId==='forest'?'曙光穿过林梢':'地宫封印苏醒') : '盟约尚未终结', `${win ? '伙伴守住了阵地，远征暂时恢复平静。' : '小队倒下了，选择新的领队再次出发。'} 远征时长 ${clockText(time)}。${saveError}`, '返回选角 →');
  $('#status').textContent = win ? '晨光已经到来，远征完成。' : '远征结束。'; updateUI();
}
window.addEventListener('keydown', e => {
  const k = e.key.toLowerCase(); if ([' ', 'arrowup', 'arrowdown', 'arrowleft', 'arrowright'].includes(k)) e.preventDefault();
  if (!e.repeat) { if(k==='r'&&mapId==='catacombs'&&(mode==='lost'||mode==='playing'||mode==='paused'))retryTrial(); if(k==='escape'&&(mode==='lost'||mode==='won'||mode==='paused'))prepareMenu(); if (k === 'p') pause(); if (k === 'm') toggleMap(); if (['1', '2', '3'].includes(k)) select(+k - 1); if (k === 'e' && mode === 'playing') jump(heroes[selected]); if (k === 'k' && mode === 'playing') skill(heroes[selected]); if (k === ' ' && mode === 'playing') dash(heroes[selected]); }
  keys.add(k);
});
canvas.addEventListener('pointerdown', e=>{
  if(mode!=='playing'||e.button!==0)return;
  const box=canvas.getBoundingClientRect(),target={x:camera.x+(e.clientX-box.left)*VIEW_W/box.width,y:camera.y+(e.clientY-box.top)*VIEW_H/box.height};
  if(blocked(target.x,target.y,16))return;
  moveTarget=target;moveFlow=buildFlow(target);canvas.focus();
});
window.addEventListener('keyup', e => keys.delete(e.key.toLowerCase()));
window.addEventListener('blur', () => { keys.clear(); if (mode === 'playing') pause(); });
document.addEventListener('visibilitychange', () => { if (document.hidden && mode === 'playing') pause(); });
function schedule(t) {
  if(mapId==='catacombs')return {interval:Math.max(.9,2.6-trial.stage*.22-t*.009),batch:Math.min(8,2+Math.floor(t/18)+Math.min(trial.stage,2)),cap:Math.min(76,28+trial.stage*6+Math.floor(t*.35))};
  return {interval:Math.max(.7,2.3-t*.012),batch:Math.min(8,3+Math.floor(t/20)),cap:Math.min(110,40+Math.floor(t*.5))};
}
function typeAt(t,n) {
  const pool=ENEMY_UNLOCKS.filter(([type,at])=>type!=='fire'&&t>=at).map(([type])=>type);
  return pool[n%pool.length];
}
function spawn(station=null) {
  if(enemies.length>=(mapId==='catacombs'?84:156))return;
  const gate=mapId==='catacombs'?(trial.stage===3?gates[2+serial%2]:trial.stage===0?gates[0]:trial.stage===1?gates[serial%2]:gates[1]):station ? gates.reduce((a,b)=>dist({x:a.tx,y:a.ty},station)<dist({x:b.tx,y:b.ty},station)?a:b) : gates[serial%gates.length];
  const type=typeAt(time,serial),spec=enemySpecs[type],offset=(serial%5-2)*12;
  const e={...spec,type,x:gate.x+(['north','south'].includes(gate.side)?offset:0),y:gate.y+(['west','east'].includes(gate.side)?offset:0),gate,entering:true,maxHp:spec.hp,cool:.8,attack:0,windup:0,target:null,anim:0,face:1,moving:true,station:station?.id??null,guardSlot:serial%6};
  enemies.push(e);spawnHistory.push({type,x:e.x,y:e.y,time,side:gate.side,station:e.station});serial++;
}
function burst(x,y,color,count=24,kind='spark') {
  for(let i=0;i<count;i++){const a=i/count*Math.PI*2;particles.push({x,y,dx:Math.cos(a)*(40+i%4*18),dy:Math.sin(a)*(40+i%4*18)-25,life:(kind==='heal'?1.4:.7)+i%3*.16,max:kind==='heal'?1.8:1,color,size:kind==='heal'?4:3,kind});}
  if(particles.length>700)particles.splice(0,particles.length-700);
}
function collect(site) {
  if(time<site.readyAt)return false;
  if(site.type==='health'&&!heroes.some(h=>h.hp>0&&h.hp<h.maxHp))return false;
  if(site.type==='health')heroes.forEach(h=>{if(h.hp>0){const n=Math.min(55,h.maxHp-h.hp);h.hp+=n;if(n)texts.push({x:h.x,y:h.y-42,text:'+'+n,color:'#ffa1b4',life:1});}});
  else buffs[site.type]=lootSpecs[site.type].duration;
  for(const h of heroes)if(h.hp>0)burst(h.x,h.y-18,lootSpecs[site.type].color,18,site.type==='health'?'heal':'spark');
  burst(site.x,site.y-14,lootSpecs[site.type].color,30);site.readyAt=time+24;site.cycle++;pickupHistory.push({type:site.type,time,station:site.id});
  $('#status').textContent=site.type==='health'?'血药补给：存活伙伴恢复生命。':`${lootSpecs[site.type].name}充能：全队获得强化，重复拾取会刷新持续时间。`;
  guardClock=Math.min(guardClock,1);beep(site.type==='power'?520:820,.16);return true;
}
function nearest(h) { return enemies.filter(e => e.hp > 0 && !e.entering).sort((a, b) => dist(h, a) - dist(h, b))[0]; }
function damage(e, n, attacker=null) {
  if (e.hp <= 0) return;
  n = Math.round(n * (attacker&&attacker.id!==selected?COMPANION_DAMAGE:1) * (buffs.power > 0 ? 1.6 : 1));
  e.hp = Math.max(0, e.hp - n); texts.push({ x: e.x, y: e.y - 35, text: '−' + n, color: '#f1deb0', life: .7 });
  if (e.hp === 0) { if(e.type==='fire'&&e.habitat!==undefined)fireRespawnAt[e.habitat]=time+8;kills++; e.windup = 0; beep(130, .08); }
}
function attack(h, target) {
  if (h.cool > 0 || h.hp <= 0) return;
  h.cool = h.id === 1 ? .8 : .55; h.attack = .32; beep(h.id === 2 ? 600 : 300, .06);
  if (h.id === 2) {
    if (target && dist(h, target) <= h.range && lineClear(h, target)) { effects.push({ type: 'bolt', x: h.x, y: h.y, tx: target.x, ty: target.y, life: .25, max: .25, color: h.color }); damage(target, h.damage, h); }
  } else {
    effects.push({ type: 'arc', x: h.x, y: h.y, r: h.range, life: .25, max: .25, color: h.color });
    enemies.forEach(e => { if (!e.entering && dist(h, e) < h.range && lineClear(h, e)) damage(e, h.damage, h); });
  }
}
function skill(h) {
  if (h.hp <= 0 || h.skill > 0) return;
  h.skill = 7; h.attack = .5; const r = h.id === 2 ? 210 : 145;
  effects.push({ type: 'ring', x: h.x, y: h.y, r, life: .6, max: .6, color: h.color });
  enemies.forEach(e => { if (!e.entering && dist(h, e) < r && lineClear(h, e)) damage(e, h.id === 1 ? 75 : 55, h); });
  h.inv = .5; shake = 5; beep(700, .22);
}
function dash(h) {
  if (h.hp <= 0 || h.dash > 0) return;
  let dx = +(keys.has('d') || keys.has('arrowright')) - +(keys.has('a') || keys.has('arrowleft'));
  let dy = +(keys.has('s') || keys.has('arrowdown')) - +(keys.has('w') || keys.has('arrowup'));
  if (!dx && !dy) dx = h.face;
  const n = Math.hypot(dx, dy); move(h, dx / n * 112, dy / n * 112); h.dash = 2; h.inv = .45;
  effects.push({ type: 'ring', x: h.x, y: h.y, r: 35, life: .3, max: .3, color: '#d7eaca' });
}
function hurt(h, n, source=null) {
  if (h.hp <= 0 || h.inv > 0 || (source&&jumpHeight(h)>20)) return false;
  h.hp = Math.max(0, h.hp - n); h.inv = .5;
  if(source){const dx=source.dx??(h.x-source.x),dy=source.dy??(h.y-source.y),d=Math.hypot(dx,dy)||1,power=source.push??(source.type==='slime'?380:source.type==='fire'?500:420);h.pushX=(dx===0&&dy===0?1:dx/d)*power;h.pushY=dy/d*power;h.pushTime=.2;if(h.id===selected){moveTarget=null;moveFlow=null;}burst(h.x,h.y,source.type==='fire'?'#ffab46':'#d6cead',8);}
  texts.push({ x: h.x, y: h.y - 38, text: '−' + n, color: '#ef9987', life: .65 });
  return true;
}
function update(dt) {
  time = mapId==='catacombs'?time+dt:Math.min(DAWN, time + dt); shake = Math.max(0, shake - dt * 25);
  if(mapId==='catacombs'&&trial.phase==='falling'){updateTrial(dt);updateUI();return;}
  for(const k of ['power','speed'])buffs[k]=Math.max(0,buffs[k]-dt);
  let lead = heroes[selected]; flowTimer -= dt;
  const at = cellAt(lead.x, lead.y);
  if (!flow || flowTimer <= 0 || flowCell !== at) { flow = buildFlow(lead); flowCell = at; flowTimer = .6; }
  spawnClock -= dt;
  if((mapId==='catacombs'||time<DAWN)&&spawnClock<=0){const pacing=schedule(time);const roaming=enemies.filter(e=>e.station===null).length;for(let i=0;i<Math.min(pacing.batch,pacing.cap-roaming);i++)spawn();spawnClock=pacing.interval;}
  guardClock-=dt;
  if(mapId==='forest'&&guardClock<=0&&enemies.length<145){
    const sites=[...herbs].sort((a,b)=>dist(a,lead)-dist(b,lead));
    for(const site of sites){const count=enemies.filter(e=>e.station===site.id&&e.hp>0).length;if(count<6){for(let n=0;n<Math.min(2,6-count);n++)spawn(site);break;}}
    guardClock=1.4;
  }
  trailClock-=dt;if(trailClock<=0){trailClock=.07;if(buffs.speed>0)heroes.filter(h=>h.hp>0&&h.moving).forEach(h=>particles.push({x:h.x,y:h.y+3,dx:0,dy:0,life:.35,max:.35,color:'#75e7b4',size:5,kind:'trail'}));}
  particles.forEach(p=>{p.life-=dt;p.x+=p.dx*dt;p.y+=p.dy*dt;});for(let i=particles.length-1;i>=0;i--)if(particles[i].life<=0)particles.splice(i,1);
  for (const h of heroes) {
    h.anim += dt; for (const k of ['cool', 'skill', 'dash', 'inv', 'attack','jumpCooldown']) h[k] = Math.max(0, h[k] - dt);
    h.moving = false; if (h.hp <= 0) continue;
    if(h.jumpTime>0){h.jumpTime=Math.max(0,h.jumpTime-dt);if(!h.jumpTime){burst(h.x,h.y,'#dacda9',5);groundCheck(h);}}
    if(h.pushTime>0){const f=h.pushTime/.2;move(h,h.pushX*f*dt,h.pushY*f*dt);h.pushTime=Math.max(0,h.pushTime-dt);}
    if(h.id===selected&&trial?.phase==='falling')continue;
    const target = nearest(h);
    if (h.id === selected) {
      const dx = +(keys.has('d') || keys.has('arrowright')) - +(keys.has('a') || keys.has('arrowleft'));
      const dy = +(keys.has('s') || keys.has('arrowdown')) - +(keys.has('w') || keys.has('arrowup'));
      if(dx||dy)moveTarget=null;
      if(moveTarget){navigate(h,moveTarget,6,dt,moveFlow);if(moveTarget&&dist(h,moveTarget)<8)moveTarget=null;}
      const n = Math.hypot(dx, dy) || 1; if(dx||dy)move(h, dx / n * h.speed * (h.id !== undefined && buffs.speed > 0 ? 1.45 : 1) * dt, dy / n * h.speed * (h.id !== undefined && buffs.speed > 0 ? 1.45 : 1) * dt);
      if (keys.has('j')) attack(h, target);
    } else if(mapId==='catacombs'&&trial.stage===3&&lead.y>=1100){
      // The companion balances behind the player and automatically jumps the same gap.
      if(h.y<1120&&lead.y>=1120){h.x=lead.x+28;h.y=lead.y;}
      const goal={x:Math.min(2130,lead.x+28),y:lead.x<BEAM_RIGHT&&lead.x>BEAM_LEFT?BEAM_Y:lead.y};
      if(h.jumpTime<=0&&(BEAM_GAPS.some(([a,b])=>h.x>b&&h.x<b+44&&goal.x<b)||jumpHeight(lead)>0))jump(h);
      navigate(h,goal,12,dt);
      if(target&&dist(h,target)<h.range&&lineClear(h,target))attack(h,target);
    } else {
      const answering=mapId==='catacombs'&&trial&&(trial.phase==='question'||trial.phase==='collapse');
      const fight = !answering && target && dist(lead, target) < 310 && dist(h, lead) < 330;
      const goal = fight ? target : lead;
      navigate(h, goal, fight ? h.range * .72 : answering?18:55, dt);
      if (fight && dist(h, target) < h.range && lineClear(h, target)) attack(h, target);
    }
  }
  companionContact(dt);updateMechanisms(dt);populateFireResidents();
  for (const e of enemies) {
    e.anim += dt; e.cool -= dt; e.attack = Math.max(0, e.attack - dt); e.moving = false;
    if (e.hp <= 0) continue;
    if (e.entering) {
      const point = { x: e.gate.tx, y: e.gate.ty }, d = dist(e, point), step = Math.min(e.speed * dt, d);
      if (d > 2) { e.x += (point.x - e.x) / d * step; e.y += (point.y - e.y) / d * step; e.moving = true; e.face = point.x >= e.x ? 1 : -1; }
      else e.entering = false;
      continue;
    }
    if(e.type==='fire'){
      e.home??=fireHome(e.x,e.y);
      e.x=e.home.x+Math.sin(e.anim*.65)*16;e.y=e.home.y+Math.sin(e.anim*.48)*8;
      e.face=heroes[selected].x>=e.x?1:-1;
    }
    const target = heroes.filter(h => h.hp > 0).sort((a, b) => dist(e, a) - dist(e, b))[0]; if (!target) continue;
    if (e.windup > 0) {
      e.windup -= dt; e.attack = .3;
      if (e.windup <= 0) {
        const victim = heroes[e.target];
        if (victim?.hp > 0 && dist(e, victim) < e.range + 12 && lineClear(e, victim)) {
          if(e.type==='fire'){const d=dist(e,victim)||1;fireballs.push({x:e.x,y:e.y,dx:(victim.x-e.x)/d*170,dy:(victim.y-e.y)/d*170,life:2.4,damage:e.damage});beep(240,.08);}
          else hurt(victim, e.damage, e);
        }
        e.cool = e.cooldown;
      }
    } else if (dist(e, target) <= e.range && lineClear(e, target) && e.cool <= 0) { e.windup = e.type==='fire'?.85:e.type==='brute'||e.type==='treant'?.75:.45; e.target = target.id; }
    else if(e.type==='fire'){/* Remain in the lava habitat; never chase onto the bridge. */}
    else if(e.station!==null && dist(e,target)>260){const site=herbs[e.station];navigate(e,site,55+e.guardSlot*9,dt,stationFlows[e.station]);}
    else navigate(e, target, e.range * (e.type==='fire'?.5:.8), dt);
  }
  for(const b of fireballs){
    b.life-=dt;const steps=Math.max(1,Math.ceil(Math.hypot(b.dx,b.dy)*dt/6));
    for(let i=0;i<steps&&b.life>0;i++){
      b.x+=b.dx*dt/steps;b.y+=b.dy*dt/steps;
      if(blocked(b.x,b.y,4)){b.life=0;break;}
      for(const h of heroes)if(h.active&&h.hp>0&&jumpHeight(h)<20&&dist(h,b)<17){
        hurt(h,b.damage,{type:b.type==='arrow'?'arrow':'fire',x:b.x,y:b.y,dx:b.dx,dy:b.dy,push:b.push??500});b.life=0;burst(b.x,b.y,'#ff9d32',12);break;
      }
    }
  }
  fireballs=fireballs.filter(b=>b.life>0);
  for(const site of herbs)if(time>=site.readyAt&&heroes[selected].hp>0&&dist(heroes[selected],site)<36)collect(site);
  enemies = enemies.filter(e => e.hp > 0); effects.forEach(e => e.life -= dt); effects = effects.filter(e => e.life > 0);
  texts.forEach(e => { e.life -= dt; e.y -= dt * 24; }); texts = texts.filter(e => e.life > 0);
  if(mapId==='catacombs')updateTrial(dt);
  if(mode==='playing'){if(heroes[selected].hp<=0)end(false);else if(mapId==='forest'&&time>=DAWN)end(true);}
  updateUI();
}
function region(h) {
  if(mapId==='catacombs')return `第 ${trial.stage+1} 关 · ${trialNames[trial.stage]}`;
  return h.x > 1630 ? '东岸 · 苔石林地' : h.x > 1370 ? '溪流 · 古木桥' : h.y < 490 && h.x > 650 ? '北境 · 失落遗迹' : h.x < 700 ? '西境 · 密林小径' : h.y > 980 ? '南境 · 蕨叶谷地' : '篝火营地';
}
function updateUI() {
  document.querySelectorAll('.hero').forEach((b, i) => {
    const h = heroes[i]; b.style.display=h.active?'':'none'; b.querySelector('.hero-key').textContent=i===selected?'P':'AI'; b.classList.toggle('selected', selected === i);
    b.querySelector('.health div').style.width = h.hp / h.maxHp * 100 + '%';
    b.querySelector('small').textContent = h.hp <= 0 ? '倒下' : selected === i ? '主角' : '随从';
    b.querySelector('.hero-desc').textContent = h.hp <= 0 ? '等待下一次远征' : `${h.hp}/${h.maxHp} HP · ${h.ability} ${h.skill > 0 ? h.skill.toFixed(1) + 's' : '就绪'}`;
  });
  document.querySelectorAll('.map-choice').forEach(b=>{b.classList.toggle('selected',b.dataset.map===chosenMap);b.setAttribute('aria-pressed',String(b.dataset.map===chosenMap));});
  const jumping=heroes[selected];$('#jumpStatus').textContent=jumping.jumpTime>0?'跳跃中':jumping.jumpCooldown>0?`跳跃 ${jumping.jumpCooldown.toFixed(1)}s`:'E 跳跃 · 已就绪';
  $('#buffStatus').textContent=[buffs.power>0?`武力 +60% · ${Math.ceil(buffs.power)}s`:'',buffs.speed>0?`速度 +45% · ${Math.ceil(buffs.speed)}s`:''].filter(Boolean).join(' / ')||'领队靠近拾取 · 同类增益刷新时长';
  document.querySelectorAll('.character-choice').forEach((b, i) => { b.classList.toggle('selected', i === chosen); b.setAttribute('aria-pressed', String(i === chosen)); b.querySelector('.choice-badge').textContent = i === chosen ? '已选领队' : ''; });
  const daylight = time < 40 ? '暮色' : time < 85 ? '深夜' : time < 125 ? '破晓前' : time < DAWN ? '晨光将至' : '黎明';
  $('#region').textContent = region(heroes[selected]);
  $('.map-label').innerHTML=mapId==='forest'?'WHISPERING WOODS <span>开阔林地 · 古桥 · 药水散落点</span>':'CANDLELIT CATACOMBS <span>石室长廊 · 先王墓穴 · 药水散落点</span>';
  $('#missionTitle').textContent=mapId==='forest'?'与随从守到黎明':'地牢三关';
  if(mapId==='forest'){$('#challengeText').textContent='与一名随从探索森林，争夺分散补给并守到黎明。';$('#best').textContent=best?clockText(best):'尚无记录';}
  $('#phase').textContent = mode === 'ready' ? '等待出发' : mode === 'paused' ? (mapOpen ? '地图查看 · 已暂停' : '林间时间已暂停') : daylight + ' · ' + mapNames[mapId];
  $('.map-label').style.display = mapOpen ? 'none' : '';
  $('#daylight').textContent = daylight; $('#progress').style.width = time / DAWN * 100 + '%';
  $('#journey').textContent = mode === 'won' ? '远征完成' : mapId==='forest'?'与伙伴守到黎明':'等待封印苏醒';
  if(mapId==='catacombs')trialUI();
}
function paintBackground() {
  if(mapId==='catacombs'){paintDungeon();return;}
  background = document.createElement('canvas'); background.width = WORLD_W; background.height = WORLD_H;
  const b = background.getContext('2d'); b.imageSmoothingEnabled = false;
  for (let y = 0; y < WORLD_H; y += 32) for (let x = 0; x < WORLD_W; x += 32) {
    b.drawImage(images.grass, x, y, 32, 32);
    if ((x / 32 + y / 32) % 7 === 0) { b.fillStyle = '#244c2612'; b.fillRect(x, y, 32, 32); }
  }
  b.lineJoin = 'round'; b.lineCap = 'round';
  for (const p of pathSegments) { b.strokeStyle = '#7b8051'; b.lineWidth = 78; b.beginPath(); b.moveTo(p[0], p[1]); b.lineTo(p[2], p[3]); b.stroke(); b.strokeStyle = '#8b895b'; b.lineWidth = 48; b.stroke(); }
  b.fillStyle = '#7b8658'; b.beginPath(); b.ellipse(camp.x, camp.y, 155, 123, 0, 0, Math.PI * 2); b.fill();
  b.fillStyle = '#52645b'; b.fillRect(748, 232, 376, 208);
  for (let y = 240; y < 432; y += 32) for (let x = 752; x < 1120; x += 32) { b.fillStyle = (x + y) % 64 ? '#657467' : '#5c6b61'; b.fillRect(x, y, 29, 29); }
  b.fillStyle = '#344e48'; b.fillRect(1460, 0, 168, WORLD_H); b.fillStyle = '#416e75'; b.fillRect(1472, 0, 144, WORLD_H);
  for (let y = 0; y < WORLD_H; y += 24) { b.fillStyle = '#78a5a133'; b.fillRect(1480 + y % 48, y, 40, 3); b.fillRect(1550, y + 12, 38, 2); }
  for (const bridge of bridges) {
    b.fillStyle = '#302f27'; b.fillRect(bridge.x, bridge.y, bridge.w, bridge.h);
    for (let x = bridge.x + 4; x < bridge.x + bridge.w - 4; x += 14) { b.fillStyle = '#8d7650'; b.fillRect(x, bridge.y + 8, 12, bridge.h - 16); b.fillStyle = '#b29865'; b.fillRect(x, bridge.y + 10, 3, bridge.h - 20); }
    b.fillStyle = '#554633'; b.fillRect(bridge.x, bridge.y + 5, bridge.w, 6); b.fillRect(bridge.x, bridge.y + bridge.h - 11, bridge.w, 6);
  }
  for (let i = 0; i < 1400; i++) {
    const x = i * 179 % WORLD_W, y = (i * 97 + 43) % WORLD_H;
    if (!isWater(x, y) && !isPath(x, y)) {
      b.fillStyle = i % 7 ? '#355937' : '#bbc28a'; b.fillRect(x, y, 3, i % 7 ? 7 : 3);
      if (i % 23 === 0) b.drawImage(images.decor, 0, 0, 16, 16, x, y, 32, 32);
    }
  }
}
function paintDungeon() {
  background=document.createElement('canvas');background.width=WORLD_W;background.height=WORLD_H;const b=background.getContext('2d');b.imageSmoothingEnabled=false;
  b.fillStyle='#17151b';b.fillRect(0,0,WORLD_W,WORLD_H);
  for(let y=0;y<WORLD_H;y+=32)for(let x=0;x<WORLD_W;x+=32){
    if(dungeonFloor(x+16,y+16)){b.drawImage(images.catTiles,736,208,32,32,x,y,32,32);b.fillStyle=((x+y)/32)%5===0?'#b19c6920':'#71624e10';b.fillRect(x,y,32,32);}
    else {const edge=[[x+48,y+16],[x-16,y+16],[x+16,y+48],[x+16,y-16]].some(([a,c])=>dungeonFloor(a,c));if(edge){b.drawImage(images.catTiles,80,144,32,32,x,y,32,32);b.fillStyle='#b29e6720';b.fillRect(x,y,32,4);}else{b.fillStyle='#1c191e';b.fillRect(x,y,32,32);}}
  }
  for(const room of dungeonRooms){const glow=b.createRadialGradient(room.x+room.w/2,room.y+room.h/2,0,room.x+room.w/2,room.y+room.h/2,room.w*.7);glow.addColorStop(0,'#deb56716');glow.addColorStop(1,'#deb56700');b.fillStyle=glow;b.fillRect(room.x,room.y,room.w,room.h);}
}
function drawPillar(c,o){c.drawImage(images.catTiles,400,112,32,80,o.x-23,o.y-74,46,96);}
function drawStation(c,site,overview=false) {
  const spec=lootSpecs[site.type],ready=time>=site.readyAt;
  c.fillStyle=ready?spec.color+'35':'#61705c35';c.fillRect(site.x-16,site.y-2,32,7); // Loose potion on the ground, no grouped altar.
  if(ready){const bob=overview?0:Math.round(Math.sin(time*3+site.id)*3);c.drawImage(images[spec.asset],0,0,32,32,site.x-36,site.y-64+bob,72,72);c.fillStyle=spec.color;for(let i=0;i<4;i++){const a=time+i*Math.PI/2;c.fillRect(site.x+Math.cos(a)*32-2,site.y+Math.sin(a)*12-3,4,4);}}
  if(!overview){c.font='11px system-ui';c.textAlign='center';c.fillStyle=ready?spec.color:'#a4ab96';c.fillText(ready?spec.name:`${spec.name} · ${Math.ceil(site.readyAt-time)}s`,site.x,site.y+31);}
}
function sheetFor(asset,state,tint) {
  const key=asset==='Slime'?'Slime':asset+state,source=images[key];if(!tint)return source;
  const cache=key+tint;if(!tintedSheets[cache]){const c=document.createElement('canvas');c.width=source.width;c.height=source.height;const d=c.getContext('2d');d.filter=tint;d.drawImage(source,0,0);tintedSheets[cache]=c;}return tintedSheets[cache];
}
function sprite(h, asset) {
  ctx.save(); ctx.translate(Math.round(h.x), Math.round(h.y)); ctx.scale((h.face || 1)*(h.scale||1),h.scale||1);
  if(mapId==='catacombs'&&trial?.phase==='falling'&&h.id===selected){const f=Math.max(.15,trial.fall/.8);ctx.translate(0,(1-f)*80);ctx.scale(f,f);}
  ctx.translate(0,-jumpHeight(h));
  ctx.globalAlpha = h.hp <= 0 ? .35 : h.id !== undefined && h.inv > 0 && Math.floor(time * 15) % 2 ? .5 : 1;
  if(asset.startsWith('Monster')){
    const row=h.hp<=0?12:h.attack>0||h.windup>0?5:h.moving?1:0,frames=row===12||row===1?8:6;
    ctx.drawImage(images[asset],Math.floor(h.anim*9)%frames*80,row*80,80,80,-55,-88,110,110);
  } else if (asset === 'Slime') {
    const im = sheetFor(asset,'',h.tint), row = h.attack > 0 ? 6 : h.moving ? 3 : 0, frames = h.attack > 0 ? 7 : h.moving ? 6 : 4;
    ctx.drawImage(im, Math.floor(h.anim * 8) % frames * 32, row * 32, 32, 32, -40, -55, 80, 80);
  } else {
    const state = h.hp <= 0 ? 'Death' : h.attack > 0 ? 'Attack01' : h.moving ? 'Walk' : 'Idle';
    const im = sheetFor(asset,state,h.tint); if (im) ctx.drawImage(im, Math.floor(h.anim * 9) % (im.width / 100) * 100 + 28, 24, 48, 48, -60, -80, 120, 120);
  }
  ctx.restore();
}
function minimap() {
  const x = VIEW_W - 172, y = 18, w = 150, h = 96, sx = w / WORLD_W, sy = h / WORLD_H;
  ctx.fillStyle = '#11241de8'; ctx.fillRect(x - 6, y - 6, w + 12, h + 30); ctx.strokeStyle = '#91a47666'; ctx.strokeRect(x - 6, y - 6, w + 12, h + 30);
  ctx.drawImage(background,x,y,w,h);
  for (const p of (mapId==='forest'?pathSegments:[])) { ctx.strokeStyle = '#b5aa7966'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(x + p[0] * sx, y + p[1] * sy); ctx.lineTo(x + p[2] * sx, y + p[3] * sy); ctx.stroke(); }
  for (const b of bridges) { ctx.fillStyle = '#d3bd80'; ctx.fillRect(x + b.x * sx, y + b.y * sy, b.w * sx, b.h * sy); }
  for(const site of herbs){ctx.fillStyle=time>=site.readyAt?lootSpecs[site.type].color:'#767468';ctx.fillRect(x+site.x*sx-2,y+site.y*sy-2,4,4);}
  for (const e of enemies) { ctx.fillStyle = '#e49385'; ctx.fillRect(x + clamp(e.x * sx, 0, w - 2), y + clamp(e.y * sy, 0, h - 2), 2, 2); }
  for (const hero of heroes) if (hero.hp > 0) { ctx.fillStyle = hero.id === selected ? '#fff0ad' : '#b4d889'; ctx.fillRect(x + hero.x * sx - 2, y + hero.y * sy - 2, 4, 4); }
  ctx.strokeStyle = '#e3e5c277'; ctx.strokeRect(x + camera.x * sx, y + camera.y * sy, VIEW_W * sx, VIEW_H * sy);
  ctx.font = '9px monospace'; ctx.textAlign = 'left'; ctx.fillStyle = '#c5cfb2'; ctx.fillText(mapId==='forest'?'FOREST / 探索地图':'CATACOMBS / 地宫' , x + 3, y + h + 16);
}
function drawOverview() {
  const scale = Math.min(VIEW_W / WORLD_W, VIEW_H / WORLD_H), ox = (VIEW_W - WORLD_W * scale) / 2;
  ctx.fillStyle = '#14221d'; ctx.fillRect(0, 0, VIEW_W, VIEW_H); ctx.save(); ctx.translate(ox, 0); ctx.scale(scale, scale);
  if (background) ctx.drawImage(background, 0, 0);
  if(mapId==='catacombs')drawTrials();
  for (const o of obstacles) {
    if (o.kind === 'tree') ctx.drawImage(images.objects, 0, 80, 48, 64, o.x - 42, o.y - 94, 84, 112);
    else if (o.kind === 'rock') ctx.drawImage(images.objects, 0, 16, 16, 16, o.x - 26, o.y - 36, 52, 52);
    else if(o.kind==='pillar')drawPillar(ctx,o);
    else ctx.drawImage(images.objects, 32, 0, 16, 16, o.x - 19, o.y - 35, 38, 38);
  }
  for (const e of enemies) { ctx.fillStyle = '#e19386'; ctx.fillRect(e.x - 5, e.y - 5, 10, 10); }
  for (const h of heroes) if (h.hp > 0) { ctx.fillStyle = h.id === selected ? '#fff1b4' : '#b9d69d'; ctx.beginPath(); ctx.arc(h.x, h.y, h.id === selected ? 17 : 11, 0, Math.PI * 2); ctx.fill(); }
  for(const site of herbs)drawStation(ctx,site,true);
  ctx.restore(); ctx.font = '12px system-ui'; ctx.textAlign = 'center';
  for (const [text, x, y] of (mapId==='forest'?[['密林小径',390,550],['失落遗迹',950,180],['篝火营地',1040,865],['古木桥',1544,310],['苔石林地',1880,650],['蕨叶谷地',700,1180]]:[['1 算术熔岩厅',400,480],['2 摆锤长廊',1088,575],['3 熔火试炼',1810,480],['4 熔岩独木桥 · 向左',1350,1090]])) {
    ctx.fillStyle = '#14251cdd'; ctx.fillRect(ox + x * scale - 43, y * scale - 15, 86, 24); ctx.fillStyle = '#e4e5c6'; ctx.fillText(text, ox + x * scale, y * scale + 2);
  }
  ctx.fillStyle = '#112019ed'; ctx.fillRect(15, VIEW_H - 40, 455, 29); ctx.fillStyle = '#d9dfc8'; ctx.textAlign = 'left'; ctx.font = '11px system-ui'; ctx.fillText('M 返回远征 · 亮点：队伍 · 红点：敌人 · 彩色祭坛：补给', 28, VIEW_H - 21);
}
function draw() {
  if (mapOpen) { drawOverview(); return; }
  const lead = heroes[selected]; camera.x = Math.round(clamp(lead.x - VIEW_W / 2, 0, WORLD_W - VIEW_W)); camera.y = Math.round(clamp(lead.y - VIEW_H / 2, 0, WORLD_H - VIEW_H));
  ctx.clearRect(0, 0, VIEW_W, VIEW_H); ctx.save();
  if (shake) ctx.translate(Math.random() * shake - shake / 2, Math.random() * shake - shake / 2);
  ctx.translate(-camera.x, -camera.y); if (background) ctx.drawImage(background, camera.x, camera.y, VIEW_W, VIEW_H, camera.x, camera.y, VIEW_W, VIEW_H);
  const visible = o => o.x > camera.x - 100 && o.x < camera.x + VIEW_W + 100 && o.y > camera.y - 40 && o.y < camera.y + VIEW_H + 130;
  if(mapId==='catacombs')drawTrials();
  for(const site of herbs)if(visible(site))drawStation(ctx,site);
  const objects = [...obstacles, ...heroes.filter(h=>h.active).map(h => ({ ...h, hero: true })), ...enemies].filter(visible).sort((a, b) => a.y - b.y);
  for (const o of objects) {
    if (o.kind === 'tree') { ctx.drawImage(images.objects, 0, 80, 48, 64, Math.round(o.x - 42), Math.round(o.y - 94), 84, 112); continue; }
    if (o.kind === 'rock') { ctx.drawImage(images.objects, 0, 16, 16, 16, Math.round(o.x - 26), Math.round(o.y - 36), 52, 52); continue; }
    if(o.kind==='pillar'){drawPillar(ctx,o);continue;}
    if (o.kind === 'wall') { ctx.drawImage(images.objects, 32, 0, 16, 16, o.x - 19, o.y - 35, 38, 38); continue; }
    ctx.fillStyle = '#17332566'; ctx.beginPath(); ctx.ellipse(o.x, o.y + 7, o.hero ? 19 : 17, 7, 0, 0, 7); ctx.fill();
    if (o.windup > 0) { ctx.strokeStyle = '#ed9e74'; ctx.lineWidth = 2; ctx.beginPath(); ctx.ellipse(o.x, o.y, o.type === 'demon' ? 30 : o.range, 18, 0, 0, 7); ctx.stroke(); }
    if (o.hero && o.id === selected && o.hp > 0) {
      ctx.strokeStyle = o.color; ctx.lineWidth = 2; ctx.beginPath(); ctx.ellipse(o.x, o.y + 7, 24, 10, 0, 0, 7); ctx.stroke();
      ctx.fillStyle = o.color; ctx.beginPath(); ctx.moveTo(o.x, o.y - 62); ctx.lineTo(o.x - 5, o.y - 70); ctx.lineTo(o.x + 5, o.y - 70); ctx.fill();
    } else if (!o.hero) { ctx.strokeStyle = '#a65c5b'; ctx.lineWidth = 1; ctx.beginPath(); ctx.ellipse(o.x, o.y + 7, 20, 8, 0, 0, 7); ctx.stroke(); }
    if(o.hero&&o.hp>0){for(const [kind,col] of [['power','#ffa453'],['speed','#83e9ba']])if(buffs[kind]>0){ctx.fillStyle=col;for(let i=0;i<5;i++){const a=time*(kind==='power'?3:-4)+i*Math.PI*2/5;ctx.fillRect(o.x+Math.cos(a)*27-2,o.y+Math.sin(a)*10+(kind==='power'?-25:6),4,4);}}}
    sprite(o, o.asset);
    if (o.hp > 0) { ctx.fillStyle = '#17281e'; ctx.fillRect(o.x - 19, o.y - 45, 38, 4); ctx.fillStyle = o.hero ? o.color : '#d47e73'; ctx.fillRect(o.x - 19, o.y - 45, 38 * o.hp / o.maxHp, 4); }
  }
  const glow = ctx.createRadialGradient(camp.x, camp.y + 45, 0, camp.x, camp.y + 45, 70); glow.addColorStop(0, '#ffb65250'); glow.addColorStop(1, '#ffb65200'); ctx.fillStyle = glow; ctx.fillRect(camp.x - 70, camp.y - 25, 140, 140);
  ctx.fillStyle = '#403126'; ctx.fillRect(camp.x - 13, camp.y + 53, 28, 7); ctx.fillStyle = '#ebaa53'; ctx.fillRect(camp.x - 4, camp.y + 31 + Math.sin(time * 12) * 2, 10, 22); ctx.fillStyle = '#f3d695'; ctx.fillRect(camp.x, camp.y + 38, 4, 12);
  if(mapId==='forest'){
  // Camp tents and ruin inscriptions are procedural landmarks, not new character art.
  ctx.fillStyle = '#394731'; ctx.beginPath(); ctx.moveTo(camp.x - 120, camp.y - 28); ctx.lineTo(camp.x - 92, camp.y - 87); ctx.lineTo(camp.x - 45, camp.y - 28); ctx.fill(); ctx.fillStyle = '#c3ae76'; ctx.beginPath(); ctx.moveTo(camp.x - 120, camp.y - 28); ctx.lineTo(camp.x - 92, camp.y - 87); ctx.lineTo(camp.x - 73, camp.y - 28); ctx.fill();
  } else {for(const room of dungeonRooms)for(const [x,y] of [[room.x+30,room.y+40],[room.x+room.w-30,room.y+40]])if(visible({x,y})){ctx.drawImage(images.catTorch,x-16,y-24,32,32);ctx.fillStyle='#ffb85b19';ctx.fillRect(x-32,y-30,64,64);}}
  if(moveTarget){ctx.strokeStyle='#e2e7aa88';ctx.lineWidth=2;ctx.strokeRect(moveTarget.x-7,moveTarget.y-7,14,14);}
  for(const p of particles){ctx.globalAlpha=Math.min(1,p.life/p.max);ctx.fillStyle=p.color;ctx.fillRect(p.x,p.y,p.size,p.size);if(p.kind==='heal'){ctx.fillRect(p.x-3,p.y+1,10,2);ctx.fillRect(p.x+1,p.y-3,2,10);}}ctx.globalAlpha=1;
  for(const b of fireballs){if(b.type==='arrow'){ctx.save();ctx.translate(b.x,b.y-15);ctx.rotate(Math.atan2(b.dy,b.dx)-Math.PI/2);ctx.drawImage(images.TrapBow,48,0,16,16,-12,-12,24,24);ctx.restore();continue;}ctx.fillStyle='#9e2925';ctx.fillRect(b.x-9,b.y-27,18,18);ctx.fillStyle='#ff782e';ctx.fillRect(b.x-7,b.y-25,14,14);ctx.fillStyle='#ffe58a';ctx.fillRect(b.x-4,b.y-22,8,8);for(let i=1;i<=3;i++){ctx.fillStyle=i%2?'#ffad3b':'#d64722';ctx.fillRect(b.x-b.dx/170*i*8-3,b.y-18-b.dy/170*i*8-3,6,6);}}
  for (const e of effects) {
    ctx.globalAlpha = e.life / e.max; ctx.strokeStyle = e.color; ctx.lineWidth = 3; ctx.beginPath();
    if (e.type === 'bolt') { ctx.moveTo(e.x, e.y - 20); ctx.lineTo(e.tx, e.ty - 20); }
    else { const r = e.r * (1 - e.life / e.max * .7); ctx.ellipse(e.x, e.y - 12, r, r * .65, 0, e.type === 'arc' ? -.7 : 0, e.type === 'arc' ? 2.6 : 7); }
    ctx.stroke(); ctx.globalAlpha = 1;
  }
  ctx.font = 'bold 15px monospace'; ctx.textAlign = 'center'; for (const t of texts) { ctx.globalAlpha = Math.min(1, t.life * 2); ctx.fillStyle = t.color; ctx.fillText(t.text, t.x, t.y); } ctx.globalAlpha = 1;
  ctx.restore();
  const dark = mode === 'ready' ? .03 : Math.max(0,Math.sin(time / DAWN * Math.PI)) * .13; ctx.fillStyle = `rgba(10,20,32,${dark})`; ctx.fillRect(0, 0, VIEW_W, VIEW_H);
  const vignette = ctx.createRadialGradient(480, 300, 170, 480, 300, 560); vignette.addColorStop(0, '#0b211000'); vignette.addColorStop(1, '#0b211055'); ctx.fillStyle = vignette; ctx.fillRect(0, 0, VIEW_W, VIEW_H);
  minimap();
  if(mapId==='catacombs'&&mode!=='ready')drawTrialBanner();
}
let last = 0;
function loop(now) { const dt = Math.min(.04, (now - last) / 1000 || 0); last = now; if (mode === 'playing') update(dt); draw(); requestAnimationFrame(loop); }
Promise.all(Object.entries(window.ASSETS).map(([k, src]) => new Promise((resolve, reject) => {
  const im = new Image(); im.onload = () => { images[k] = im; resolve(); }; im.onerror = reject; im.src = src;
}))).then(() => {
  loaded = true;
  document.querySelectorAll('.map-preview').forEach(c=>{applyMap(c.dataset.map);const dc=c.getContext('2d');dc.imageSmoothingEnabled=false;dc.drawImage(background,0,0,WORLD_W,WORLD_H,0,0,c.width,c.height);});
  applyMap(chosenMap);
  for (const [selector, size] of [['.portrait', 46], ['.choice-portrait', 65]]) document.querySelectorAll(selector).forEach((c, i) => { const cx = c.getContext('2d'); cx.imageSmoothingEnabled = false; cx.drawImage(images[specs[i].asset + 'Idle'], 28, 24, 48, 48, 0, 0, size, size); });
  $('#start').disabled = false; $('#start').textContent = '开始远征 →'; updateUI(); requestAnimationFrame(loop);
}).catch(() => { $('#start').disabled = false; $('#characterSelect').classList.add('hidden'); $('#mapSelect').classList.add('hidden'); show('素材加载失败', '请重新打开完整交付目录中的 index.html。', '重试'); $('#start').onclick = () => location.reload(); });
// Read-only diagnostics. They do not change model or expose gameplay controls.
window.gameStatus = () => ({ mode,unlockedEnemies:ENEMY_UNLOCKS.filter(([,at])=>time>=at).map(([type])=>type),mechanisms:mechanismSpecs.map(t=>({...t,...mechanismState[t.id],phase:mechPhase(t),rect:mechRect(t),rowPhases:t.kind==='spikerow'?Array.from({length:t.cells},(_,i)=>rowPhase(t,i)):null,position:t.kind==='saw'?sawPosition(t):{x:t.x,y:t.y}})),companionDamageMultiplier:COMPANION_DAMAGE,beam:{left:BEAM_LEFT,right:BEAM_RIGHT,y:BEAM_Y,exit:BEAM_EXIT,gaps:BEAM_GAPS.map(g=>[...g])},lavaFlowSpeed:LAVA_FLOW_SPEED,fireballs:fireballs.map(b=>({...b})),trial:trial?JSON.parse(JSON.stringify(trial)):null,mapId,chosenMap,mapOpen,moveTarget:moveTarget?{...moveTarget}:null,time,selected,chosen,kills,buffs:{...buffs},particles:particles.length,world:{width:WORLD_W,height:WORLD_H},camera:{...camera},hazards:mapId==='catacombs'?pendulums():[],heroes:heroes.map(({x,y,hp,skill,dash,speed,damage,active,jumpTime,jumpCooldown,pushTime,allyBump,id})=>({x,y,hp,active,jumpTime,jumpCooldown,pushTime,allyBump,skill,dash,speed:speed*(buffs.speed>0?1.45:1),damage:Math.round(damage*(id!==selected?COMPANION_DAMAGE:1)*(buffs.power>0?1.6:1))})),enemies:enemies.map(({x,y,hp,type,entering,station,home,habitat})=>({x,y,hp,type,entering,station,home:home?{...home}:null,habitat})),spawnHistory:spawnHistory.map(e=>({...e})),pickups:herbs.map(e=>({...e,available:time>=e.readyAt})),pickupHistory:pickupHistory.map(e=>({...e})),assets:Object.keys(images).length});
window.mapStatus=()=>{const reach=buildFlow(camp);return {mapId,bridges:bridges.map(b=>({...b})),gates:gates.map(g=>({...g,reachable:reach[cellAt(g.tx,g.ty)]>=0})),obstacles:obstacles.length,landmarks:herbs.map(p=>({x:p.x,y:p.y,type:p.type,region:p.region,reachable:reach[cellAt(p.x,p.y)]>=0}))};};
})();
