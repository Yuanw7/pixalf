extends Node
const Model=preload("res://map_model.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 025 ",label)
func run(app):
 app.resume_editor();app.trap_picker.open("地刺")
 check(app.trap_picker.visible and app.trap_picker.grid.get_child_count()==12,"picker exposes all traps")
 app.trap_picker.search.text="喷火";app.trap_picker.search.text_changed.emit("喷火");check(app.trap_picker.grid.get_child_count()==1,"search matches descriptions")
 app.trap_picker.search.text="notfound";app.trap_picker.search.text_changed.emit("notfound");check(app.trap_picker.place.disabled,"empty search cannot place stale selection")
 app.trap_picker.open("炸弹");app.trap_picker.place.pressed.emit();check(app.tool=="炸弹" and not app.trap_picker.visible,"choose tool returns to editor")
 app.overview=true;app.update_join_buttons()
 check(app.join_buttons.size()==4 and app.join_buttons[0].visible and app.join_buttons[0].icon==app.plus_texture,"four asset-based join controls")
 app.join_buttons[0].pressed.emit();check(app.shape_dialog.visible,"join asset button opens room creation");app.shape_dialog.hide()
 app.level=Model.four_rooms();app.playing=false;app.toggle_play();app.room_index=3
 var gate={};var switch={}
 for o in app.room().objects:
  if o.kind=="隔板门" and o.target=="finish":gate=o
 for o in app.room().objects:
  if o.kind=="开关" and o.link==gate.id:switch=o
 app.runtime[3].doors[gate.id]=1.0;app.player=app.cell_center([gate.x,gate.y]);app.cross_door()
 check(not app.won,"crossing final door alone does not win")
 app.runtime[3].doors[gate.id]=0;app.player=app.cell_center([switch.x,switch.y]);app.activate_switch()
 check(app.won and app.runtime[3].cleared,"final button immediately wins")
 app.retry();check(not app.won and not app.runtime[3].cleared,"retry resets completion")
 app.die("test");app.tick(0.3,Vector2.ZERO);check(app.failure_time>0 and app.actor_action=="hurt" and app.actor_time>0,"defeat animates before result overlay")
 var time=app.failure_time;app.die("duplicate");check(app.failure_time==time,"duplicate hit does not restart animation")
 app.retry();check(app.failure_time==0 and app.alive,"retry clears defeat animation")
 app.show_home()
 var game=app.legacy_game
 check(game.start_game("catacombs",app.outfit),"classic boots for presentation tests")
 game.state.mode="won";game.refresh_state();check(not game.victory_confirmed and game.resume_button.text.contains("终点按钮"),"classic awaits explicit victory button")
 game.resume_button.pressed.emit();check(game.victory_confirmed,"classic button confirms victory")
 game.state.mode="lost";game._process(0.3);check(game.surface.defeated and game.surface.defeat_time>0,"classic defeat animation advances while rules stopped")
 game.finish()
 print("025 BUTTONS + UX TESTS ",checks," checks / ",("PASS" if failures.is_empty() else str(failures)))
