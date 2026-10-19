from pathlib import Path
import json,base64,struct,hashlib,io
from PIL import Image
root=Path(__file__).resolve().parents[1];original=root/'builds/0.8.0/game'
if not original.exists():original=root/'workshop/demo080'
out=root/'workshop/legacy_rules';art=out/'art';art.mkdir(parents=True,exist_ok=True)
assets=json.loads((original/'assets.js').read_text()[len('window.ASSETS='):-1]);info={}
for key,value in assets.items():
 data=base64.b64decode(value.split(',')[1]);ext='png' if data.startswith(b'\x89PNG') else 'jpg';(art/(key+'.'+ext)).write_bytes(data);info[key]=[*Image.open(io.BytesIO(data)).size,ext]
(out/'assets.json').write_text(json.dumps(info))
s=(original/'index.js').read_text();begin=s.index('Promise.all(');end=s.index('// Read-only diagnostics.',begin);s=s[:begin]+s[end:]
end=s.rfind('})();');s=s[:end]+(root/'scripts/legacy/bridge.js').read_text()+s[end:]
(out/'rules.js').write_text((root/'scripts/legacy/adapter.js').read_text()+s)
(out/'provenance.json').write_text(json.dumps({'source':'builds/0.8.0/game/index.js','sha256':hashlib.sha256((original/'index.js').read_bytes()).hexdigest(),'removed':'asynchronous browser image loading only','added':'Godot render-command recorder and typed input/state bridge','assets':len(info)},indent=2))
print('Extracted',len(info),'original assets; retained original rules functions')
