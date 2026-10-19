"""Isolated visual scenes, never used by the production entry point."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
base=(root/'index.html').read_text().replace('href="style.css"','href="../style.css"').replace('src="assets.js"','src="../assets.js"')
source=(root/'index.js').read_text().replace("localStorage.setItem('thornbound.trials.v3'", "localStorage.setItem('thornbound.preview015.v3'")
needle="$('#start').disabled = false; $('#start').textContent = '开始远征 →'; updateUI(); requestAnimationFrame(loop);"
assert needle in source
for name,stage,x,y in [('doll',2,1740,840),('keeper',2,1900,864),('bomb',2,1968,864),('escape',2,2000,800),('door',0,624,808)]:
    setup=f"""$('#start').disabled=false;start();trial=newTrial({stage});retryTrial();
heroes[selected].x={x};heroes[selected].y={y};
for(const h of heroes)if(h.active&&h.id!==selected){{h.x={x}-35;h.y={y}+26;}}
spawnClock=Infinity;guardClock=Infinity;time=2.2;
{"trial.ready=true;trial.round=trial.required;trial.phase='ready';" if name=='door' else ''}
{"mechanismState.doll.phase='fuse';mechanismState.doll.timer=2.5;" if name=='bomb' else ''}
mode='paused';$('#overlay').classList.add('hidden');updateUI();requestAnimationFrame(loop);"""
    (root/f'reports/015-{name}.html').write_text(base.replace('<script src="index.js"></script>','<script>'+source.replace(needle,setup)+'</script>'))
