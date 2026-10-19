extends Node
const Model=preload("res://map_model.gd")
var failures: Array=[]
var checks=0
var app
var elapsed=0.0
func check(value: bool,label: String):
 checks+=1
 if not value:failures.append(label);print("FAIL ",label)
func canonical(data) -> String:return JSON.stringify(JSON.parse_string(JSON.stringify(data)))
func walk_to(cell: Vector2i) -> bool:
 var target=Vector2(cell)*32+Vector2(16,16);var old_room=app.room_index
 for n in range(1600):
  if not app.alive or app.room_index!=old_room:return false
  var delta=target-app.player
  if delta.length()<0.6:return true
  app.tick(1.0/60.0,delta.normalized()*minf(1.0,delta.length()/(160.0/60.0)));elapsed+=1.0/60.0
 return false
func press_switch():
 app.activate_switch()
 for n in range(45):app.tick(1.0/60.0,Vector2.ZERO);elapsed+=1.0/60.0
func cross(side: int):
 var old=app.room_index
 for n in range(50):
  app.tick(1.0/60.0,Vector2(Model.DIRS[side]));elapsed+=1.0/60.0
  if app.room_index!=old or app.won:return

func run(workshop):
 app=workshop
 app.set_process(false)
 check(Model.validate(app.level,true)=="","four-room playable validation")
 var original=canonical(app.level)
 # All shape/orientation and extreme size combinations must have closed walls and floor.
 for shape in Model.SHAPES:
  for rotation in range(4):
   for dimensions in [[10,10],[30,24],[13,17]]:
    var r=Model.make_room("a","shape",dimensions[0],dimensions[1],shape,rotation)
    var data={"schema":2,"rooms":[r]}
    check(Model.validate(data)=="","shape %s %d %s"%[shape,rotation,dimensions])
    check(Model.flood(r,Vector2i(r.spawn[0],r.spawn[1])).size()>3,"connected interior %s %d"%[shape,rotation])
 # All four assembly directions and offsets; input dictionaries remain untouched.
 for side in range(4):
  for offset in [-3,0,3]:
   var a=Model.make_room("a","A",18,14,"矩形");var b=Model.make_room("b","B",16,12,"矩形");b.position=[40,0]
   var data={"schema":2,"rooms":[a,b]};var before=canonical(data)
   var result=Model.join(data,"a","b",side,offset)
   check(result.error=="" and Model.validate(result.get("level",{}))=="","join %d offset %d"%[side,offset])
   check(canonical(data)==before,"join is atomic")
   if result.error=="":
    var repeated=Model.join(result.level,"a","b",side,offset)
    check(repeated.error=="" and Model.validate(repeated.get("level",{}))=="","repeat join deduplicates")
    # Open the actual runtime gate and cross in each direction at both usable edges.
    for edge in [-6.0,6.0]:
     app.level=result.level.duplicate(true);app.room_index=0;app.runtime=[]
     for r in app.level.rooms:app.runtime.append(app.state_for(r))
     app.playing=true;app.alive=true;app.won=false;app.visited=["a"]
     var gate=Model.door_by_id(app.room(),result.door);app.runtime[0].doors[gate.id]=1.0
     var direction=Vector2(Model.DIRS[side]);app.player=app.cell_center([gate.x,gate.y])-direction*32+Vector2(-direction.y,direction.x)*edge
     cross(side)
     check(app.room_index==1 and app.can_move(app.player),"portal edge %d %.0f"%[side,edge])
     cross((side+2)%4)
     check(app.room_index==0 and app.can_move(app.player),"return portal %d %.0f"%[side,edge])
 app.playing=false;app.level=Model.four_rooms();app.room_index=0
 var invalid=app.level.duplicate(true);invalid.rooms[1].position=[0,0]
 check(Model.validate(invalid)!="","overlap rejected")
 invalid=app.level.duplicate(true);invalid.rooms[1].position[1]+=1
 check(Model.validate(invalid)!="","misaligned portal rejected")
 invalid=app.level.duplicate(true);invalid.rooms[0].spawn=[2.5,4]
 check(Model.validate(invalid)!="","fractional coordinates rejected")
 invalid=app.level.duplicate(true);invalid.rooms[0].objects[0].target="missing"
 check(Model.validate(invalid)!="","missing target rejected")
 invalid=app.level.duplicate(true);invalid.rooms[0].objects[0].side=-1
 check(Model.validate(invalid)!="","negative side rejected")
 invalid=app.level.duplicate(true);invalid.rooms[0].objects[0].entry=true
 check(Model.validate(invalid)!="","paired inlet deadlock rejected")
 invalid=app.level.duplicate(true);invalid.rooms[1].objects[0].entry=false;invalid.rooms[0].objects[0].entry=true
 check(Model.validate(invalid,true)!="","reversed progression rejected")
 var shifted=Model.join(app.level,"r1","r2",0,1)
 check(shifted.error=="" and Model.validate(shifted.get("level",{}),true)=="","move connected room group preserves downstream portals")
 if shifted.error=="":check(shifted.level.rooms[3].position[1]==app.level.rooms[3].position[1]+1,"downstream rooms move together")
 var rejected=Model.join(app.level,"r1","r2",0,30)
 check(rejected.error!="" and canonical(app.level)==original,"non-touching join rejected atomically")
 check(Model.reshape(app.level,"r1",20,14,"L形",0).error!="","connected resize guarded")
 app.disconnect_room()
 var disconnected=canonical(app.level)
 app.undo();check(canonical(app.level)==original,"disconnect undo restores paired doors")
 app.redo();check(canonical(app.level)==disconnected,"disconnect redo")
 var reshaped=Model.reshape(app.level,"r1",16,10,"L形",1)
 check(reshaped.error=="","reshape disconnected room")
 app.level=Model.four_rooms();app.room_index=0;app.overview=false
 app.tool="墙壁";app.paint(Vector2i(4,4),false);app.painting=false;app.stroke_cells.clear()
 check(app.room().walls.has([4,4]),"paint wall at scaled grid")
 app.undo();check(canonical(app.level)==original,"painting undo")
 for i in range(4):
  app.room_index=i
  var c=Vector2i(app.room().spawn[0],app.room().spawn[1])
  check(app.screen_cell(app.view_origin()+(Vector2(c)*32+Vector2(16,16))*app.view_scale())==c,"screen-to-grid room %d"%i)
 app.room_index=0
 app.join_target="r2";app.join_side=0;app.join_offset=0;app.preview_join()
 check(not app.preview_level.is_empty() and canonical(app.level)==original,"preview leaves layout untouched")
 app.apply_join();check(Model.validate(app.level,true)=="","UI applies valid join")
 app.undo();check(canonical(app.level)==original,"assembly undo")
 app.preview_level={};app.overview=false
 check(app.save_level("user://017-test-map.json"),"save schema 2")
 check(app.save_level("user://017-test-map.json") and FileAccess.file_exists("user://017-test-map.json.bak"),"backup before overwrite")
 check(app.load_level("user://017-test-map.json") and canonical(app.level)==original,"schema 2 roundtrip")
 var bad=FileAccess.open("user://017-bad.json",FileAccess.WRITE);bad.store_string('{"schema":2,"rooms":[null]}');bad.close()
 check(not app.load_level("user://017-bad.json") and canonical(app.level)==original,"malformed read preserves layout")
 check(not app.save_level("/dev/null/rooms.json"),"write failure")
 var legacy=Model.make_room("old","旧版",22,16,"矩形")
 for key in ["width","height","shape","rotation","position"]:legacy.erase(key)
 var converted=Model.migrate({"schema":1,"rooms":[legacy]})
 check(Model.validate(converted)=="" and converted.rooms[0].width==22,"schema 1 migration")
 var old_rooms=[]
 for i in range(2):
  var old=Model.make_room("old%d"%i,"旧版房间",22,16,"矩形")
  old.objects=[{"id":"door","kind":"隔板门","x":21,"y":8,"target":"old1" if i==0 else "finish"},{"id":"switch","kind":"开关","x":19,"y":9,"link":"door"}]
  for key in ["width","height","shape","rotation","position"]:old.erase(key)
  old_rooms.append(old)
 var raw_legacy=JSON.parse_string(JSON.stringify({"schema":1,"rooms":old_rooms}))
 converted=Model.migrate(raw_legacy);Model.normalize(converted)
 check(Model.validate(converted,true)=="" and converted.rooms[0].objects[0].legacy,"schema 1 JSON links and float coordinates migrate")
 check(raw_legacy.schema==1 and not raw_legacy.rooms[0].has("width"),"migration preserves original data")
 # Traverse the delivered map using real tick movement, traps active, no teleport or invulnerability.
 app.level=Model.four_rooms();app.room_index=3;app.toggle_play();elapsed=0
 check(app.room_index==0,"play always starts at room one")
 check(walk_to(Vector2i(2,4)) and walk_to(Vector2i(15,4)) and walk_to(Vector2i(15,6)),"room1 walk around active spikes")
 check(app.runtime[1].time==0 and app.runtime[2].time==0,"future rooms remain idle")
 press_switch();check(walk_to(Vector2i(16,6)),"approach first door");cross(0)
 check(app.room_index==1,"right door enters room2")
 var entrance=app.player;app.tick(0.01,Vector2.ZERO)
 check(app.room_index==1,"no immediate bounce between paired doors")
 app.retry();check(app.player==entrance and app.runtime[1].time==0,"retry uses actual entrance")
 check(walk_to(Vector2i(3,6)) and walk_to(Vector2i(3,12)) and walk_to(Vector2i(9,12)) and walk_to(Vector2i(9,13)),"room2 bomb escape movement")
 check(app.runtime[1].bombs.b2!=-1,"room2 bomb actually triggered")
 press_switch();check(walk_to(Vector2i(9,14)),"approach lower door");cross(1)
 check(app.room_index==2,"down door enters room3")
 check(walk_to(Vector2i(10,1)) and walk_to(Vector2i(10,8)) and walk_to(Vector2i(2,8)),"room3 active trap navigation")
 press_switch();check(walk_to(Vector2i(1,8)),"approach left door");cross(2)
 check(app.room_index==3,"left door enters room4")
 check(walk_to(Vector2i(14,8)) and walk_to(Vector2i(10,8)) and walk_to(Vector2i(10,14)) and walk_to(Vector2i(8,14)) and walk_to(Vector2i(8,15)),"room4 bomb escape movement")
 check(app.runtime[3].bombs.b4!=-1,"room4 bomb actually triggered")
 press_switch();check(app.won,"final switch wins without walking through door")
 check(app.won and app.alive and app.visited.size()==4,"four-room normal movement clear")
 if "--visual-test" in OS.get_cmdline_user_args():
  await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("user://017-clear.png")
 print("PLAYTHROUGH seconds=",snappedf(elapsed,0.01)," visited=",app.visited," alive=",app.alive," won=",app.won)
 app.toggle_play();check(canonical(app.level)==original,"runtime never mutates authoring data")
 # Isolated failure/retry tests: traps must still be lethal.
 app.toggle_play();app.player=app.cell_center([8,6])
 for n in range(200):app.tick(0.02,Vector2.ZERO)
 check(not app.alive,"spike damage active")
 app.retry();check(app.alive,"death retry")
 app.overview=true;var clock=app.runtime[0].time;app._process(1.0)
 check(app.runtime[0].time==clock,"overview pauses simulation")
 app.toggle_play();app.level=Model.four_rooms();app.room_index=0;app.overview=true;app.preview_level={};app.refresh()
 check(app.load_level("res://maps/four-rooms.json") and canonical(app.level)==original,"delivered map equals editor-built map")
 check(app.current_path=="user://rooms-v2.json","bundled example saves to user data, not application bundle")
 var bench_start=Time.get_ticks_usec()
 for n in range(20):Model.validate(app.level,true)
 print("BENCH four-room validation avg_ms=",snappedf((Time.get_ticks_usec()-bench_start)/20000.0,0.01))
 var large={"schema":2,"rooms":[]}
 for i in range(32):
  var r=Model.make_room("large%d"%i,"大房间",30,24,"矩形");r.position=[i*32,0];large.rooms.append(r)
 bench_start=Time.get_ticks_usec()
 var large_issue=Model.validate(large)
 print("BENCH 32 rooms / 30x24 validation_ms=",snappedf((Time.get_ticks_usec()-bench_start)/1000.0,0.01))
 check(large_issue=="","maximum-size editing map validation")
 app.overview=true;app.refresh()
 var extra=load("res://tests018.gd").new();add_child(extra);await extra.run(app)
 checks+=extra.checks;failures.append_array(extra.failures)
 var character_suite=load("res://tests019.gd").new();add_child(character_suite);await character_suite.run(app)
 checks+=character_suite.checks;failures.append_array(character_suite.failures)
 var visual_suite=load("res://tests020.gd").new();add_child(visual_suite);await visual_suite.run(app)
 checks+=visual_suite.checks;failures.append_array(visual_suite.failures)
 var classic_suite=load("res://tests021.gd").new();add_child(classic_suite);await classic_suite.run(app)
 checks+=classic_suite.checks;failures.append_array(classic_suite.failures)
 var native_suite=load("res://tests022.gd").new();add_child(native_suite);await native_suite.run(app)
 checks+=native_suite.checks;failures.append_array(native_suite.failures)
 var challenge_suite=load("res://tests024.gd").new();add_child(challenge_suite);await challenge_suite.run(app)
 checks+=challenge_suite.checks;failures.append_array(challenge_suite.failures)
 var ui_suite=load("res://tests025.gd").new();add_child(ui_suite);await ui_suite.run(app)
 checks+=ui_suite.checks;failures.append_array(ui_suite.failures)
 var scenery_suite=load("res://tests026.gd").new();add_child(scenery_suite);await scenery_suite.run(app)
 checks+=scenery_suite.checks;failures.append_array(scenery_suite.failures)
 var combat_suite=load("res://tests027.gd").new();add_child(combat_suite);await combat_suite.run(app)
 checks+=combat_suite.checks;failures.append_array(combat_suite.failures)
 var performance_suite=load("res://tests028.gd").new();add_child(performance_suite);await performance_suite.run(app)
 checks+=performance_suite.checks;failures.append_array(performance_suite.failures)
 print("WORKSHOP 028 TESTS ",checks," checks / ",("PASS" if failures.is_empty() else str(failures)))
 if "--visual-test" in OS.get_cmdline_user_args():
  await get_tree().process_frame
  await RenderingServer.frame_post_draw
  get_viewport().get_texture().get_image().save_png("user://017-map.png")
 get_tree().quit(0 if failures.is_empty() else 1)
