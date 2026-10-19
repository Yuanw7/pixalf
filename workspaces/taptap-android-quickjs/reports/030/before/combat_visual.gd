extends RefCounted
const Dungeon=preload("res://dungeon_art.gd")
const KNIFE=preload("res://art/dungeon/weapon_knife.png")
const ICE=Color("91dce5")
const WHITE=Color("fff5d8")
static func point(at: Vector2,angle: float,radius: float) -> Vector2:
 return (at+Vector2(cos(angle),sin(angle))*radius).snapped(Vector2(2,2))
static func spark(canvas: CanvasItem,at: Vector2,t: float,tint: Color=WHITE):
 var opacity=clampf(1-t,0,1)
 for i in range(8):
  var angle=i*TAU/8+.15
  var p=point(at,angle,5+t*(22+i%3*8))
  canvas.draw_rect(Rect2(p,Vector2(4 if i%2==0 else 2,4 if i%2==0 else 2)),Color(tint,opacity))
 if t<.45:
  var w=12*(1-t/.45)
  canvas.draw_rect(Rect2(at-Vector2(w,2),Vector2(w*2,4)),Color(WHITE,opacity))
  canvas.draw_rect(Rect2(at-Vector2(2,w),Vector2(4,w*2)),Color(WHITE,opacity))
static func air(canvas: CanvasItem,effects: Array,shots: Array):
 for p in shots:
  var at=Vector2(p.x,p.y-20);var direction=Vector2(p.dx,p.dy)
  for i in range(1,5):
   var tail=(at-direction*(i*9)).snapped(Vector2(2,2))
   canvas.draw_rect(Rect2(tail-Vector2(2,2),Vector2(4,4)),Color(ICE,(5-i)*.17))
  # Same single blade as the held weapon; its source tip points north.
  var transform=Transform2D(direction.angle()+PI/2,at)*Transform2D(Vector2(2,0),Vector2(0,2),Vector2.ZERO)
  Dungeon.quad(canvas,transform,Rect2(-KNIFE.get_size()/2,KNIFE.get_size()),Color.WHITE,KNIFE)
 for e in effects:
  var t=clampf(float(e.age)/float(e.life),0,1);var at=Vector2(e.x,e.y);var angle=float(e.get("angle",0));var opacity=1-t
  match e.kind:
   "slash":
    var radius=float(e.r)*(.65+t*.3)
    for layer in range(2):
     var polygon=PackedVector2Array();var start=angle-1.4+t*.7;var sweep=2.2
     var outer=radius-layer*5
     for i in range(13):polygon.append(point(at,start+sweep*i/12,outer))
     for i in range(12,-1,-1):polygon.append(point(at,start+sweep*i/12,outer-(13-layer*6)*sin(PI*i/12)))
     canvas.draw_colored_polygon(polygon,Color(ICE if layer==0 else WHITE,opacity))
    for i in range(4):canvas.draw_rect(Rect2(point(at,angle+.9-i*.3,radius+6+i*3),Vector2(3,3)),Color(ICE,opacity))
   "thrust":
    var direction=Vector2.from_angle(angle);var side=direction.orthogonal();var end=at+direction*float(e.r)*(.55+.45*t)
    canvas.draw_colored_polygon(PackedVector2Array([at+side*5,end+side*3,end+direction*14,end-side*3,at-side*5]),Color(ICE,opacity))
    canvas.draw_line(at+direction*16,end+direction*12,Color(WHITE,opacity),3,false)
    for i in [-1,1]:canvas.draw_line(at+side*i*11,end-direction*28+side*i*11,Color(WHITE,opacity*.6),2,false)
   "hit","launch","wall":spark(canvas,at,t,Color("cfaf78") if e.kind=="wall" else WHITE)
static func floor_remains(canvas: CanvasItem,remains: Array,_textures: Dictionary):
 for e in remains:
  var at=Vector2(e.x,e.y);var age=float(e.age);var alpha=clampf((float(e.life)-age)/2,0,1)
  canvas.draw_rect(Rect2(at-Vector2(18,3),Vector2(36,9)),Color(.09,.08,.08,.28*alpha))
  Dungeon.draw_remains(canvas,e)
  if age<.35:spark(canvas,at-Vector2(0,8),age/.35,Color("a5aa93"))
static func victory_height(time: float) -> float:
 if time<.16:return -3*sin(time/.16*PI)
 if time<.72:return 24*sin((time-.16)/.56*PI)
 if time<1.22:return 13*sin((time-.72)/.5*PI)
 return 0
static func victory(canvas: CanvasItem,at: Vector2,time: float):
 if time<.12:return
 var alpha=clampf((3.0-time)/.6,0,1)
 # Gold completion seal and outward square confetti, matching the dungeon palette.
 var top=at+Vector2(0,-85-minf(time*28,16))
 canvas.draw_colored_polygon(PackedVector2Array([top+Vector2(-26,0),top+Vector2(-19,-19),top+Vector2(0,-12),top+Vector2(19,-19),top+Vector2(26,0),top+Vector2(24,18),top+Vector2(-24,18)]),Color(.72,.52,.2,.65*alpha))
 for i in range(18):
  var clock=fmod(time+float(i)*.07,1.4);var theta=float(i)*2.399
  var p=at+Vector2(cos(theta)*clock*48,-30-clock*90+clock*clock*38)
  canvas.draw_rect(Rect2(p.snapped(Vector2(2,2)),Vector2(3,5)),Color(WHITE if i%3==0 else Color("d8b568"),alpha*(1-clock/1.4)))
 var font=canvas.get_theme_default_font() if canvas is Control else ThemeDB.fallback_font
 canvas.draw_string(font,top+Vector2(-24,10),"完成",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color(WHITE,alpha))
