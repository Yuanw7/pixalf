extends RefCounted
const Catalog = preload("res://trap_catalog.gd")
const TrapMotion = preload("res://trap_runtime.gd")

const SHAPES = ["矩形", "L形", "T形", "十字形"]
const DIRS = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const SIDES = ["右", "下", "左", "上"]

static func inside(r: Dictionary, c: Vector2i) -> bool:
 if c.x<0 or c.y<0 or c.x>=int(r.width) or c.y>=int(r.height):return false
 var u=(c.x+0.5)/float(r.width);var v=(c.y+0.5)/float(r.height)
 for n in range(int(r.rotation)):
  var previous=u;u=v;v=1.0-previous
 match r.shape:
  "L形":return not (u>=0.5 and v<0.5)
  "T形":return v<0.5 or (u>=0.3 and u<0.7)
  "十字形":return (u>=0.3 and u<0.7) or (v>=0.3 and v<0.7)
 return true

static func boundary(r: Dictionary, c: Vector2i) -> bool:
 if not inside(r,c):return false
 for d in DIRS:
  if not inside(r,c+d):return true
 return false

static func door_side(r: Dictionary, c: Vector2i) -> int:
 for i in range(4):
  var d=DIRS[i];var tangent=Vector2i(-d.y,d.x)
  if inside(r,c) and not inside(r,c+d) and inside(r,c-d*2) and not boundary(r,c-d) and boundary(r,c+tangent) and boundary(r,c-tangent):return i
 return -1

static func make_room(id: String, title: String, width: int, height: int, shape: String, rotation: int=0) -> Dictionary:
 var r={"id":id,"name":title,"width":width,"height":height,"shape":shape,"rotation":rotation,"position":[0,0],"spawn":[2,2],"walls":[],"objects":[]}
 for y in range(height):
  for x in range(width):
   if boundary(r,Vector2i(x,y)):r.walls.append([x,y])
 for y in range(2,height-2):
  for x in range(2,width-2):
   if inside(r,Vector2i(x,y)) and not boundary(r,Vector2i(x,y)):
    r.spawn=[x,y];return r
 return r

static func object_at(r: Dictionary, c: Vector2i) -> Dictionary:
 for o in r.objects:
  if int(o.x)==c.x and int(o.y)==c.y:return o
 return {}
static func by_id(data: Dictionary, id: String) -> Dictionary:
 for r in data.rooms:
  if r.id==id:return r
 return {}
static func door_by_id(r: Dictionary,id: String) -> Dictionary:
 for o in r.objects:
  if o.id==id:return o
 return {}
static func position(r: Dictionary) -> Vector2i:return Vector2i(r.position[0],r.position[1])

static func overlap(data: Dictionary) -> String:
 var occupied={}
 for r in data.rooms:
  for y in range(int(r.height)):
   for x in range(int(r.width)):
    var c=Vector2i(x,y)
    if not inside(r,c):continue
    var world=c+position(r);var edge=boundary(r,c)
    if occupied.has(world) and (not edge or not occupied[world].edge):return "房间重叠："+occupied[world].name+" / "+r.name
    occupied[world]={"name":r.name,"edge":edge}
 return ""

static func connected_component(data: Dictionary,id: String) -> Array:
 var visited=[id];var queue=[id]
 while not queue.is_empty():
  var current=queue.pop_front()
  for r in data.rooms:
   for o in r.objects:
    if o.kind!="隔板门" or o.target=="finish" or o.get("legacy",false):continue
    var next=""
    if r.id==current:next=o.target
    elif o.target==current:next=r.id
    if next!="" and not visited.has(next):visited.append(next);queue.append(next)
 return visited

static func remove_door(data: Dictionary, room_id: String, door_id: String):
 var r=by_id(data,room_id);var o=door_by_id(r,door_id)
 if o.is_empty():return
 if o.get("pair","")!="":
  var target=by_id(data,o.target)
  if not target.is_empty():
   var pair=door_by_id(target,o.pair)
   if not pair.is_empty():
    target.objects.erase(pair)
    for s in target.objects.duplicate():
     if s.kind=="开关" and s.link==pair.id:
      if s.id==pair.id+"_switch":target.objects.erase(s)
      else:s.link=""
 r.objects.erase(o)
 for s in r.objects.duplicate():
  if s.kind=="开关" and s.link==door_id:
   if s.id==door_id+"_switch":r.objects.erase(s)
   else:s.link=""

# The same atomic operation is used by the editor and the four-room example.
static func join(data: Dictionary, source_id: String, target_id: String, side: int, offset: int) -> Dictionary:
 var next=data.duplicate(true);var a=by_id(next,source_id);var b=by_id(next,target_id)
 if a.is_empty() or b.is_empty() or a==b:return {"error":"请选择另一个房间"}
 for o in a.objects.duplicate():
  if o.kind=="隔板门" and o.target==target_id:remove_door(next,a.id,o.id)
 var group=connected_component(next,b.id)
 if group.has(a.id):return {"error":"这两个房间另有连接路径；请先解除连接再调整"}
 var target_position=position(a)
 match side:
  0:target_position+=Vector2i(a.width-1,offset)
  1:target_position+=Vector2i(offset,a.height-1)
  2:target_position+=Vector2i(1-b.width,offset)
  3:target_position+=Vector2i(offset,1-b.height)
 var shift=target_position-position(b)
 for r in next.rooms:
  if group.has(r.id):r.position=[position(r).x+shift.x,position(r).y+shift.y]
 var issue=overlap(next)
 if issue!="":return {"error":issue+"，请调整拼接偏移"}
 var candidates: Array=[]
 for y in range(int(a.height)):
  for x in range(int(a.width)):
   var c=Vector2i(x,y);var t=position(a)+c-position(b)
   if door_side(a,c)!=side or door_side(b,t)!=(side+2)%4:continue
   if not object_at(a,c).is_empty() or not object_at(b,t).is_empty():continue
   var ac=c-DIRS[side];var bc=t+DIRS[side]
   if a.walls.has([ac.x,ac.y]) or b.walls.has([bc.x,bc.y]):continue
   if not object_at(a,ac).is_empty() or not object_at(b,bc).is_empty():continue
   if a.spawn==[ac.x,ac.y] or b.spawn==[bc.x,bc.y]:continue
   candidates.append({"c":c,"t":t,"score":absf(y-a.height/2.0) if side%2==0 else absf(x-a.width/2.0)})
 if candidates.is_empty():return {"error":"没有可对齐的平直墙段或门内有障碍；请换方向/偏移"}
 candidates.sort_custom(func(l,r):return l.score<r.score)
 var choice=candidates[0];var c=choice.c;var t=choice.t
 var id="join_%s_%s"%[a.id,b.id];var pair=id+"_entry"
 a.objects.append({"id":id,"kind":"隔板门","x":c.x,"y":c.y,"side":side,"target":b.id,"pair":pair,"entry":false})
 b.objects.append({"id":pair,"kind":"隔板门","x":t.x,"y":t.y,"side":(side+2)%4,"target":a.id,"pair":id,"entry":true})
 var sw=c-DIRS[side]*2
 # Choose a free adjacent interior cell for the explicit switch.
 var spots=[sw,sw+Vector2i(-DIRS[side].y,DIRS[side].x),sw-Vector2i(-DIRS[side].y,DIRS[side].x)]
 var placed=false
 for spot in spots:
  if inside(a,spot) and not a.walls.has([spot.x,spot.y]) and object_at(a,spot).is_empty() and a.spawn!=[spot.x,spot.y]:
   a.objects.append({"id":id+"_switch","kind":"开关","x":spot.x,"y":spot.y,"link":id});placed=true;break
 if not placed:return {"error":"门旁没有可放置开关的空地"}
 return {"error":"","level":next,"door":id}

static func reshape(data: Dictionary, id: String, width: int, height: int, shape: String, rotation: int) -> Dictionary:
 var next=data.duplicate(true);var r=by_id(next,id)
 for o in r.objects:
  if o.kind=="隔板门" and o.target!="finish":return {"error":"请先解除此房间的拼接，再修改尺寸或房型（可撤销）"}
 var replacement=make_room(r.id,r.name,width,height,shape,rotation);replacement.position=r.position
 for c in r.walls:
  var v=Vector2i(c[0],c[1])
  if not boundary(r,v) and inside(replacement,v) and not boundary(replacement,v):replacement.walls.append(c)
 var removed=0
 for o in r.objects:
  var c=Vector2i(o.x,o.y)
  if o.kind=="隔板门":
   var side=door_side(replacement,c)
   if side>=0:o.side=side;replacement.objects.append(o)
   else:removed+=1
  elif inside(replacement,c) and not replacement.walls.has([c.x,c.y]):replacement.objects.append(o)
  else:removed+=1
 for o in replacement.objects:
  if o.kind=="开关" and door_by_id(replacement,o.link).is_empty():o.link=""
 if inside(replacement,Vector2i(r.spawn[0],r.spawn[1])) and not replacement.walls.has(r.spawn):replacement.spawn=r.spawn
 if replacement.walls.has(replacement.spawn) or not object_at(replacement,Vector2i(replacement.spawn[0],replacement.spawn[1])).is_empty():
  var found=false
  for y in range(height):
   for x in range(width):
    var c=Vector2i(x,y)
    if inside(replacement,c) and not replacement.walls.has([x,y]) and object_at(replacement,c).is_empty():replacement.spawn=[x,y];found=true;break
   if found:break
  if not found:return {"error":"新房型没有可用出生位置"}
 next.rooms[next.rooms.find(r)]=replacement
 var issue=overlap(next)
 if issue!="":return {"error":issue}
 return {"error":"","level":next,"removed":removed}

static func four_rooms() -> Dictionary:
 var a=make_room("r1","01 · 石厅入门",18,12,"矩形")
 var b=make_room("r2","02 · 折角引信",18,16,"L形")
 var c=make_room("r3","03 · 三岔地刺",22,14,"T形",2)
 var d=make_room("r4","04 · 十字终厅",18,18,"十字形")
 b.position=[40,0];c.position=[80,0];d.position=[120,0]
 var data={"schema":2,"rooms":[a,b,c,d]}
 for spec in [["r1","r2",0,0],["r2","r3",1,-3],["r3","r4",2,0]]:
  var result=join(data,spec[0],spec[1],spec[2],spec[3])
  assert(result.error=="",result.error)
  if result.error!="":return data
  data=result.level
 a=by_id(data,"r1");b=by_id(data,"r2");c=by_id(data,"r3");d=by_id(data,"r4")
 a.spawn=[2,6];a.objects.append({"id":"s1","kind":"地刺","x":8,"y":6,"period":2.4})
 b.objects.append({"id":"b2","kind":"炸弹","x":6,"y":10,"fuse":3.5})
 c.objects.append({"id":"s3a","kind":"地刺","x":9,"y":9,"period":2.8})
 c.objects.append({"id":"s3b","kind":"地刺","x":12,"y":9,"period":2.8})
 d.objects.append({"id":"b4","kind":"炸弹","x":8,"y":10,"fuse":4.0})
 var exit_cell=Vector2i(8,17)
 d.objects.append({"id":"finish","kind":"隔板门","x":exit_cell.x,"y":exit_cell.y,"side":1,"target":"finish","pair":"","entry":false})
 d.objects.append({"id":"finish_switch","kind":"开关","x":8,"y":15,"link":"finish"})
 return data

static func migrate(data: Variant) -> Variant:
 if not data is Dictionary or data.get("schema")!=1:return data
 var result=data.duplicate(true);result.schema=2
 if not result.get("rooms") is Array:return data
 for i in range(result.rooms.size()):
  var r=result.rooms[i]
  if not r is Dictionary:return data
  r.width=22;r.height=16;r.shape="矩形";r.rotation=0;r.position=[i*25,0]
  if not r.get("objects") is Array:return data
  for o in r.objects:
   if o is Dictionary and o.get("kind")=="隔板门":
    o.side=0 if o.get("x")==21 else 2;o.pair="";o.entry=false;o.legacy=o.get("target")!="finish"
 return result

static func integral(v: Variant) -> bool:
 return (v is int or v is float) and is_finite(float(v)) and float(v)==floor(float(v))
static func pair_valid(v: Variant) -> bool:return v is Array and v.size()==2 and integral(v[0]) and integral(v[1])
static func normalize(data: Variant):
 if not data is Dictionary or not data.get("rooms") is Array:return
 for r in data.rooms:
  if not r is Dictionary:continue
  for k in ["width","height","rotation"]:
   if integral(r.get(k)):r[k]=int(r[k])
  for k in ["spawn","position"]:
   if pair_valid(r.get(k)):r[k]=[int(r[k][0]),int(r[k][1])]
  if r.get("walls") is Array:
   for i in range(r.walls.size()):
    if pair_valid(r.walls[i]):r.walls[i]=[int(r.walls[i][0]),int(r.walls[i][1])]
  if r.get("objects") is Array:
   for o in r.objects:
    if o is Dictionary:
     for k in ["x","y","side"]:
      if integral(o.get(k)):o[k]=int(o[k])

static func validate(data: Variant, playable: bool=false) -> String:
 if not data is Dictionary or data.get("schema")!=2:return "不支持的文件版本"
 if not data.get("rooms") is Array or data.rooms.is_empty() or data.rooms.size()>32:return "房间数量需为1–32"
 var ids=[]
 for r in data.rooms:
  if not r is Dictionary or not r.get("id") is String or ids.has(r.id):return "房间ID缺失或重复"
  ids.append(r.id)
  if not r.get("name") is String or not r.get("walls") is Array or not r.get("objects") is Array:return "房间字段缺失"
  if not integral(r.get("width")) or not integral(r.get("height")) or r.width<10 or r.width>30 or r.height<10 or r.height>24:return "宽需10–30格，高需10–24格"
  if not SHAPES.has(r.get("shape")) or not integral(r.get("rotation")) or r.rotation<0 or r.rotation>3:return "房型或朝向无效"
  if not pair_valid(r.get("position")) or abs(r.position[0])>10000 or abs(r.position[1])>10000:return "地图坐标无效"
  if not pair_valid(r.get("spawn")) or not inside(r,Vector2i(r.spawn[0],r.spawn[1])):return "出生点在房间外"
  if r.walls.size()>720 or r.objects.size()>720:return "对象数量过多"
  for cell in r.walls:
   if not pair_valid(cell) or not inside(r,Vector2i(cell[0],cell[1])):return "墙体超出房型"
  for y in range(int(r.height)):
   for x in range(int(r.width)):
    if boundary(r,Vector2i(x,y)) and not r.walls.has([x,y]):return "房型外墙缺口"
  if r.walls.has(r.spawn):return "出生点在墙内"
  var object_ids=[];var occupied=[]
  for o in r.objects:
   if not o is Dictionary or not o.get("id") is String or object_ids.has(o.id):return "对象ID缺失或重复"
   object_ids.append(o.id)
   if not integral(o.get("x")) or not integral(o.get("y")) or not inside(r,Vector2i(o.x,o.y)):return "对象超出房型"
   if occupied.has([o.x,o.y]) or r.spawn==[o.x,o.y]:return "对象重叠或覆盖出生点"
   occupied.append([o.x,o.y])
   if not o.get("kind") is String or (not ["隔板门","开关"].has(o.kind) and not Catalog.known(o.kind)):return "未知对象类型"
   if o.kind=="隔板门":
    if not integral(o.get("side")) or o.side<0 or o.side>3 or door_side(r,Vector2i(o.x,o.y))!=o.side:return "门洞不在平直外墙"
    if not o.get("target") is String or not o.get("pair","") is String or not o.get("entry",false) is bool or not o.get("legacy",false) is bool:return "门关联格式无效"
    if o.target=="finish" and o.get("entry",false):return "终点不能标记为配对入口"
   elif r.walls.has([o.x,o.y]):return "对象与墙重叠"
   if o.kind=="开关" and not o.get("link") is String:return "开关关联格式无效"
   if Catalog.known(o.kind):
    var trap_issue=Catalog.validate(o)
    if trap_issue!="":return r.name+"："+trap_issue
    if playable and o.kind in ["移动锯轮","摆动刺球","伸缩长矛","火焰箱","风扇"]:
     var p=Catalog.settings(o)
     for sample in range(65):
      var at=TrapMotion.position(o,float(p.delay)+float(p.period)*sample/64.0)
      if o.kind in ["伸缩长矛","火焰箱","风扇"]:at=Vector2(o.x*32+16,o.y*32+16)+Vector2(DIRS[int(p.direction)])*float(p.travel)*32*sample/64.0
      for corner in [Vector2(-12,-12),Vector2(12,12),Vector2(-12,12),Vector2(12,-12)]:
       var cell=Vector2i(((at+corner)/32).floor())
       if not inside(r,cell) or r.walls.has([cell.x,cell.y]):return r.name+"："+o.kind+"的作用路径碰墙，请调整方向或距离"

 var issue=overlap(data)
 if issue!="":return issue
 for r in data.rooms:
  for o in r.objects:
   if o.kind=="开关":
    var gate=door_by_id(r,o.link)
    if o.link!="" and (gate.is_empty() or gate.kind!="隔板门"):return "开关关联失效"
    if playable and o.link=="":return r.name+"：开关未关联门"
   if o.kind!="隔板门":continue
   if o.target!="finish":
    var target=by_id(data,o.target)
    if target.is_empty() or target.id==r.id:return "目标房间失效"
    if not o.get("legacy",false):
     var pair=door_by_id(target,o.get("pair",""))
     if pair.is_empty() or pair.kind!="隔板门" or pair.target!=r.id or pair.get("pair")!=o.id:return "门洞连接不成对"
     if pair.get("entry",false)==o.get("entry",false):return "配对门必须是一端出口、一端入口"
     if (o.side+2)%4!=pair.side or position(r)+Vector2i(o.x,o.y)!=position(target)+Vector2i(pair.x,pair.y):return "拼接门洞没有对齐"
     var landing=Vector2i(pair.x,pair.y)-DIRS[pair.side]
     if target.walls.has([landing.x,landing.y]) or not object_at(target,landing).is_empty():return "目标门内的落脚点被占用"
   if playable and not o.get("entry",false):
    var linked=false
    for sw in r.objects:
     if sw.kind=="开关" and sw.link==o.id:linked=true
    if not linked:return r.name+"：门缺少开关"
  if playable:
   var reachable=flood(r,Vector2i(r.spawn[0],r.spawn[1]))
   for o in r.objects:
    var cell=Vector2i(o.x,o.y)
    if o.kind=="开关" and not reachable.has(cell):return r.name+"：开关不可达"
    if o.kind=="隔板门" and not reachable.has(cell-DIRS[o.side]):return r.name+"：门前道路不通"
 if playable:
  var seen=[data.rooms[0].id];var queue=seen.duplicate();var finish=false
  while not queue.is_empty():
   var r=by_id(data,queue.pop_front())
   for o in r.objects:
    if o.kind!="隔板门" or o.get("entry",false):continue
    if o.target=="finish":finish=true
    elif not seen.has(o.target):seen.append(o.target);queue.append(o.target)
  if seen.size()!=data.rooms.size():return "有房间未连接到第1关"
  if not finish:return "地图缺少可达终点门"
 return ""

static func flood(r: Dictionary, start: Vector2i) -> Dictionary:
 var found={start:true};var queue=[start];var wall_set={}
 for c in r.walls:wall_set[Vector2i(c[0],c[1])]=true
 while not queue.is_empty():
  var c=queue.pop_front()
  for d in DIRS:
   var n=c+d
   if inside(r,n) and not wall_set.has(n) and not found.has(n):found[n]=true;queue.append(n)
 return found
