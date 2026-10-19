extends Node
const Model=preload("res://map_model.gd")
const Library=preload("res://map_library.gd")
const ClockRule=preload("res://extraction_timer.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 032 ",label)
func run(app):
 app.set_process(false);app.playing=false;app.level=Library.spatial_challenges();app.room_index=0;app.resume_editor()
 check(not ClockRule.config(app.level).enabled,"old maps default to no countdown")
 var depth=app.undo_stack.size()
 check(app.set_extraction(true,180) and app.undo_stack.size()==depth+1,"editor stores whole-map option")
 var copy=JSON.parse_string(JSON.stringify(app.level));Model.normalize(copy)
 check(Model.validate(copy,true)=="" and copy.extraction.seconds==180,"countdown survives map JSON round trip")
 app.undo();check(not ClockRule.config(app.level).enabled,"countdown option undo")
 app.redo();check(ClockRule.config(app.level).enabled,"countdown option redo")
 for bad in [null,{"enabled":1},{"seconds":-1},{"seconds":"20"},{"seconds":INF},{"seconds":3601}]:
  var invalid=app.level.duplicate(true);invalid.extraction=bad;check(Model.validate(invalid)!="","bad countdown rejected")
 app.toggle_play();app.tick(.05,Vector2.ZERO)
 check(app.run_elapsed>0 and app.run_elapsed<.06,"new run starts clock")
 var time=app.run_elapsed;app.overview=true;app._process(.5);check(app.run_elapsed==time,"map pause freezes run clock");app.overview=false
 app.outfit_panel.show();app._process(.5);check(app.run_elapsed==time,"wardrobe freezes run clock");app.outfit_panel.hide()
 app.die("test");app.tick(.5,Vector2.ZERO);check(app.run_elapsed==time,"dead player clock frozen")
 app.retry();check(app.run_elapsed==time and app.alive,"checkpoint retry does not refill countdown")
 # Traversal state is room-local; extraction elapsed is deliberately map-global.
 app.room_index=1;app.player=app.cell_center(app.room().spawn);app.retry_position=app.player
 app.tick(.05,Vector2.ZERO);check(app.run_elapsed>time,"room change continues global clock")
 app.run_elapsed=179.99;app.tick(.05,Vector2.ZERO)
 check(not app.alive and app.extraction_expired and not app.won,"zero countdown is real defeat")
 app.retry();check(app.alive and app.room_index==0 and app.run_elapsed==0 and not app.extraction_expired,"timeout retry restarts entire run")
 app.room_index=1;app.player=app.cell_center([15,7]);app.runtime[1].challenge.done=true;app.run_elapsed=180
 app.activate_switch();check(not app.won and not app.alive,"final switch cannot win after deadline")
 app.retry();app.room_index=1;app.player=app.cell_center([15,7]);app.runtime[1].challenge.done=true;app.run_elapsed=179.9
 app.activate_switch();check(app.won and app.alive,"final switch wins before deadline")
 time=app.run_elapsed;app.tick(1,Vector2.ZERO);check(app.won and app.run_elapsed==time,"victory freezes countdown")
 app.playing=false;app.set_extraction(false,10);app.toggle_play();app.run_elapsed=1000;app.tick(.05,Vector2.ZERO)
 check(app.alive and not app.extraction_expired,"disabled timer never times out")
 check(ClockRule.text(61.1)=="01:02" and ClockRule.text(0)=="00:00","display rounds up seconds without negative time")
 app.playing=false;app.show_home()
 print("032 EXTRACTION TIMER ",checks," checks / ","PASS" if failures.is_empty() else str(failures))
