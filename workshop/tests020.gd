extends Node
const Model=preload("res://map_model.gd")
const Visual=preload("res://visual_rooms.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 020 ",label)
func run(app):
 var base={"schema":2,"rooms":[Model.make_room("a","起点",18,14,"矩形")]}
 var original=JSON.stringify(base)
 for side in range(4):
  for shape in Model.SHAPES:
   var result=Visual.add_adjacent(base,"a",side,16,12,shape,0,"b")
   check(result.error=="","add side %d %s"%[side,shape])
   if result.error=="":
    check(Model.validate(result.level)=="","valid new room geometry/doors")
    check(Model.connected_component(result.level,"a").size()==2,"paired connection")
 check(JSON.stringify(base)==original,"add previews preserve source")
 var joined=Visual.add_adjacent(base,"a",0,18,14,"矩形",0,"b").level
 check(Visual.add_adjacent(joined,"a",0,18,14,"矩形",0,"c").error!="","occupied side rejects repeated add")
 var moved=Visual.move_preview(joined,"b",Vector2i(4,5),2)
 check(moved.error=="" and not moved.snapped,"connected group free move")
 check(Model.position(moved.level.rooms[0])==Vector2i(4,5) and Model.position(moved.level.rooms[1])==Vector2i(21,5),"group relative layout preserved")
 check(Model.validate(moved.level)=="","group doors remain valid")
 var separate=base.duplicate(true);var b=Model.make_room("b","移动房",18,14,"矩形");b.position=[40,0];separate.rooms.append(b)
 var snap=Visual.move_preview(separate,"b",Vector2i(-22,0),2)
 check(snap.error=="" and snap.snapped and Model.position(snap.level.rooms[1])==Vector2i(17,0),"near edge snaps to shared wall")
 check(Model.validate(snap.level)=="","snap creates valid doors/switch")
 var blocked=Visual.move_preview(separate,"b",Vector2i(-36,0),2)
 check(blocked.error!="","overlap rejected")
 check(Model.position(separate.rooms[1])==Vector2i(40,0),"failed move preserves original")
 var full=base.duplicate(true)
 for i in range(31):
  var extra=Model.make_room("extra%d"%i,"备用",10,10,"矩形");extra.position=[100+i*15,0];full.rooms.append(extra)
 check(Visual.add_adjacent(full,"a",0,18,14,"矩形",0,"overflow").error!="","32-room limit atomic")
 app.home.hide();app.playing=false;app.outfit_panel.hide();app.level=base.duplicate(true);app.room_index=0;app.overview=true;app.preview_level={};app.undo_stack.clear();app.redo_stack.clear();app.refresh()
 var prior=JSON.stringify(app.level)
 app.show_add_adjacent(1);app.shape_dialog.hide()
 check(JSON.stringify(app.level)==prior and app.undo_stack.is_empty(),"cancel add dialog has no changes")
 app.show_add_adjacent(0);app.size_width.value=16;app.size_height.value=12;app.apply_shape()
 check(app.level.rooms.size()==2 and app.overview and not app.shape_dialog.visible,"confirm plus adds connected room")
 app.undo();check(app.level.rooms.size()==1,"add undo removes room and doors")
 app.redo();check(app.level.rooms.size()==2 and Model.validate(app.level)=="","add redo restores paired doors")
 # Exercise real _input press/motion/release, including release outside the canvas.
 app.level=separate.duplicate(true);app.room_index=1;app.refresh();app.undo_stack.clear();app.redo_stack.clear()
 var t=app.overview_transform(app.level)
 var start=t.origin+Vector2(48,6)*t.scale
 var press=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.position=start;app._input(press)
 check(app.dragging_room and app.overview,"click selects without entering room")
 var motion=InputEventMouseMotion.new();motion.position=start-Vector2(22*t.scale,0);motion.button_mask=MOUSE_BUTTON_MASK_LEFT;app._input(motion)
 check(app.drag_result.get("snapped",false),"input motion previews snap")
 check(app.level==separate,"drag does not commit early")
 var release=InputEventMouseButton.new();release.button_index=MOUSE_BUTTON_LEFT;release.pressed=false;release.position=motion.position;app._input(release)
 check(not app.dragging_room and Model.connected_component(app.level,"a").size()==2,"release commits snap")
 app.undo();check(app.level==separate,"move undo restores disconnected topology")
 app.begin_room_drag(start);app.update_room_drag(start+Vector2(10,20))
 var escape=InputEventKey.new();escape.keycode=KEY_ESCAPE;escape.pressed=true;app._input(escape)
 check(not app.dragging_room and app.level==separate,"Escape cancels preview")
 app.begin_room_drag(start);app.update_room_drag(start+Vector2(20,20));app.finish_room_drag(Vector2.ZERO)
 check(not app.dragging_room and app.level==separate,"outside release cancels")
 for side in range(4):check(app.plus_at(app.plus_center(side))==side,"visible plus hit target")
 app.level=Model.four_rooms();app.room_index=0;app.overview=true;app.refresh()
 print("020 VISUAL ROOM TESTS ",checks," checks / ",("PASS" if failures.is_empty() else str(failures)))
