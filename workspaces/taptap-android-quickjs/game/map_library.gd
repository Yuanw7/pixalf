extends RefCounted
const Model=preload("res://map_model.gd")
const Catalog=preload("res://trap_catalog.gd")
const ROOT="user://maps/"
static func showcase() -> Dictionary:
 var r=Model.make_room("laboratory","机关实验室",30,24,"矩形")
 r.spawn=[2,2]
 r.objects=[{"id":"exit","kind":"隔板门","x":29,"y":2,"side":0,"target":"finish","pair":"","entry":false},{"id":"switch","kind":"开关","x":27,"y":2,"link":"exit"}]
 for i in range(12):
  var o=Catalog.create(Catalog.KINDS[i],5+(i%4)*6,7+int(i/4)*6,"trap_%d"%i)
  o.travel=1;r.objects.append(o)
 for i in range(4):
  var o=Catalog.create("地刺",7+i*3,4,"sequence_%d"%i)
  o.period=3.0;o.active=0.6;o.delay=i*0.5;r.objects.append(o)
 return {"schema":2,"title":"机关实验室 · 12类机关","rooms":[r]}
static func entries(root: String=ROOT) -> Array:
 var result=[{"title":"大型机关房 · 木头人＋数字地砖","path":"","data":spatial_challenges()},{"title":"四关拼接地图","path":"","data":Model.four_rooms()},{"title":"机关实验室 · 12类机关","path":"","data":showcase()}]
 DirAccess.make_dir_recursive_absolute(root)
 for file in DirAccess.get_files_at(root):
  if not file.ends_with(".json"):continue
  var path=root.path_join(file);var f=FileAccess.open(path,FileAccess.READ)
  if f==null or f.get_length()>2*1024*1024:continue
  var parser=JSON.new();var error=parser.parse(f.get_as_text());f.close()
  if error!=OK:continue
  var data=Model.migrate(parser.data);Model.normalize(data)
  if Model.validate(data,true)!="":continue
  result.append({"title":str(data.get("title",file)).left(60),"path":path,"data":data})
 return result
static func save_map(data: Dictionary,title: String,path: String="",root: String=ROOT) -> Dictionary:
 var issue=Model.validate(data,true)
 if issue!="":return {"error":issue,"path":""}
 if title.strip_edges().is_empty():return {"error":"请输入地图名称","path":""}
 if DirAccess.make_dir_recursive_absolute(root)!=OK:return {"error":"无法创建地图目录","path":""}
 if path.is_empty():path=root.path_join("map_%d_%d.json"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()])
 if path.get_base_dir().simplify_path()!=root.trim_suffix("/").simplify_path():return {"error":"地图路径不属于游玩目录","path":""}
 var copy=data.duplicate(true);copy.title=title.strip_edges().left(60)
 var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null:return {"error":"无法写入地图","path":""}
 f.store_string(JSON.stringify(copy,"  "));f.flush();var error=f.get_error();f.close()
 if error!=OK:return {"error":"写入失败，保留原地图","path":""}
 if FileAccess.file_exists(path) and DirAccess.copy_absolute(path,path+".bak")!=OK:return {"error":"备份失败，保留原地图","path":""}
 if DirAccess.rename_absolute(path+".tmp",path)!=OK:return {"error":"替换失败，保留原地图","path":""}
 return {"error":"","path":path}

static func challenges() -> Dictionary:
 var data=Model.four_rooms();data.title="挑战试炼 · 木头人与数字快答"
 for i in range(data.rooms.size()):
  var r=data.rooms[i]
  r.objects=r.objects.filter(func(o):return not Catalog.known(o.kind))
  r.challenge={"type":"木头人" if i%2==0 else "数字快答"}
  r.name=("木头人回廊" if i%2==0 else "数字快答厅")+" %d"%(i+1)
 return data


static func scenery_showcase() -> Dictionary:
 var data=Model.four_rooms();data.title="立体地宫 · 场景装饰示例"
 var r=data.rooms[0]
 for c in [[6,2],[6,3],[7,3],[8,3],[11,8],[12,8],[12,9]]:r.walls.append(c)
 var props=[["石柱",3,2],["雕像",10,2],["木箱",14,3],["陶罐",14,4],["碎石",7,8],["烛台",4,3],["石柱",3,9],["陶罐",15,9],["木箱",9,9],["碎石",14,8]]
 for i in range(props.size()):r.objects.append({"id":"decor_%d"%i,"kind":props[i][0],"x":props[i][1],"y":props[i][2]})
 return data


static func spatial_challenges() -> Dictionary:
 var a=Model.make_room("sentinel","木偶守卫与纵向火带",22,14,"矩形")
 var b=Model.make_room("math_floor","数字地砖熔岩房",18,14,"矩形");b.position=[30,0]
 var data={"schema":2,"title":"大型机关房 · 木头人＋数字地砖","rooms":[a,b]}
 data=Model.join(data,a.id,b.id,0,0).level
 for i in range(2):data.rooms[i]=Model.Challenge.Spatial.apply(data.rooms[i],Model.Challenge.Spatial.TYPES[i+1]).room
 b=data.rooms[1]
 b.objects.append({"id":"spatial_exit","kind":"隔板门","x":17,"y":7,"side":0,"target":"finish","pair":"","entry":false})
 b.objects.append({"id":"spatial_button","kind":"开关","x":15,"y":7,"link":"spatial_exit"})
 return data
