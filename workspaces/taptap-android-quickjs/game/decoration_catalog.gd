extends RefCounted
const KINDS=["石柱","雕像","木箱","陶罐","碎石","烛台"]
const SHEETS={
 "石柱":["res://art/dungeon/column.png",Rect2(0,4,16,35),Vector2(32,70)],
 "雕像":["res://legacy_rules/art/catDecor.png",Rect2(80,112,32,48),Vector2(36,54)],
 "木箱":["res://art/dungeon/crate.png",Rect2(0,0,16,24),Vector2(32,48)],
 "陶罐":["res://legacy_rules/art/catDecor.png",Rect2(176,128,16,16),Vector2(24,24)],
 "碎石":["res://legacy_rules/art/catDecor.png",Rect2(144,144,32,16),Vector2(36,18)],
 "烛台":["res://art/decor/candle.png",Rect2(0,0,7,14),Vector2(14,28)]}
static var cache={}
static func known(kind: String) -> bool:return KINDS.has(kind)
static func icon(kind: String) -> Texture2D:
 if not cache.has(kind):
  var a=AtlasTexture.new();a.atlas=load(SHEETS[kind][0]);a.region=SHEETS[kind][1];cache[kind]=a
 return cache[kind]
static func draw_prop(canvas: CanvasItem,o: Dictionary,clock: float):
 var p=Vector2(o.x*32+16,o.y*32+25);var size=SHEETS[o.kind][2]
 if o.kind=="碎石":
  for piece in [Rect2(-13,-9,8,6),Rect2(-2,-14,9,8),Rect2(7,-5,6,4)]:
   var rect=Rect2(p+piece.position,piece.size)
   canvas.draw_rect(Rect2(rect.position+Vector2(2,2),rect.size),Color("252d29"))
   canvas.draw_rect(rect,Color("798574"));canvas.draw_line(rect.position,rect.position+Vector2(rect.size.x,0),Color("a3ab94"),1)
  return
 if o.kind!="碎石":canvas.draw_circle(p,10,Color(0,0,0,0.24))
 canvas.draw_texture_rect(icon(o.kind),Rect2(p-Vector2(size.x/2,size.y),size),false,Color.WHITE if o.kind in ["木箱","石柱"] else Color(1.3,1.25,1.2))
 if o.kind=="烛台":
  var tip=p-Vector2(0,size.y-3)
  canvas.draw_circle(tip,18,Color(0.94,0.62,0.20,0.06))
  canvas.draw_rect(Rect2(tip+Vector2(-2,-3-sin(clock*6)),Vector2(4,6)),Color("f0bd69"))
