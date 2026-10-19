# Explicit isolated visual fixtures; never shipped as production gameplay entrypoints.
from pathlib import Path
root=Path(__file__).resolve().parents[1]
base=(root/'index.html').read_text().replace('href="style.css"','href="../style.css"').replace('src="assets.js"','src="../assets.js"')
base=base.replace('算对一步，闯过熔火。','新怪物与复合机关 · 场景验收').replace('五种新敌人逐渐现身。穿过地刺、锯轮与箭弩，跃过摇摇欲坠的木梁。','独立场景验收，不代表完整通关。P 开始/暂停，M 全图，E 跳跃。')
source=(root/'index.js').read_text().replace("localStorage.setItem('thornbound.trials.v2'","localStorage.setItem('thornbound.test-preview011.v2'")
needle="$('#start').disabled = false; $('#start').textContent = '开始远征 →'; updateUI(); requestAnimationFrame(loop);"
for scene,stage,setup in [('corridor',1,"""heroes[selected].x=1030;heroes[selected].y=790;
for(const [type,x,y]of[['scout',844,670],['wolf',1030,658],['brute',1185,680],['treant',1308,866],['slime',850,880]]){const spec=enemySpecs[type];enemies.push({...spec,type,x,y,maxHp:spec.hp,cool:2,attack:0,windup:0,anim:0,face:1,entering:false,station:null});}
"""),('lava',3,"""heroes[selected].x=1608;heroes[selected].y=BEAM_Y;
mechanismState['crumble-east']={phase:'cracking',timer:.5};
""")]:
 code=f"""$('#start').disabled=false;start();time=42;trial=newTrial({stage});retryTrial();
{setup}
for(const h of heroes)if(h.active&&h.id!==selected){{h.x=heroes[selected].x+35;h.y=heroes[selected].y;}}
spawnClock=6;mode='paused';$('#overlay').classList.add('hidden');updateUI();requestAnimationFrame(loop);"""
 assert needle in source
 html=base.replace('<script src="index.js"></script>','<script>'+source.replace(needle,code)+'</script>')
 (root/f'reports/011-{scene}.html').write_text(html)
 print(f'reports/011-{scene}.html')
