extends Node
const Character=preload("res://character_catalog.gd")
const Model=preload("res://map_model.gd")
const Combat=preload("res://combat_visual.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 027 ",label)
func run(app):
 var saved=app.outfit.duplicate(true)
 var ranged=Character.equip(Character.DEFAULT,"weapon","kunai").outfit
 check(Character.valid(ranged) and ranged.shield=="roundshield","ranged gear composes with shield")
 check(Combat.KNIFE.get_width()>0,"ranged icon imported")
 app.level=Model.four_rooms();app.playing=false;app.resume_editor();app.toggle_play();app.outfit=ranged;app.actor_direction="east"
 app.workshop_attack();check(app.combat_shots.size()==1 and app.actor_action=="attack","workshop J starts throw")
 app.workshop_attack();check(app.combat_shots.size()==1,"cooldown prevents repeated attack in one frame")
 for i in range(100):app.tick(.016,Vector2.ZERO)
 check(app.combat_shots.is_empty(),"workshop projectiles expire or hit walls")
 app.retry();check(app.combat_fx.is_empty() and app.combat_shots.is_empty(),"retry clears workshop FX")
 app.room_index=3
 var gate={}
 for o in app.room().objects:
  if o.kind=="隔板门" and o.target=="finish":gate=o
 for o in app.room().objects:
  if o.kind=="开关" and o.link==gate.id:app.player=app.cell_center([o.x,o.y])
 app.activate_switch();app.tick(.4,Vector2.RIGHT)
 check(app.won and app.victory_time>0 and Combat.victory_height(app.victory_time)>0,"button starts airborne celebration")
 app.tick(.4,Vector2.ZERO);check(app.runtime[3].doors[gate.id]==1,"final door finishes opening during celebration")
 app.retry();check(app.victory_time==0 and not app.won,"retry resets victory clock")
 app.outfit=saved;app.show_home()
 var game=app.legacy_game;game.start_game("catacombs",ranged)
 check(game.state.combat.weapon=="kunai","selected ranged weapon reaches QuickJS")
 game.wardrobe_closed(Character.DEFAULT);check(game.state.combat.weapon=="sword","mid-run wardrobe updates real combat")
 game.state.mode="won";game.refresh_state();game._process(.2)
 check(game.victory_time==0 and not game.surface.victorious,"arrival alone cannot start victory")
 game.confirm_victory();game._process(.05)
 check(game.victory_time>0 and game.surface.victorious and not game.resume_button.visible,"classic celebration plays before replay button")
 var time=game.victory_time;game.confirm_victory();check(game.victory_time==time,"repeated F does not restart celebration")
 game.frozen=true;game._process(.3);check(game.victory_time==time,"wardrobe pauses victory")
 game.frozen=false;var retry_key=InputEventKey.new();retry_key.keycode=KEY_R;retry_key.pressed=true;game._input(retry_key);check(game.victory_time==0 and not game.surface.victorious,"classic retry resets celebration")
 game.finish()
 print("027 COMBAT + VICTORY TESTS ",checks," checks / ",("PASS" if failures.is_empty() else str(failures)))

func capture_review(app):
 app.show_home();app.home.hide()
 var game=app.legacy_game
 var weapon="sword"
 for id in ["sword","spear","kunai"]:
  if ("--"+id) in OS.get_cmdline_user_args():weapon=id
 var equipment=Character.equip(Character.DEFAULT,"weapon",weapon).outfit
 game.start_game("catacombs",equipment)
 var source=game.simulation_source();var end=source.rfind("})();")
 source=source.substr(0,end)+FileAccess.get_file_as_string("res://test_fixtures/combat.js")+source.substr(end)
 game.state=JSON.parse_string(game.runtime.bridge.run_json(JSON.stringify({"op":"sim_boot","source":source,"payload":{"op":"boot","map":"catacombs","weapon":weapon,"assets":game.assets,"records":{}}})))
 game.state=game.invoke("sim_step",{"op":"fixture","weapon":weapon,"distances":[140 if weapon=="kunai" else 65]})
 if "--remains" in OS.get_cmdline_user_args():
  game.state=game.invoke("sim_step",{"op":"fixture_damage"})
  for i in range(50):game.state=game.invoke("sim_step",{"op":"step","dt":1.0/60,"render":i==49})
 elif "--victory" in OS.get_cmdline_user_args():
  game.state.mode="won";game.confirm_victory();game.victory_time=.4
 else:
  for i in range(7):game.state=game.invoke("sim_step",{"op":"step","dt":1.0/60,"keys":["j"],"render":i==6})
 game.refresh_state();game.frozen=true
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var suffix="victory" if "--victory" in OS.get_cmdline_user_args() else "remains" if "--remains" in OS.get_cmdline_user_args() else weapon
 var destination="user://027-"+suffix+".png"
 get_viewport().get_texture().get_image().save_png(destination)
 print("CAPTURE "+ProjectSettings.globalize_path(destination))
