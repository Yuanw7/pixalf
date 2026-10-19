extends Control
const Combat=preload("res://combat_visual.gd")
var victorious=false
var victory_time=0.0
const Scenery=preload("res://room_scenery.gd")
var depth_walls: Dictionary={}
var depth_gates: Dictionary={}
var depth_background=false
const Character=preload("res://character_catalog.gd")
var last_draw_usec=0
var commands: Array=[]
var textures: Dictionary={}
var gradients: Dictionary={}
var ellipse_cache: Dictionary={}
var defeated=false
var defeat_time=0.0
var outfit=Character.DEFAULT.duplicate()
var font: Font
var color_cache={}
func matrix(m: Array) -> Transform2D:return Transform2D(Vector2(m[0],m[1]),Vector2(m[2],m[3]),Vector2(m[4],m[5]))
func rectangle(a: Array) -> Rect2:return Rect2(a[0],a[1],a[2],a[3])
func paint_color(value,alpha: float) -> Color:
 var key=str(value)
 if color_cache.size()>1024:color_cache.clear()
 if not color_cache.has(key):
  var color=Color.WHITE
  if value is String:
   if value.begins_with("rgba"):
    var parts=value.trim_prefix("rgba(").trim_suffix(")").split(",")
    color=Color(float(parts[0])/255,float(parts[1])/255,float(parts[2])/255,float(parts[3]))
   else:color=Color.from_string(value,Color.WHITE)
  color_cache[key]=color
 var result: Color=color_cache[key];result.a*=alpha;return result
func clipped_rect(rect: Rect2,command: Array) -> Rect2:
 var clip=command.back()
 if clip==null:return rect
 var local=matrix(command[1]).affine_inverse()*matrix(clip.m)*rectangle(clip.r)
 return rect.intersection(local)
func gradient_texture(info: Dictionary,rect: Rect2) -> Texture2D:
 var key=JSON.stringify([info,rect.position.x,rect.position.y,rect.size.x,rect.size.y])
 if not gradients.has(key):
  var gradient=Gradient.new();var stops=info.stops
  var colors=PackedColorArray();var offsets=PackedFloat32Array()
  for stop in stops:offsets.append(float(stop[0]));colors.append(paint_color(stop[1],1))
  gradient.offsets=offsets;gradient.colors=colors
  var texture=GradientTexture2D.new();texture.gradient=gradient;texture.width=128;texture.height=128;texture.fill=GradientTexture2D.FILL_RADIAL
  var p=info.gradient
  texture.fill_from=(Vector2(p[3],p[4])-rect.position)/rect.size
  texture.fill_to=(Vector2(p[3]+p[5],p[4])-rect.position)/rect.size
  gradients[key]=texture
 return gradients[key]
func _draw():
 if font==null:return
 var draw_started=Time.get_ticks_usec()
 for c in commands:
  draw_set_transform_matrix(matrix(c[1]))
  var color=paint_color(c[3],float(c[2]))
  match c[0]:
   "combat_floor":Combat.floor_remains(self,c[4],textures)
   "combat_air":
    if not victorious and not defeated:Combat.air(self,c[4],c[5])
   "rect":
    var rect=clipped_rect(Rect2(c[4],c[5],c[6],c[7]),c)
    if not rect.has_area():continue
    if c[3] is Dictionary:draw_texture_rect(gradient_texture(c[3],rect),rect,false,Color(1,1,1,c[2]))
    else:draw_rect(rect,color,c[8],-1 if c[8] else maxf(1,c[9]))
   "image":
    if not textures.has(c[4]):continue
    var destination=rectangle(c[6]);var cropped=clipped_rect(destination,c)
    if not cropped.has_area():continue
    var source=rectangle(c[5]);var ratio=source.size/destination.size
    source.position+=(cropped.position-destination.position)*ratio;source.size=cropped.size*ratio
    draw_texture_rect_region(textures[c[4]],cropped,source,Color(1,1,1,c[2]))
   "ellipse":
    var points=ellipse_points(c)
    draw_set_transform_matrix(matrix(c[1])*Transform2D(0,Vector2(c[4],c[5])))
    if c[11]:draw_colored_polygon(points,color)
    else:draw_polyline(points,color,maxf(1,c[12]),true)
   "poly":
    var points=PackedVector2Array()
    for point in c[4]:points.append(Vector2(point[0],point[1]))
    if c[5] and points.size()>=3:draw_colored_polygon(points,color)
    elif points.size()>=2:draw_polyline(points,color,maxf(1,c[6]),true)
   "text":
    var text_size=maxi(8,int(c[7]));var at=Vector2(c[5],c[6]);var width=font.get_string_size(c[4],HORIZONTAL_ALIGNMENT_LEFT,-1,text_size).x
    if c[8]=="center":at.x-=width/2
    elif c[8]=="right":at.x-=width
    draw_string(font,at,c[4],HORIZONTAL_ALIGNMENT_LEFT,-1,text_size,color)
   "lpc":
    var action="hurt" if defeated or c[8]<=0 else ("attack" if c[11]>0 else ("walk" if c[10] else "idle"))
    var position=Vector2(c[4],c[5]-c[6]+(1-c[7])*80)
    var clock=defeat_time if defeated else float(c[13])
    if action=="attack":
     var count=Character.frames("body").get_frame_count(Character.clip(outfit,action,c[12]))
     clock=minf(clock*count/.32/9,(count-.01)/9)
    Character.draw_actor(self,outfit,position,"victory" if victorious else action,c[12],victory_time if victorious else clock,1.15*c[7])
    if victorious:Combat.victory(self,position,victory_time)
 draw_set_transform_matrix(Transform2D.IDENTITY)
 if depth_background:
  for cell in depth_walls:Scenery.wall(self,cell,depth_walls,1.0,depth_gates)

 last_draw_usec=Time.get_ticks_usec()-draw_started

func prepare_depth():
 depth_walls.clear()
 for c in commands:
  if c[0]=="image" and c[4]=="catTiles" and c[5]==[80.0,144.0,32.0,32.0]:
   depth_walls[Vector2i(int(c[6][0]/32),int(c[6][1]/32))]=true
 # Classic routes include narrow beams: keep projection inside their existing wall tiles.
 for cell in depth_walls:depth_gates[cell+Vector2i.UP]=true
 depth_background=true

func ellipse_points(c: Array) -> PackedVector2Array:
 var key=str([c[6],c[7],c[8],c[9],c[10]])
 if not ellipse_cache.has(key):
  if ellipse_cache.size()>=128:ellipse_cache.clear()
  var points=PackedVector2Array();var span=minf(TAU,c[10]-c[9]);var count=maxi(8,int(ceil(absf(span)*8)))
  var rotation=float(c[8]);var cosine=cos(rotation);var sine=sin(rotation)
  for i in range(count+1):
   var angle=c[9]+span*i/count;var dx=cos(angle)*c[6];var dy=sin(angle)*c[7]
   points.append(Vector2(dx*cosine-dy*sine,dx*sine+dy*cosine))
  ellipse_cache[key]=points
 return ellipse_cache[key]
