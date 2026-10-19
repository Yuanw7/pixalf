# Isolated visual QA fixture. Production files and campaign progress are not changed.
from pathlib import Path
root=Path(__file__).resolve().parents[1]
html=(root/'index.html').read_text().replace('href="style.css"','href="../style.css"').replace('src="assets.js"','src="../assets.js"')
html=html.replace('算对一步，闯过熔火。','独木桥 · 场景验收').replace('地牢四连关：算术地砖、摆锤、熔火试炼与熔岩独木桥。带上一名随从，跳过断口，边战边闯。','独立测试场景：E 跳跃，向左跨越断口。这里的截图不代表完成前三关。')
source=(root/'index.js').read_text()
needle="$('#start').disabled = false; $('#start').textContent = '开始远征 →'; updateUI(); requestAnimationFrame(loop);"
assert needle in source
source=source.replace(needle,"""$('#start').disabled=false;start();trial=newTrial(3);retryTrial();
heroes[selected].x=1584;heroes[selected].y=BEAM_Y;
for(const h of heroes)if(h.active&&h.id!==selected){h.x=1620;h.y=BEAM_Y;}
spawnClock=8;mode='paused';show('第四关场景验收','E 起跳，然后向左跨过断口；R 可重试本关。测试场景不写入正式通关记录。','开始验收');updateUI();requestAnimationFrame(loop);""")
source=source.replace("localStorage.setItem('thornbound.trials.v2'","localStorage.setItem('thornbound.test-preview.v2'")
html=html.replace('<script src="index.js"></script>','<script>'+source+'</script>')
(root/'reports/008-preview.html').write_text(html)
print('reports/008-preview.html')
