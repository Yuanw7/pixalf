extends RefCounted
const Model=preload("res://map_model.gd")
const HEIGHT=24.0
const Art=preload("res://dungeon_art.gd")
static var slab_texture: CanvasTexture
static func floor_tile(canvas: CanvasItem,c: Vector2i):
 var seed=posmod(c.x*31+c.y*17,61)
 var frame=1 if seed<54 else 2+(seed-54)%7
 canvas.draw_texture_rect(Art.texture("floor_"+str(frame)),Rect2(Vector2(c)*32,Vector2(32,32)),false)
static func pillar(canvas: CanvasItem,at: Vector2):
 canvas.draw_texture_rect_region(Art.texture("column"),Rect2(at-Vector2(16,70),Vector2(32,70)),Rect2(0,4,16,35))
static func slab(canvas: CanvasItem,rect: Rect2):
 if slab_texture==null:
  slab_texture=CanvasTexture.new();slab_texture.diffuse_texture=Art.texture("floor_1")
  slab_texture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;slab_texture.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 # One repeated-texture quad per board tile, rather than 16 draw commands each frame.
 Art.quad(canvas,Transform2D.IDENTITY,rect,Color.WHITE,slab_texture,Rect2(Vector2.ZERO,rect.size/2))
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
 var side="left" if not solid.has(c+Vector2i.LEFT) else "right" if not solid.has(c+Vector2i.RIGHT) else "mid"
 var tint=Color(1,1,1,alpha)
 var face=Art.texture("wall_"+side)
 # Repeat source pixels at 2x instead of stretching bricks vertically.
 var height=rise+26;var y=6-rise
 while height>0:
  var h=minf(32,height)
  canvas.draw_texture_rect_region(face,Rect2(p+Vector2(0,y),Vector2(32,h)),Rect2(0,0,16,h/2),tint)
  y+=h;height-=h
 canvas.draw_texture_rect_region(Art.texture("wall_top_"+side),Rect2(p-Vector2(0,rise),Vector2(32,6)),Rect2(0,13,16,3),tint)
 if front(c,solid) and posmod(c.x*17+c.y*7,19)==0:
  canvas.draw_texture_rect(Art.texture("wall_banner_red"),Rect2(p+Vector2(0,-rise+6),Vector2(32,32)),false,tint)
 elif front(c,solid) and posmod(c.x*7+c.y*13,23)==0:
  var at=p+Vector2(16,16-rise)
  canvas.draw_rect(Rect2(at-Vector2(4,0),Vector2(8,12)),Color(.13,.12,.11,alpha))
  canvas.draw_rect(Rect2(at-Vector2(3,5),Vector2(6,9)),Color(.9,.45,.19,alpha))
  canvas.draw_rect(Rect2(at-Vector2(1,4),Vector2(2,6)),Color(1,.82,.47,alpha))
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
