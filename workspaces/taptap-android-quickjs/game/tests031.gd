extends Node
const Model=preload("res://map_model.gd")
const Challenge=preload("res://room_trial.gd")
const Library=preload("res://map_library.gd")
var failures=[]
var checks=0
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 031 ",label)
func run(app):
 app.set_process(false);app.resume_editor()
 var demo=Library.spatial_challenges()
 check(Model.validate(demo,true)=="","template rooms join with usable exits")
 var parser=JSON.new();parser.parse(JSON.stringify(demo));Model.normalize(parser.data)
 check(Model.validate(parser.data,true)=="" and Challenge.kind(parser.data.rooms[0])==Challenge.TYPES[1],"save/load preserves room types")
 var invalid=demo.duplicate(true);invalid.rooms[0].challenge.green=-1
 check(Model.validate(invalid)!="","bad room timing rejected")
 invalid=demo.duplicate(true);invalid.rooms[1].challenge="invalid"
 check(Model.validate(invalid)!="","bad room configuration rejected without crash")
 var small=Model.make_room("small","small",10,10,"矩形")
 check(Challenge.apply(small,Challenge.TYPES[1]).error!="","small room rejects template without changing original")
 var blocked=demo.duplicate(true);blocked.rooms[1].walls.append([9,7])
 check(Model.validate(blocked)!="","math answer tiles reject walls")
 var dirty=Model.make_room("dirty","dirty",18,14,"矩形");dirty.walls.append([9,7])
 check(Challenge.apply(dirty,Challenge.TYPES[2]).error=="","template cleans interior walls before board validation")
 var malformed=demo.duplicate(true);malformed.rooms[1].objects.append({"id":"broken"})
 check(Model.validate(malformed)!="","malformed map rejects before spatial coordinate access")
 # Multi-select through the same methods used by UI clicks and same-kind button.
 app.level=Library.showcase();app.room_index=0;app.selection="";app.selections.clear();app.refresh()
 app.select_object("sequence_0");app.select_object("sequence_1",true);check(app.selected_objects().size()==2,"shift click adds")
 app.select_object("sequence_1",true);check(app.selected_objects().size()==1,"shift click toggles off")
 app.select_same_kind();var n=app.selected_objects().size();check(n>=4,"same-kind selection")
 var untouched=Model.door_by_id(app.room(),"trap_1").duplicate(true)
 var depth=app.undo_stack.size();check(app.batch_timing({"period":4.0,"active":.8}),"batch timing accepts valid input")
 check(app.undo_stack.size()==depth+1,"batch is one undo step")
 check(app.selected_objects().all(func(o):return o.period==4.0 and o.active==.8),"all selected updated")
 check(Model.door_by_id(app.room(),"trap_1")==untouched,"nonselected bomb unchanged")
 var before=JSON.stringify(app.level);depth=app.undo_stack.size()
 check(not app.batch_timing({"period":.1}) and JSON.stringify(app.level)==before and depth==app.undo_stack.size(),"invalid batch atomic reject")
 app.undo();check(Model.door_by_id(app.room(),"sequence_0").period==3.0,"undo entire group")
 app.redo();check(Model.door_by_id(app.room(),"sequence_0").period==4.0,"redo entire group")
 # Template application preserves paired doors and supports undo.
 app.level=demo.duplicate(true);app.room_index=0;app.refresh();before=JSON.stringify(app.level)
 check(app.apply_room_template(Challenge.TYPES[2]) and Model.validate(app.level,true)=="","replace room type preserving paired doors")
 app.undo();check(JSON.stringify(app.level)==before,"undo room template")
 # Wood sentinel: stop safely, move on red => visible laser then real failure.
 app.level=demo.duplicate(true);app.room_index=0;app.playing=false;app.resume_editor();app.toggle_play()
 check(app.playing,"challenge demo starts")
 app.activate_switch();check(app.runtime[0].doors.values().all(func(v):return v==0),"cannot open exit before trial")
 var s=app.runtime[0].challenge;s.elapsed=4.2;app.player=Vector2(80,350)
 app.tick(.05,Vector2.ZERO);check(app.alive and s.laser==0,"red stop between fire lanes safe")
 app.tick(.05,Vector2.RIGHT);check(s.laser>0 and app.alive,"red movement locks laser first")
 for i in range(6):app.tick(.05,Vector2.ZERO)
 check(not app.alive,"laser actually kills")
 app.retry();check(app.runtime[0].challenge.elapsed==0 and app.alive,"retry resets full room rules")
 s=app.runtime[0].challenge;s.elapsed=1.8;app.player=Vector2(144,280);app.tick(.01,Vector2.ZERO)
 check(not app.alive,"stopping on an active vertical flame is lethal")
 app.retry();var time=app.runtime[0].challenge.elapsed;app.overview=true;app._process(.5);check(app.runtime[0].challenge.elapsed==time,"map pause freezes challenge")
 app.overview=false
 # Input-driven wood run: watch light/flame state, walk only into safe space.
 var frames=0;var crossing_x=-1.0
 while app.alive and not app.runtime[0].challenge.done and frames<6000:
  s=app.runtime[0].challenge
  var c=Challenge.config(app.room());var cycle=fposmod(s.elapsed,c.green+c.warning+c.red)
  var safe=cycle<c.green-.15
  if crossing_x>app.player.x:
   safe=true
  else:
   crossing_x=-1
   for lane in Challenge.lanes(app.room(),s.elapsed):
    if lane.x>app.player.x and lane.x-app.player.x<60:
     var duration=(lane.x+36-app.player.x)/160.0
     if cycle+duration>c.green-.1:safe=false
     for j in range(int(ceil(duration/.05))+1):
      var future=s.elapsed+j*.05;var future_x=app.player.x+j*8
      if absf(future_x-lane.x)<26 and Challenge.lanes(app.room(),future).any(func(l):return l.x==lane.x and l.active):safe=false
     if safe:crossing_x=lane.x+36
  app.tick(.05,Vector2.RIGHT if safe else Vector2.ZERO);frames+=1
 print("WOOD_RUN frames=",frames," alive=",app.alive," x=",app.player.x," elapsed=",app.runtime[0].challenge.elapsed," notice=",app.notice)
 check(app.alive and app.runtime[0].challenge.done,"normal movement can solve wood/fire room")
 # Walk to the paired switch and through the physical doorway after solving.
 var wood_switch={}
 for obj in app.room().objects:
  if obj.kind=="开关":wood_switch=obj;break
 var goal=app.cell_center([wood_switch.x,wood_switch.y])
 for i in range(70):
  if app.player.distance_to(goal)<8:break
  app.tick(.025,(goal-app.player).normalized())
 app.activate_switch()
 var wood_door=Model.door_by_id(app.room(),wood_switch.link);goal=app.cell_center([wood_door.x,wood_door.y])
 for i in range(120):
  if app.room_index==1:break
  app.tick(.025,(goal-app.player).normalized())
 check(app.room_index==1 and app.alive,"solved wood room opens paired door and enters math room")
 # Walk into the board, answer by moving to tiles, then reach the final switch.
 var physical_frames=0
 while app.alive and not app.runtime[1].challenge.done and physical_frames<2400:
  var current=app.runtime[1].challenge;var rect=Challenge.board(app.room());var destination=rect.get_center()
  if current.phase in ["question","collapse"]:destination=rect.position+Vector2(current.safe%3,int(current.safe/3))*64+Vector2(32,32)
  var movement=(destination-app.player).normalized() if app.player.distance_to(destination)>3 else Vector2.ZERO
  app.tick(.025,movement);physical_frames+=1
 check(app.alive and app.runtime[1].challenge.done,"normal walking answers arithmetic room")
 goal=app.cell_center([15,7])
 for i in range(120):
  if app.player.distance_to(goal)<8:break
  app.tick(.025,(goal-app.player).normalized())
 app.activate_switch();check(app.won,"final room victory switch respects completed trial")
 # Isolated failure cases below reset the campaign result.
 app.won=false;app.runtime[1]=app.state_for(app.room())
 # Math model's entry trigger, answer and collapse behavior.
 app.room_index=1;app.player=app.cell_center(app.room().spawn);app.runtime[1]=app.state_for(app.room());app.alive=true
 s=app.runtime[1].challenge;app.tick(.1,Vector2.ZERO);check(s.phase=="prepare","math waits until player enters board")
 var board=Challenge.board(app.room());app.player=board.get_center()
 for i in range(10):app.tick(.1,Vector2.ZERO)
 check(s.phase=="question" and s.numbers.size()==9,"question has nine unique tiles")
 check(s.numbers.duplicate().size()==9 and s.safe>=0,"answer is on board")
 app.player=board.position+Vector2((s.safe+1)%9%3,int(((s.safe+1)%9)/3))*64+Vector2(32,32)
 for i in range(31):app.tick(.1,Vector2.ZERO)
 check(not app.alive,"wrong answer collapses")
 app.runtime[1]=app.state_for(app.room());app.alive=true;app.player=board.get_center();s=app.runtime[1].challenge
 for round in range(2):
  while s.phase!="question" or s.round!=round:
   s=app.runtime[1].challenge;app.tick(.05,Vector2.ZERO)
   if s.phase=="question" and s.round==round:break
  app.player=board.position+Vector2(s.safe%3,int(s.safe/3))*64+Vector2(32,32)
  while not s.done and s.round==round:app.tick(.05,Vector2.ZERO)
 check(s.done and app.alive,"correct answers unlock exit")
 print("031 CHALLENGE + MULTISELECT ",checks," checks / ","PASS" if failures.is_empty() else str(failures))
