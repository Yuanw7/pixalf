# Isolated visual QA fixture. Production files and campaign progress are not changed.
from pathlib import Path
root=Path(__file__).resolve().parents[1]
html=(root/'index.html').read_text().replace('href="style.css"','href="../style.css"').replace('src="assets.js"','src="../assets.js"')
html=html.replace('带上一名随从，跃过三处断桥，躲开重锤与火元素的击退。','独立场景验收；不代表完成前三关。E 跳跃，P 开始/暂停。')
html=html.replace('算对一步，闯过熔火。','熔岩与火元素 · 场景验收').replace('地牢四连关：算术地砖、摆锤、熔火试炼与熔岩独木桥。带上一名随从，跳过断口，边战边闯。','独立场景验收：慢速岩浆、三处断桥、锤头与火元素。E 跳跃，P 开始/暂停。')
source=(root/'index.js').read_text()
needle="$('#start').disabled = false; $('#start').textContent = '开始远征 →'; updateUI(); requestAnimationFrame(loop);"
assert needle in source
source=source.replace(needle,"""$('#start').disabled=false;start();trial=newTrial(3);retryTrial();
heroes[selected].x=1584;heroes[selected].y=BEAM_Y;
for(const h of heroes)if(h.active&&h.id!==selected){h.x=1620;h.y=BEAM_Y;}
spawnClock=8;time=.6;enemies=[{...enemySpecs.fire,type:'fire',x:1740,y:1220,maxHp:52,cool:1.2,attack:0,windup:0,anim:0,face:-1,entering:false,station:null}];mode='paused';$('#overlay').classList.add('hidden');updateUI();requestAnimationFrame(loop);""")
source=source.replace("localStorage.setItem('thornbound.trials.v2'","localStorage.setItem('thornbound.test-preview009.v2'")
html=html.replace('<script src="index.js"></script>','<script>'+source+'</script>')
(root/'reports/009-preview.html').write_text(html)
print('reports/009-preview.html')
