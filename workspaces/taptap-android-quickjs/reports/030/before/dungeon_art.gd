extends RefCounted
# Original 0x72 frames, kept at a common 2 world pixels per source pixel.
# All transforms are applied to vertices so callers' camera transforms survive.
const ROOT="res://art/dungeon/"
const UNIT=2.0
const INK=Color("222222")
const SKIN=Color("fccba3")
const WEAPONS={"sword":"weapon_regular_sword","axe":"weapon_double_axe","spear":"weapon_spear","kunai":"weapon_knife"}
const GRIPS={"sword":Vector2(5,18),"axe":Vector2(8,19),"spear":Vector2(3,23),"kunai":Vector2(3,11)}
const ENEMIES={"Slime":"tiny_zombie","Monster03":"goblin","Monster00":"masked_orc","Monster02":"big_zombie","Monster01":"ogre","Monster09":"chort","Soldier":"knight_m","Orc":"orc_warrior","Demon_A":"imp"}
static var cache: Dictionary={}
static func warmup():
 # Preload once at startup, so a newly spawned species never does disk I/O mid-fight.
 for actor in ENEMIES.values()+["elf_m"]:
  for action in ["idle","run"]:
   for frame in range(4):texture(actor+"_"+action+"_anim_f"+str(frame))
 for id in WEAPONS.values():texture(id)
static func texture(id: String) -> Texture2D:
 if not cache.has(id):cache[id]=load(ROOT+id+".png")
 return cache[id]
static func quad(canvas: CanvasItem,transform: Transform2D,rect: Rect2,color: Color,tex: Texture2D=null,region: Rect2=Rect2()):
 var points=PackedVector2Array([transform*rect.position,transform*Vector2(rect.end.x,rect.position.y),transform*rect.end,transform*Vector2(rect.position.x,rect.end.y)])
 if tex==null:canvas.draw_colored_polygon(points,color);return
 if not region.has_area():region=Rect2(Vector2.ZERO,tex.get_size())
 var a=region.position/tex.get_size();var b=region.end/tex.get_size()
 canvas.draw_polygon(points,PackedColorArray([color]),PackedVector2Array([a,Vector2(b.x,a.y),b,Vector2(a.x,b.y)]),tex)
static func pixel(canvas: CanvasItem,t: Transform2D,x: float,y: float,w: float,h: float,color: Color):quad(canvas,t,Rect2(x,y,w,h),color)
static func pose(action: String,time: float,direction: String,weapon: String) -> Dictionary:
 var animation="run" if action=="walk" else "idle"
 var frame=int(maxf(time,0)*(10 if action=="walk" else 5))%4
 var bob=([-1,-3,-1,0] if action=="walk" else [0,1,2,1])[frame]
 var hand=Vector2(6,-5+bob);var angle=.22
 # Attack clocks are elapsed seconds in every renderer; preview loops separately.
 var progress=clampf(time/.32,0,1)
 if action=="attack":
  frame=0;bob=0
  var aim=-PI/2 if direction=="north" else PI/2 if direction=="south" else 0.0
  if weapon in ["kunai","spear"]:
   var reach=sin(progress*PI)
   hand=Vector2(5,-6)+Vector2.from_angle(aim)*reach*5
   angle=aim+PI/2
  else:
   angle=lerpf(-1.1,2.6,progress)+aim*.4
   hand=Vector2(5,-6)+Vector2(cos(angle-PI/2),sin(angle-PI/2))*2
 if action=="victory":frame=0;bob=0;hand=Vector2(6,-15);angle=.2
 return {"animation":animation,"frame":frame,"bob":bob,"hand":hand,"angle":angle,"behind":direction=="north"}
static func weapon_transform(body: Transform2D,p: Dictionary,weapon: String) -> Transform2D:
 return body*Transform2D(float(p.angle),p.hand)*Transform2D(0,-GRIPS[weapon])
static func draw_weapon(canvas: CanvasItem,body: Transform2D,p: Dictionary,weapon: String):
 if not WEAPONS.has(weapon):return
 var tex=texture(WEAPONS[weapon])
 quad(canvas,weapon_transform(body,p,weapon),Rect2(Vector2.ZERO,tex.get_size()),Color.WHITE,tex)
static func draw_hand(canvas: CanvasItem,body: Transform2D,p: Dictionary,chest: String):
 var hand: Vector2=p.hand
 # Sleeve joins shoulder to grip, then a foreground glove covers the handle.
 var shoulder=Vector2(3,-6+p.bob)
 var sleeve=Rect2(shoulder,Vector2.ONE).expand(hand).grow(.5)
 quad(canvas,body,sleeve,INK)
 quad(canvas,body,sleeve.grow(-.65),Color("417089") if chest=="plate" else Color("704733"))
 quad(canvas,body,Rect2(hand-Vector2(1.5,1),Vector2(3,3)),INK)
 quad(canvas,body,Rect2(hand-Vector2(.5,0),Vector2(2,1)),SKIN)
static func draw_shield(canvas: CanvasItem,body: Transform2D,bob: float):
 # Pixel stair-step silhouette, in the same palette and grid as the source hero.
 pixel(canvas,body,-6,-9+bob,6,9,INK);pixel(canvas,body,-7,-7+bob,8,5,INK)
 pixel(canvas,body,-5,-8+bob,4,7,Color("417089"));pixel(canvas,body,-6,-6+bob,6,3,Color("417089"))
 pixel(canvas,body,-5,-8+bob,3,1,Color("72d6ce"));pixel(canvas,body,-4,-5+bob,2,2,Color("fdf7ed"))
static func draw_hero(canvas: CanvasItem,outfit: Dictionary,feet: Vector2,action: String,direction: String,time: float,scale: float):
 var p=pose(action,time,direction,outfit.weapon)
 var flip=-1.0 if direction=="west" else 1.0
 var unit=UNIT*scale
 var body=Transform2D(Vector2(flip*unit,0),Vector2(0,unit),feet.round())
 if action=="hurt":
  var fall=clampf(time/.45,0,1)
  body=Transform2D(0,feet.round()-Vector2(0,6*unit*fall))*Transform2D(flip*PI/2*fall,Vector2.ZERO)*Transform2D(Vector2(flip*unit,0),Vector2(0,unit),Vector2.ZERO)
 if p.behind and action!="hurt":draw_weapon(canvas,body,p,outfit.weapon);draw_hand(canvas,body,p,outfit.chest)
 if outfit.shield!="none" and direction=="east":draw_shield(canvas,body,p.bob)
 var suffix="_%s_anim_f%d"%[p.animation,p.frame]
 var knight=texture("knight_m"+suffix)
 var split=21+int(p.bob)
 # The helmet/head and torso use synchronized frame crops, never a baked full outfit.
 var top=texture(("elf_m" if outfit.helmet=="none" else "knight_m")+suffix)
 quad(canvas,body,Rect2(-8,-28,16,split),Color.WHITE,top,Rect2(0,0,16,split))
 quad(canvas,body,Rect2(-8,split-28,16,28-split),Color.WHITE,knight,Rect2(0,split,16,28-split))
 if outfit.chest=="leather":
  pixel(canvas,body,-4,-7+p.bob,8,4,Color("a66b45"));pixel(canvas,body,-4,-7+p.bob,2,4,Color("704733"))
  pixel(canvas,body,-4,-4+p.bob,8,1,Color("4c352e"));pixel(canvas,body,0,-4+p.bob,2,1,Color("facb3e"))
 if outfit.helmet=="barbuta":
  pixel(canvas,body,0,-12+p.bob,6,4,INK);pixel(canvas,body,1,-11+p.bob,5,2,SKIN);pixel(canvas,body,4,-11+p.bob,1,1,Color("417089"))
 if action!="hurt" and not p.behind:draw_weapon(canvas,body,p,outfit.weapon);draw_hand(canvas,body,p,outfit.chest)
 if outfit.shield!="none" and direction!="east":draw_shield(canvas,body,p.bob)
static func draw_enemy(canvas: CanvasItem,asset: String,at: Vector2,moving: bool,time: float,face: float=1,attack: float=0,dead: bool=false,flash: float=0,scale: float=1.0):
 var id=ENEMIES.get(asset,"goblin")
 var tex=texture(id+("_run" if moving else "_idle")+"_anim_f"+str(int(maxf(time,0)*(9 if moving else 5))%4))
 var unit=UNIT*scale
 var lunge=sin(clampf(attack/.3,0,1)*PI)*3
 var transform=Transform2D(Vector2(unit*(-1 if face<0 else 1),0),Vector2(0,unit),at.round()+Vector2(face*lunge,0))
 if dead:transform=Transform2D(PI/2,at-Vector2(0,5))*Transform2D(Vector2(unit,0),Vector2(0,unit),Vector2.ZERO)
 quad(canvas,transform,Rect2(-tex.get_width()/2.0,-tex.get_height(),tex.get_width(),tex.get_height()),Color(1.5,1.3,1.1) if flash>0 else Color(1,1,1,.45 if dead else 1),tex)
static func draw_remains(canvas: CanvasItem,e: Dictionary):
 var id=ENEMIES.get(str(e.asset),"goblin");var tex=texture(id+"_idle_anim_f0")
 var fallen=clampf(float(e.age)/.32,0,1);var alpha=clampf((float(e.life)-float(e.age))/2,0,1)
 var unit=UNIT;var half=tex.get_size()/2;var face=-1.0 if float(e.get("face",1))<0 else 1.0
 var center=Vector2(e.x,e.y)-Vector2(0,lerpf(half.y*unit,4,fallen))
 var t=Transform2D(face*PI/2*fallen,center)*Transform2D(Vector2(unit,0),Vector2(0,unit),Vector2.ZERO)
 quad(canvas,t,Rect2(-half,tex.get_size()),Color(.7,.68,.6,alpha),tex)
