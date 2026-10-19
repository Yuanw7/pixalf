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
 var result=[{"title":"四关拼接地图","path":"","data":Model.four_rooms()},{"title":"机关实验室 · 12类机关","path":"","data":showcase()}]
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
