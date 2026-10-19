extends RefCounted
const Model=preload("res://map_model.gd")
const HEIGHT=24.0
# Projection only: authored wall footprints and collision geometry never change.
static func walls(r: Dictionary) -> Dictionary:
 var result={}
 var gates={}
 for o in r.objects:
  if o.kind=="隔板门":gates[Vector2i(o.x,o.y)]=true
 for cell in r.walls:
  var c=Vector2i(cell[0],cell[1])
  if not gates.has(c):result[c]=true
 return result
static func front(c: Vector2i,solid: Dictionary) -> bool:return not solid.has(c+Vector2i.DOWN)
static func wall(canvas: CanvasItem,c: Vector2i,solid: Dictionary,alpha: float=1.0,gates: Dictionary={}):
 var rise=0.0 if gates.has(c+Vector2i.UP) else HEIGHT
 var p=Vector2(c)*32
 var top=Color("727d70");top.a=alpha
 var shade=Color("36413b");shade.a=alpha
 var face=Color("536257");face.a=alpha
 # The lower edge is the true blocking footprint; the wall rises above it.
 if front(c,solid):
  canvas.draw_rect(Rect2(p+Vector2(0,8),Vector2(32,24)),face)
  for row in range(3):
   var y=p.y+8+row*8
   canvas.draw_line(Vector2(p.x,y),Vector2(p.x+32,y),shade,2)
   var offset=0 if row%2==0 else 8
   for x in range(offset,32,16):canvas.draw_line(Vector2(p.x+x,y),Vector2(p.x+x,y+8),shade,2)
  canvas.draw_line(p+Vector2(0,31),p+Vector2(32,31),Color(0.09,0.13,0.12,alpha),2)
 else:canvas.draw_rect(Rect2(p+Vector2(0,8),Vector2(32,24)),top.darkened(0.22))
 canvas.draw_rect(Rect2(p-Vector2(0,rise),Vector2(32,rise+8)),top)
 if not solid.has(c+Vector2i.RIGHT):
  canvas.draw_rect(Rect2(p+Vector2(26,-rise),Vector2(6,rise+32)),shade)
 if not solid.has(c+Vector2i.LEFT):
  canvas.draw_rect(Rect2(p+Vector2(0,-rise),Vector2(3,rise+32)),shade.lightened(0.12))
 canvas.draw_line(p+Vector2(3,-rise+2),p+Vector2(26,-rise+2),Color(0.64,0.68,0.59,alpha),2)
 if front(c,solid):
  canvas.draw_rect(Rect2(p+Vector2(0,4),Vector2(32,5)),shade)
  canvas.draw_line(p+Vector2(0,4),p+Vector2(30,4),Color(0.63,0.67,0.58,alpha),2)
 # Small wear marks are deterministic, so paused scenes do not shimmer.
 if rise>0 and (c.x+c.y*3)%4==0:canvas.draw_rect(Rect2(p+Vector2(12,-14),Vector2(5,2)),top.darkened(0.15))
static func shadows(canvas: CanvasItem,r: Dictionary,solid: Dictionary):
 for c in solid:
  if front(c,solid) and Model.inside(r,c+Vector2i.DOWN):
   canvas.draw_rect(Rect2(Vector2(c)*32+Vector2(0,32),Vector2(32,9)),Color(0,0,0,0.3))
   canvas.draw_rect(Rect2(Vector2(c)*32+Vector2(2,41),Vector2(30,3)),Color(0,0,0,0.13))

static func door_cells(r: Dictionary) -> Dictionary:
 var gates={}
 for o in r.objects:
  if o.kind=="隔板门":gates[Vector2i(o.x,o.y)]=true
 return gates
