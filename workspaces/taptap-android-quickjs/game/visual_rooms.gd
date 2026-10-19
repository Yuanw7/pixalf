extends RefCounted
const Model=preload("res://map_model.gd")

# Work on copies: failed additions and drag previews never modify the authored map.
static func add_adjacent(data: Dictionary, source: String, side: int, width: int, height: int, shape: String, rotation: int, id: String) -> Dictionary:
 if data.rooms.size()>=32:return {"error":"最多32个房间。"}
 var a=Model.by_id(data,source)
 if a.is_empty() or side<0 or side>3:return {"error":"无效房间或方向"}
 var next=data.duplicate(true)
 next.rooms.append(Model.make_room(id,"新房间 %d"%(data.rooms.size()+1),width,height,shape,rotation))
 var center=int((a.height-height)/2.0) if side%2==0 else int((a.width-width)/2.0)
 var offsets=[center]
 for i in range(1,31):offsets.append(center+i);offsets.append(center-i)
 for offset in offsets:
  var result=Model.join(next,source,id,side,offset)
  if result.error=="":return result
 return {"error":"这一侧没有容纳新房间及门洞的空间；请缩小房间、换房型或换一侧。"}

static func move_preview(data: Dictionary, id: String, delta: Vector2i, tolerance: float) -> Dictionary:
 var group=Model.connected_component(data,id);var moved=data.duplicate(true)
 for r in moved.rooms:
  if group.has(r.id):r.position=[r.position[0]+delta.x,r.position[1]+delta.y]
 var candidates=[]
 for a in moved.rooms:
  if group.has(a.id):continue
  for b in moved.rooms:
   if not group.has(b.id):continue
   var ap=Model.position(a);var bp=Model.position(b)
   for side in range(4):
    var distance=0.0;var offset=0
    match side:
     0:distance=absf(bp.x-(ap.x+a.width-1));offset=bp.y-ap.y
     1:distance=absf(bp.y-(ap.y+a.height-1));offset=bp.x-ap.x
     2:distance=absf(bp.x+b.width-1-ap.x);offset=bp.y-ap.y
     3:distance=absf(bp.y+b.height-1-ap.y);offset=bp.x-ap.x
    if distance<=tolerance:candidates.append({"a":a.id,"b":b.id,"side":side,"offset":offset,"distance":distance})
 candidates.sort_custom(func(a,b):return a.distance<b.distance)
 for c in candidates:
  var joined=Model.join(moved,c.a,c.b,c.side,c.offset)
  if joined.error=="":joined.snapped=true;return joined
 var issue=Model.overlap(moved)
 return {"error":issue,"level":moved,"snapped":false}
