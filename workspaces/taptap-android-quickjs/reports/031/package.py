from pathlib import Path
import json,zipfile,hashlib,datetime
base=Path(__file__).resolve().parents[2]
report=base/'reports/031'
log=(report/'regression.log').read_text()
assert 'WORKSHOP 031 TESTS 1730 checks / PASS' in log and 'SCRIPT ERROR' not in log and 'FAIL ' not in log
# Runtime remains in its fixed directory; this is an archive for review/rollback, not a new launcher.
with zipfile.ZipFile(report/'SOURCE.zip','w',zipfile.ZIP_DEFLATED) as z:
 for prefix in ['game','scripts']:
  for f in (base/prefix).rglob('*'):
   if f.is_file() and '.godot' not in f.parts and f.suffix!='.import':z.write(f,f.relative_to(base))
 for rel in ['README.md','00-从这里开始.txt','启动实验版.command','AGENTS.md','MULTIPLAYER_PLAN.md','docs/031-ROOMS.md']:
  z.write(base/rel,rel)
 for f in sorted((report/'before').glob('*')):z.write(f,f.relative_to(base))
with zipfile.ZipFile(report/'SOURCE.zip') as z:assert z.testzip() is None
files={}
for folder in [base/'game',report/'before']:
 for f in folder.rglob('*'):
  if f.is_file() and '.godot' not in f.parts and f.suffix!='.import':files[str(f.relative_to(base))]=hashlib.sha256(f.read_bytes()).hexdigest()
for rel in ['reports/031/SOURCE.zip','reports/031/regression.log','reports/031/tests.log','reports/031/wood.png','reports/031/math.png','reports/031/multi.png','docs/031-ROOMS.md','README.md','MULTIPLAYER_PLAN.md','启动实验版.command','00-从这里开始.txt']:
 f=base/rel;files[rel]=hashlib.sha256(f.read_bytes()).hexdigest()
manifest={'iteration':'031','builtAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'status':'local candidate; technical checks passed; user experience approval pending','fixedLauncher':str(base/'启动实验版.command'),'engine':'runtime/Godot, unchanged','tests':'1730 full checks PASS; 37 new checks, includes normal input two-room completion','visualQA':['wood.png','math.png','multi.png'],'multiplayer':'design only; no networking implemented','dataCompatibility':'schema 2; old challenge types preserved; new spatial types require this update; existing user saves not cleared','rollback':'before/ contains changed original files; SOURCE.zip preserves this complete source snapshot','files':files}
(report/'DELIVERY.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print('Source archive integrity passed; checksum manifest saved; fixed launcher unchanged.')
