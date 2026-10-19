extends Node
const C=preload("res://room_challenge.gd")
const Model=preload("res://map_model.gd")
const Library=preload("res://map_library.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 024 ",label)
func run(app):
 app.show_start();check(app.start_screen.visible and not app.home.visible,"launch screen visible")
 app.start_screen.start_requested.emit();check(app.home.visible and not app.start_screen.visible,"start opens map library")
 app.show_start();app.start_screen.workshop_requested.emit();check(not app.home.visible and not app.start_screen.visible,"workshop opens editor")
 check(Model.validate(Library.challenges(),true)=="","challenge demo playable validation")
 var data=Library.challenges();var decoded=JSON.parse_string(JSON.stringify(data));Model.normalize(decoded)
 check(Model.validate(decoded,true)=="" and decoded.rooms[1].challenge.type=="数字快答","challenge JSON round trip")
 var plain=Model.make_room("r","r",18,14,"矩形");plain.challenge={"type":"数字快答","seconds":8.0}
 var reshaped=Model.reshape({"schema":2,"rooms":[plain]},"r",20,16,"矩形",0)
 check(reshaped.error=="" and reshaped.level.rooms[0].challenge.seconds==8.0,"reshape preserves challenge")
 for bad in [{"type":"unknown"},{"seconds":0},{"green":"NaN"},{"rounds":1.2},{"rounds":31}]:check(C.validate(bad)!="","reject malformed challenge")
 app.level=data;app.room_index=0;app.playing=false;app.toggle_play()
 var st=app.runtime[0].challenge;var conf=C.config(app.room())
 app.player=Vector2(96,96);st.elapsed=conf.green+conf.warning+0.1;st.phase="red"
 C.update(app,0.02,app.player-Vector2(7,0));check(not app.alive,"red movement fails")
 app.retry();st=app.runtime[0].challenge
 check(not st.done and st.elapsed==0 and app.alive,"retry resets challenge")
 st.elapsed=conf.green+conf.warning+0.1;st.phase="red"
 C.update(app,0.02,app.player);check(app.alive,"standing still during red survives")
 var target={}
 for o in app.room().objects:
  if o.kind=="开关" and not Model.door_by_id(app.room(),o.link).get("entry",false):target=o;break
 app.player=app.cell_center([target.x,target.y]);app.activate_switch()
 check(app.runtime[0].doors[target.link]==0,"challenge locks door switch")
 st.phase="green";st.elapsed=0;C.update(app,0.01,app.player)
 check(st.done and st.bomb==0,"arrival arms bomb")
 app.activate_switch();check(app.runtime[0].doors[target.link]>0,"completed challenge enables manual switch")
 C.update(app,conf.fuse+0.1,app.player);check(not app.alive,"remaining near bomb fails")
 app.retry();st=app.runtime[0].challenge;st.done=true;st.bomb=0;st.goal=app.player+Vector2(200,0)
 C.update(app,conf.fuse+0.1,app.player);check(app.alive,"leaving blast radius survives")
 app.playing=false;app.level=Library.challenges();app.level.rooms[0].challenge={"type":"数字快答","rounds":2,"seconds":2};app.toggle_play()
 st=app.runtime[0].challenge;conf=C.config(app.room())
 var t=st.question_time;app.overview=true;app._process(0.1);check(st.question_time==t,"map pause freezes challenge timer");app.overview=false
 var wrong=(st.choices.find(st.answer)+1)%3;app.answer_challenge(wrong);check(not app.alive,"wrong answer fails")
 app.retry();st=app.runtime[0].challenge
 app.answer_buttons[st.choices.find(st.answer)].pressed.emit();check(st.round==1 and not st.done,"correct answer advances")
 app.answer_challenge(st.choices.find(st.answer));check(st.round==2 and st.done,"final answer unlocks exit")
 app.retry();C.update(app,2.1,app.player);check(not app.alive,"answer timeout fails")
 check(app.runtime[1].challenge.elapsed==0,"unvisited room challenge stays idle")
 app.show_home()
 print("024 START + CHALLENGE TESTS ",checks," checks / ",("PASS" if failures.is_empty() else str(failures)))
