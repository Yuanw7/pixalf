extends Node
const Character=preload("res://character_catalog.gd")
const Art=preload("res://dungeon_art.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 030 ",label)
func key(code):
 var event=InputEventKey.new();event.keycode=code;event.pressed=true;return event
func run(app):
 var game=app.legacy_game
 game.start_game("catacombs",Character.DEFAULT)
 game._input(key(KEY_SPACE));game._process(.017)
 check(game.state.heroes[0].jumpTime>0 and game.state.heroes[0].dash==0,"Space jumps without dashing")
 game.command("retry");game._input(key(KEY_SHIFT));game._process(.017)
 check(game.state.heroes[0].dash>0 and game.state.heroes[0].jumpTime==0,"Shift dashes without jumping")
 game.command("retry");game._input(key(KEY_E));game._process(.017)
 check(game.state.heroes[0].jumpTime>0,"legacy E jump remains available")
 var source=game.simulation_source();var end=source.rfind("})();")
 source=source.substr(0,end)+FileAccess.get_file_as_string("res://test_fixtures/combat.js")+source.substr(end)
 game.runtime.bridge.run_json(JSON.stringify({"op":"sim_boot","source":source,"payload":{"op":"boot","map":"catacombs","weapon":"sword","assets":game.assets,"records":{}}}))
 game.state=game.invoke("sim_step",{"op":"fixture","distances":[65,200],"hp":100});game.frame_budget=0
 game._input(key(KEY_K));game._process(.1)
 check(game.state.enemies[0].hp==45 and game.state.enemies[1].hp==100,"K preserves damage and range")
 check(game.state.combat.fx.any(func(e):return e.kind=="skill") and game.state.combat.fx.any(func(e):return e.kind=="skill_hit"),"K emits fast cut and confirmed hit burst")
 check(game.impact_pause>0 and not game.state.commands.is_empty(),"batched K hit stops on a rendered impact frame")
 var time=game.state.time;game._process(.02)
 check(game.state.time==time,"hit stop freezes simulation for a short interval")
 game._process(.04);game._process(.02)
 check(game.state.time>time,"simulation resumes after hit stop")
 game._input(key(KEY_K));game._process(.02)
 check(game.state.enemies[0].hp==45 and game.state.combat.skillImpact==1,"held/repeated K cannot bypass cooldown")
 for i in range(25):game._process(.017)
 check(not game.state.combat.fx.any(func(e):return e.kind in ["skill","skill_hit"]),"skill visuals expire promptly")
 game.command("retry")
 check(game.impact_pause==0 and game.state.combat.fx.is_empty(),"retry clears impact freeze and FX")
 game.runtime.bridge.run_json(JSON.stringify({"op":"sim_boot","source":source,"payload":{"op":"boot","map":"catacombs","weapon":"sword","assets":game.assets,"records":{}}}))
 game.state=game.invoke("sim_step",{"op":"fixture","wall":true,"distances":[140],"hp":100});game.frame_budget=0
 game._input(key(KEY_K));game._process(.017)
 check(game.state.enemies[0].hp==100 and game.impact_pause==0,"K cannot hit through the closed door or freeze on a miss")
 var background=game.background.get_child(0)
 check(not background.depth_floor.is_empty() and not background.depth_walls.is_empty(),"new dungeon skin follows original floor and wall footprints")
 game.finish()
 app.level=preload("res://map_model.gd").four_rooms();app.playing=false;app.resume_editor();app.toggle_play()
 app._input(key(KEY_SPACE));app.tick(.1,Vector2.ZERO);var air=app.air_time;app._input(key(KEY_SPACE))
 check(air>0 and app.air_time==air,"workshop Space jumps and cannot restart in air")
 app._input(key(KEY_K));app._input(key(KEY_K))
 check(app.combat_fx.filter(func(e):return e.kind=="skill").size()==1,"workshop K preview obeys cooldown")
 app.retry();check(app.air_time==0 and app.jump_cool==0 and app.skill_cool==0,"workshop retry resets jump and skill")
 check(Art.STEEL["72d6ceff"].b-Art.STEEL["72d6ceff"].r<.07,"plate armor uses neutral steel gray")
 app.show_home()
 print("030 INPUT + FEEL + SCENERY TESTS ",checks," checks / ",("PASS" if failures.is_empty() else str(failures)))
