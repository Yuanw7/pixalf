extends Node
const Model=preload("res://map_model.gd")
const Decor=preload("res://decoration_catalog.gd")
const Scenery=preload("res://room_scenery.gd")
const Library=preload("res://map_library.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 026 ",label)
func run(app):
 var data=Library.scenery_showcase()
 check(Model.validate(data,true)=="","decorated four-room map remains playable")
 var copy=JSON.parse_string(JSON.stringify(data));Model.normalize(copy)
 check(Model.validate(copy,true)=="" and copy.rooms[0].objects.size()==data.rooms[0].objects.size(),"all decorations survive JSON roundtrip")
 for kind in Decor.KINDS:check(Decor.icon(kind)!=null,"decoration asset "+kind)
 var r=data.rooms[0];var before=JSON.stringify(r);var walls=Scenery.walls(r)
 check(before==JSON.stringify(r),"wall projection does not change authoring geometry")
 for door in r.objects:
  if door.kind=="隔板门":check(not walls.has(Vector2i(door.x,door.y)),"door stays out of projected wall geometry")
 check(Scenery.front(Vector2i(0,0),{Vector2i(0,0):true}),"exposed wall draws front face")
 check(not Scenery.front(Vector2i(0,0),{Vector2i(0,0):true,Vector2i(0,1):true}),"joined wall has no internal front face")
 app.level=data;app.room_index=0;app.resume_editor()
 var old_walls=app.room().walls.duplicate(true)
 app.tool="木箱";app.stroke_cells.clear();app.paint(Vector2i(6,3),false)
 check(app.room().walls==old_walls and Model.object_at(app.room(),Vector2i(6,3)).is_empty(),"placing decoration cannot erase a wall")
 app.stroke_cells.clear();app.painting=false;app.paint(Vector2i(4,5),false)
 check(Model.object_at(app.room(),Vector2i(4,5)).kind=="木箱","editor places decoration")
 app.undo();check(Model.object_at(app.room(),Vector2i(4,5)).is_empty(),"decoration placement undo")
 app.toggle_play();var prop=app.room().objects.filter(func(o):return o.kind=="木箱")[0]
 check(app.can_move(app.cell_center([prop.x,prop.y])),"decorations do not block existing routes")
 app.show_home()
 var game=app.legacy_game;game.start_game("catacombs",app.outfit)
 var background=game.background.get_child(0)
 check(background.depth_background and not background.depth_walls.is_empty(),"classic dungeon uses native depth walls")
 check(background.depth_gates.size()==background.depth_walls.size(),"classic narrow paths keep original footprint")
 game.finish()
 print("026 SCENERY TESTS ",checks," checks / ",("PASS" if failures.is_empty() else str(failures)))
