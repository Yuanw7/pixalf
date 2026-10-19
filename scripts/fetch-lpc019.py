"""Fetch pinned, unmodified LPC layers and retain per-file author/license records."""
from pathlib import Path
import urllib.request,concurrent.futures,csv,io,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
COMMIT='58ce1aa479e4df32845a73a5d0afc221c3a893c2'
BASE=f'https://raw.githubusercontent.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator/{COMMIT}/'
DEST=ROOT/'workshop/art/lpc';DEST.mkdir(parents=True,exist_ok=True)
A=['walk','slash','thrust','hurt']
# id, source directory, z, source animations; oversized attack layers stay separate.
LAYERS=[
 ('body','body/bodies/male',10,A),('head','head/heads/human/male',100,A),
 ('pants','legs/pants/male',20,A),('boots','feet/boots/revised/male',25,A),
 ('plate','torso/armour/plate/male',60,A),('leather','torso/armour/leather/male',60,A),
 ('armet','hat/helmet/armet/adult',130,A),('barbuta','hat/helmet/barbuta/male',130,A),
 ('roundshield','shield/round',120,A),
 ('sword_front','weapon/sword/longsword',140,['walk','hurt']),('sword_back','weapon/sword/longsword/universal_behind',9,['walk','hurt']),
 ('sword_attack_front','weapon/sword/longsword/attack_slash',150,['slash_oversize']),('sword_attack_back','weapon/sword/longsword/attack_slash/behind',8,['slash_oversize']),
 ('axe_front','weapon/blunt/waraxe',140,['walk','hurt']),('axe_back','weapon/blunt/waraxe/behind',9,['walk','hurt']),
 ('axe_attack_front','weapon/blunt/waraxe/attack_slash',150,['slash_oversize']),('axe_attack_back','weapon/blunt/waraxe/attack_slash/behind',8,['slash_oversize']),
 ('spear_front','weapon/polearm/spear/foreground',140,['walk','thrust','hurt']),('spear_back','weapon/polearm/spear/background',9,['walk','thrust','hurt'])]
def fetch(path):return urllib.request.urlopen(BASE+path,timeout=35).read()
credits=fetch('CREDITS.csv').decode();rows={r['filename']:r for r in csv.DictReader(io.StringIO(credits))};jobs=[]
for id,prefix,z,anims in LAYERS:
 for anim in anims:jobs.append((id,prefix,z,anim))
def download(job):
 id,prefix,z,anim=job;source=prefix+'/'+anim+'.png';credit=rows[source]
 if id.startswith('sword'):source=prefix+'/'+anim+'/longsword.png'
 if id.startswith('axe'):source=prefix+'/'+anim+'/waraxe.png'
 if id.startswith('spear'):source=prefix+'/'+anim+'/steel.png'
 if '_attack_' in id:source=prefix+('/longsword.png' if id.startswith('sword') else '/waraxe.png')
 dest=DEST/id/(anim+'.png');dest.parent.mkdir(parents=True,exist_ok=True)
 
 try:data=dest.read_bytes() if dest.exists() and id!="boots" else fetch('spritesheets/'+source)
 except urllib.error.HTTPError as e:
  if e.code==404 and anim=="hurt":print("No hurt layer upstream:",source);return None
  raise RuntimeError(source) from e
 dest.write_bytes(data)
 from PIL import Image
 with Image.open(dest) as im:size=list(im.size)
 return {'id':id,'source':source,'file':str(dest.relative_to(ROOT/'workshop')),'z':z,'animation':anim,'size':size,'sha256':hashlib.sha256(data).hexdigest(),'credit':credit}
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as ex:records=[r for r in ex.map(download,jobs) if r is not None]
(DEST/'manifest.json').write_text(json.dumps({'commit':COMMIT,'repository':BASE,'files':records},ensure_ascii=False,indent=2))
with (DEST/'CREDITS.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=['filename','notes','authors','licenses','urls']);w.writeheader();w.writerows(r['credit'] for r in records)
authors=sorted(set(a.strip() for r in records for a in r['credit']['authors'].split(',')))
(DEST/'CREDITS.txt').write_text('LPC modular character artwork\nRepository: https://github.com/LiberatedPixelCup/Universal-LPC-Spritesheet-Character-Generator\nPinned commit: '+COMMIT+'\n\nAuthors:\n'+'\n'.join(authors)+'\n\nPer-file attribution, original links and license alternatives: CREDITS.csv.\nSelected license: OGA-BY 3.0 when listed; otherwise CC-BY-SA 3.0. Images are unmodified upstream PNGs; no image merging or recoloring. Source PNGs remain accessible in this folder and source.zip.\nOGA-BY: https://static.opengameart.org/OGA-BY-3.0.txt\nCC-BY-SA 3.0: https://creativecommons.org/licenses/by-sa/3.0/\nGodot importer plugin has its own MIT license under addons/LPCAnimatedSprite/LICENSE.\n')
(DEST/'README.md').write_text('# LPC modular character subset\n\n019: adult male body; four-direction walk/slash/thrust and south-facing hurt. Runtime idle uses walk frame 0. Equipment layers are independent PNGs, not precomposed outfits. Oversized weapons retain their original frame dimensions.\n\n19 layers; only upstream frames actually available are imported. See manifest.json for actual counts, dimensions, hashes, source paths and author/license metadata. Never mix arbitrary LPC revisions without checking rows, body size and animation compatibility.\n\nSee CREDITS.txt and CREDITS.csv. Art filenames are not item inventory definitions; character_catalog.gd declares compatible equipment.\n')
print('Fetched',len(records),'PNGs;',len(authors),'credited authors;',COMMIT)
for r in records:
 if r['id'].endswith('front'):print(r['id'],r['animation'],r['size'])
