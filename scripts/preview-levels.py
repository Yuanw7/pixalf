# Explicit isolated visual fixtures; never shipped as production gameplay entrypoints.
from pathlib import Path
root=Path(__file__).resolve().parents[1]
base=(root/'index.html').read_text().replace('href="style.css"','href="../style.css"').replace('src="assets.js"','src="../assets.js"')
base=base.replace('算对一步，闯过熔火。','复合机关四关 · 场景验收').replace('地牢四连关：算术地砖、摆锤、熔火试炼与熔岩独木桥。五种新敌人逐渐现身。穿过地刺、锯轮与箭弩，跃过摇摇欲坠的木梁。','每关独立取景，不代表完整通关。火焰喷射器、鼓风机、炸弹、定向墙刺、连排地刺、塌落拱顶为0.8.0新增。')
base=base.replace('BUILD 0.7.0 · LOCAL PROTOTYPE','BUILD 0.8.0 · SCENARIO')
source=(root/'index.js').read_text().replace("localStorage.setItem('thornbound.trials.v2'","localStorage.setItem('thornbound.test-preview012.v2'")

def spike(t,off): c=(t+off)%4.6; return 'rest' if c<2.6 else 'warning' if c<3.3 else 'active'
def wall(t,off): c=(t+off)%3.6; return 'rest' if c<2.1 else 'warning' if c<2.6 else 'active'
def row(t,off,i): c=(t+off+i*.26)%3.2; return 'rest' if c<2.0 else 'warning' if c<2.4 else 'active'
def saw(t,off): return 'active'

# (id, kind, offset, cells) for the time-driven hazards of each scene.
TIME_DRIVEN={
 'hall':[('spike-entry','spike',0,1),('row-hall','row',.8,3),('wallspike-hall','wall',1.4,1)],
 'corridor':[('spike-corridor-a','spike',.4,1),('spike-corridor-b','spike',2.4,1),('saw-corridor','saw',0,1),
             ('wallspike-corridor','wall',.2,1),('row-corridor','row',1.1,3)],
 'trials':[('spike-final','spike',1.6,1),('row-trials','row',.4,3),('wallspike-trials','wall',.7,1)],
 'beam':[],
 'lava':[],
 'doll':[('band-top','band',0,1),('band-upper','band',.6,1),('band-lower','band',1.2,1),('band-bottom','band',1.8,1)],
}
def band(t,off): c=(t+off)%4.6; return 'rest' if c<2.7 else 'warning' if c<3.4 else 'fire'
def phase_of(t,kind,off,i):
 if kind=='spike': return spike(t,off)
 if kind=='band': return band(t,off)
 if kind=='wall': return wall(t,off)
 if kind=='row': return row(t,off,i)
 return 'active'
def score(t,scene):
 live=[(k,o,c) for _,k,o,c in TIME_DRIVEN[scene]]
 n=0
 for k,o,c in live:
  for i in range(c):
   p=phase_of(t,k,o,i)
   n+= 2 if p in ('active','fire') else 1 if p=='warning' else 0
 return n
def best_time(scene):
 return max((round(t*.05,2) for t in range(0,1200)),key=lambda t:score(t,scene))

# Overrides put the state-machine hazards where the screenshot can show them.
STATES={
 'hall':[("flame-hall","fire",.7),("bomb-hall","fuse",.5)],
 'corridor':[("fan-corridor","gust",1.0),("bomb-corridor","fuse",.5),("rockfall-corridor","crack",.5)],
 'trials':[("flame-trials-a","fire",.7),("flame-trials-b","warn",.4),("bomb-trials","fuse",.6),("rockfall-gate","crack",.5),("rockfall-trials","fall",.3)],
 'beam':[("bomb-beam","fuse",.5),("fan-beam","gust",1.0)],
 'lava':[],
 'doll':[("doll","red",2.0)],
}
SCENES=[
 ('hall',0,686,830,"""for(const [id,phase,timer] of STATES)if(mechanismState[id])mechanismState[id]={phase,timer};
enemies.push({...enemySpecs.slime,type:'slime',x:300,y:700,hp:38,maxHp:38,cool:2,attack:0,windup:0,anim:0,face:1,entering:false,station:null});
"""),
 ('corridor',1,1150,780,"""for(const [id,phase,timer] of STATES)if(mechanismState[id])mechanismState[id]={phase,timer};
for(const [type,x,y]of[['scout',900,690],['wolf',1290,830],['brute',1000,860]]){const spec=enemySpecs[type];enemies.push({...spec,type,x,y,hp:spec.hp,maxHp:spec.hp,cool:2,attack:0,windup:0,anim:0,face:1,entering:false,station:null});}
"""),
 ('trials',3,2150,752,"""for(const [id,phase,timer] of STATES)if(mechanismState[id])mechanismState[id]={phase,timer};
for(const [type,x,y]of[['treant',2400,880],['slime',2150,620]]){const spec=enemySpecs[type];enemies.push({...spec,type,x,y,hp:spec.hp,maxHp:spec.hp,cool:2,attack:0,windup:0,anim:0,face:1,entering:false,station:null});}
"""),
 ('doll',2,1750,830,"""for(const [id,phase,timer] of STATES)if(mechanismState[id])mechanismState[id]={phase,timer};
mechanismState['band-top']={phase:'rest',timer:0};
mechanismState['band-bottom']={phase:'fire',timer:.6};
"""),
 ('beam',4,1700,1264,"""for(const [id,phase,timer] of STATES)if(mechanismState[id])mechanismState[id]={phase,timer};
mechanismState['crumble-mid']={phase:'cracking',timer:.5};
"""),
 ('lava',4,900,1264,"""mechanismState['crumble-west']={phase:'cracking',timer:.5};
mechanismState['fan-beam']={phase:'idle',timer:1};
for(const [type,x,y]of[['wolf',1240,1264]]){const spec=enemySpecs[type];enemies.push({...spec,type,x,y,hp:spec.hp,maxHp:spec.hp,cool:2,attack:0,windup:0,anim:0,face:1,entering:false,station:null});}
"""),
]
needle="$('#start').disabled = false; $('#start').textContent = '开始远征 →'; updateUI(); requestAnimationFrame(loop);"
assert needle in source
for scene,stage,hx,hy,extra in SCENES:
 t=best_time(scene)
 states=','.join(f"['{i}','{p}',{v}]" for i,p,v in STATES[scene])
 setup=extra.replace('STATES','['+states+']')
 code=f"""$('#start').disabled=false;start();time={t};trial=newTrial({stage});retryTrial();time={t};
heroes[selected].x={hx};heroes[selected].y={hy};
{setup}
for(const h of heroes)if(h.active&&h.id!==selected){{h.x=heroes[selected].x+38;h.y=heroes[selected].y+12;}}
spawnClock=900;guardClock=900;mode='paused';$('#overlay').classList.add('hidden');updateUI();requestAnimationFrame(loop);"""
 html=base.replace('<script src="index.js"></script>','<script>'+source.replace(needle,code)+'</script>')
 (root/f'reports/012-{scene}.html').write_text(html)
 print(f'reports/012-{scene}.html  stage={stage} time={t} phases='+','.join(phase_of(t,k,o,i) for _,k,o,c in TIME_DRIVEN[scene] for i in range(c)))
