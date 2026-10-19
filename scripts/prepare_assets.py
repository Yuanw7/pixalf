from pathlib import Path
import base64,json
root=Path(__file__).resolve().parents[1]
pack=root/'assets/packs'
data={}
for name in ['Soldier','Orc','Demon_A']:
 for state in ['Idle','Walk','Attack01','Hurt','Death']:
  p=next(p for p in pack.rglob(name+'_'+state+'.png') if 'with shadows' not in str(p))
  data[name+state]='data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode()
for key,file in [('grass','sprites/tilesets/grass.png'),('objects','sprites/objects/objects.png'),('Slime','sprites/characters/slime.png'),('decor','sprites/tilesets/decor_16x16.png')]:
 p=pack/'mystic_woods_free_2.2'/file;data[key]='data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode()
# Additional user-supplied catacomb tiles and consumable icons.
for key,file in [('catTiles','mainlevbuild.png'),('catDecor','decorative.png'),('catTorch','torch_1.png')]:
 p=pack/'RF_Catacombs_v1.0'/file;data[key]='data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode()
for key,file in [('potionHealth','icon1.png'),('potionPower','icon13.png'),('potionSpeed','icon5.png')]:
 p=pack/'Icons'/file;data[key]='data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode()
for key,file in [('LavaTexture','lava-reference.png')]:
 p=root/'assets/custom/009'/file;data[key]='data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode()
for n in ['00','01','02','03','09']:
 p=pack/'TopdownMonstersPart1Free/Free'/(n+'.png');data['Monster'+n]='data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode()
# Trap and Weapon originals. Only uncropped source sheets are embedded; frame
# contracts live in index.js so a frame can never be re-cut silently.
for key,file in [('TrapSpikes','Spike_B.png'),('TrapSaw','Suriken.png'),('TrapBow','Shooter_Arrow_Trap.png'),('TrapPlatform','FallingPlatfrom.png'),('TrapMace','SpikeBall.png'),
                 ('TrapFireBox','FireBox.png'),('TrapFire','Fire.png'),('TrapFan','Fan.png'),('TrapBomb','Bomb.png'),
                 ('TrapRock','FallingRock.png'),('TrapBrick','Brick1.png'),('TrapWall','Trap_Spike.png')]:
 p=pack/'TrapAndWeapon/Trap and Weapon'/file;data[key]='data:image/png;base64,'+base64.b64encode(p.read_bytes()).decode()
(root/'assets.js').write_text('window.ASSETS='+json.dumps(data)+';')
