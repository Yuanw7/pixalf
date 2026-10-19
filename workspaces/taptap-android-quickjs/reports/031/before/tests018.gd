extends Node
const Model=preload("res://map_model.gd")
const Catalog=preload("res://trap_catalog.gd")
const Library=preload("res://map_library.gd")
const Traps=preload("res://trap_runtime.gd")
var checks=0
var failures=[]
func check(condition: bool,label: String):
 checks+=1
 if not condition:failures.append(label);print("FAIL 018 ",label)
func fixture(app,kind: String) -> Dictionary:
 app.level=Library.showcase();app.room_index=0;app.playing=true;app.alive=true;app.won=false;app.air_time=0;app.overview=false
 var o=Catalog.create(kind,10,10,"test")
 o.period=2.0;o.active=1.0;o.travel=2
 app.room().objects=[o];app.runtime=[app.state_for(app.room())];app.runtime[0].time=1.2;app.player=Vector2(80,80)
 return o
func run(app):
 check(Catalog.KINDS.size()==12,"12 distinct trap types")
 check(Model.validate(Library.showcase(),true)=="","showcase playable")
 var data=Library.showcase();var spikes=data.rooms[0].objects.filter(func(o):return o.id.begins_with("sequence"))
 check(spikes.size()==4,"four staggered spikes")
 spikes[1].delay=1.7
 check(spikes[0].delay==0 and spikes[2].delay==1 and spikes[3].delay==1.5,"editing one delay preserves other three")
 var saved=JSON.parse_string(JSON.stringify(data));Model.normalize(saved)
 check(saved.rooms[0].objects[-3].delay==1.7,"individual timing JSON roundtrip")
 var first=spikes[0];var last=spikes[3]
 check(Catalog.phase(first,2.6).active and not Catalog.phase(last,2.6).active,"different phases at same room time")
 first.active=31
 check(Model.validate(data,true)!="","invalid active duration rejected")
 for kind in Catalog.KINDS:
  var o=fixture(app,kind)
  if kind in ["地刺","旋转刺阵","落石"]:app.player=Traps.point(o);Traps.update(app,0.02);check(not app.alive,kind+" lethal active phase")
  elif kind in ["移动锯轮","摆动刺球"]:app.player=Traps.position(o,1.2);Traps.update(app,0.02);check(not app.alive,kind+" collision follows moving sprite")
  elif kind in ["伸缩长矛","火焰箱"]:app.player=Traps.point(o)+Vector2(48,0);Traps.update(app,0.02);check(not app.alive,kind+" directional range")
  elif kind=="炸弹":
   app.player=Traps.point(o);Traps.update(app,0.02);check(app.runtime[0].bombs.test==o.fuse,"bomb proximity ignition")
   app.runtime[0].bombs.test=0.01;Traps.update(app,0.02);check(not app.alive,"bomb fuse explosion")
  elif kind=="箭塔":
   Traps.update(app,0.02);check(app.runtime[0].projectiles.size()==1,"arrow emits")
   Traps.update(app,0.02);check(app.runtime[0].projectiles.size()==1,"one arrow per cycle")
   app.player=app.runtime[0].projectiles[0].position+Vector2(4,0);Traps.update(app,0.02);check(not app.alive,"arrow hit")
  elif kind=="风扇":
   app.player=Traps.point(o)+Vector2(32,0);var before=app.player;Traps.update(app,0.05);check(app.player.x>before.x,"fan pushes")
  elif kind=="塌落平台":
   app.player=Traps.point(o);Traps.update(app,0.02);check(app.alive and app.runtime[0].mechanisms.test.armed>0,"platform arms on contact")
   Traps.update(app,1.1);check(not app.alive,"platform collapse lethal")
   app.alive=true;app.player=Vector2(80,80);Traps.update(app,1.0);check(app.runtime[0].mechanisms.test.armed==-1,"platform recovers")
  elif kind=="弹簧":
   app.player=Traps.point(o);Traps.update(app,0.02);check(app.air_time>0 and app.launch_velocity.x>0,"spring launches")
   var before=app.player;app.tick(0.05,Vector2.ZERO);check(app.player.x>before.x,"spring movement applied")
  o.delay=10;app.runtime=[app.state_for(app.room())];app.alive=true;app.air_time=0;app.player=Traps.point(o);Traps.update(app,0.02)
  check(app.alive and app.runtime[0].projectiles.is_empty() and app.air_time==0,"delay prevents "+kind)
 var o=fixture(app,"箭塔");app.room().walls.append([11,10]);Traps.update(app,0.3)
 check(app.runtime[0].projectiles.is_empty(),"walls block arrows")
 o=fixture(app,"地刺");app.air_time=0.3;app.player=Traps.point(o);Traps.update(app,0.02);check(app.alive,"spring airborne immunity")
 var blocked=Library.showcase();blocked.rooms[0].objects[5].travel=6
 check(Model.validate(blocked,true)!="","sweeping traps cannot cross walls")
 # Library roundtrips use a separate test directory, never user maps.
 var root="user://test-library-018/"
 DirAccess.make_dir_recursive_absolute(root)
 for file in DirAccess.get_files_at(root):DirAccess.remove_absolute(root+file)
 var first_save=Library.save_map(Library.showcase(),"地图甲","",root)
 var second_save=Library.save_map(Model.four_rooms(),"地图乙","",root)
 check(first_save.error=="" and second_save.error=="" and first_save.path!=second_save.path,"two independent map files")
 var reloaded=Library.entries(root)
 check(reloaded.size()==4,"reload library preserves two created maps plus builtins")
 var update=Library.save_map(Library.showcase(),"地图甲第二版",first_save.path,root)
 check(update.error=="" and Library.entries(root).size()==4 and FileAccess.file_exists(first_save.path+".bak"),"update retains identity and backup")
 var f=FileAccess.open(root+"bad.json",FileAccess.WRITE);f.store_string("{broken");f.close()
 check(Library.entries(root).size()==4,"bad JSON does not block healthy maps")
 check(Library.save_map({"schema":9},"坏地图",first_save.path,root).error!="","invalid update refused")
 check(Library.entries(root).size()==4,"failed update preserves healthy map")
 check(Library.save_map(Model.four_rooms(),"逃逸","user://outside.json",root).error!="","library disallows external overwrite")
 app.playing=false;app.level=Model.four_rooms();app.room_index=0;app.home.hide();app.refresh()
 app.selection="s1";app.refresh()
 app.show_home();check(app.library_list.item_count>=2 and app.home.visible,"home lists maps")
 var draft=JSON.stringify(app.level);app.library_list.select(1);app.open_library_map(true)
 check(app.playing and app.formal_run and not app.sidebar.is_visible_in_tree(),"formal play hides editor tools")
 app.show_home();check(JSON.stringify(app.level)==draft and not app.playing,"return home restores draft")
 app.home.hide();app.trap_box.show();check(app.trap_picker.grid.get_child_count()==12,"searchable palette contains 12 tools")
 app.trap_box.hide();check(not app.trap_box.visible,"palette collapses")
 app.level=Model.four_rooms();app.room_index=0;app.overview=true;app.refresh()
 for file in DirAccess.get_files_at(root):DirAccess.remove_absolute(root+file)
 DirAccess.remove_absolute(root)
 print("018 EXTRA ",checks," checks")
