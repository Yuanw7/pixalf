extends Node
const Character=preload("res://character_catalog.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 022 ",label)
func run(app):
 var game=app.legacy_game
 var draft=JSON.stringify(app.level)
 check(game.start_game("catacombs",Character.DEFAULT),"native dungeon boots")
 check(not app.classic_runtime.active,"WebView not active")
 check(game.state.design.rooms.size()==4 and game.state.design.mechanisms.size()==29,"four original rooms and 29 original traps")
 check(game.state.design.boards==[{"x":224.0,"y":560.0},{"x":1600.0,"y":560.0}],"original answer board positions")
 check(game.state.design.beam.gaps==[[560.0,640.0],[992.0,1080.0],[1456.0,1552.0]],"original plank gaps")
 check(game.surface.textures.size()>=44,"original assets and native background texture loaded")
 check(game.state.commands.any(func(c):return c[0]=="lpc"),"protagonist uses LPC draw command")
 var initial=game.state.heroes[0].x
 var started=Time.get_ticks_usec()
 for i in range(60):game.state=game.invoke("sim_step",{"op":"step","dt":1.0/60,"keys":["d"],"render":i==59})
 check(game.state.heroes[0].x>initial+170,"original normal-speed movement")
 print("022 native step avg_ms=",(Time.get_ticks_usec()-started)/60000.0)
 game.state=game.invoke("sim_step",{"op":"step","dt":1.0/60,"actions":["e","j"],"keys":["j"]})
 check(game.state.heroes[0].jumpTime>0 and game.state.heroes[0].attack>0,"jump and real attack reach old simulation")
 check(game.state.commands.any(func(c):return c[0]=="lpc" and c[11]>0),"LPC attack animation driven by combat state")
 var before=game.state.time
 for button in game.get_child(1).get_children():
  if button is Button and button.text=="角色衣柜":button.pressed.emit()
 check(app.outfit_panel.visible and game.frozen,"actual wardrobe button opens and pauses")
 game._process(1)
 check(game.state.time==before,"wardrobe freezes simulation")
 var axe=Character.equip(Character.DEFAULT,"weapon","axe").outfit
 app.outfit_panel.hide()
 check(not game.frozen,"wardrobe cancel resumes through visibility callback")
 game.wardrobe_closed(axe)
 check(game.surface.outfit.weapon=="axe" and not game.frozen,"wardrobe equipment applies to classic protagonist")
 check(game.state.time==before,"equipment change does not restart level")
 game.command("pause");before=game.state.time
 game.state=game.invoke("sim_step",{"op":"step","dt":1.0/60,"keys":["d"]})
 check(game.state.mode=="paused" and game.state.time==before,"pause stops hazards and enemies")
 game.command("resume");check(game.state.mode=="playing","resume")
 game.command("retry");check(game.state.trial.stage==0 and game.state.heroes[0].hp==170 and game.state.heroes[0].x==144,"checkpoint retry restores original state")
 game.finish();check(not game.active and not game.visible and JSON.stringify(app.level)==draft,"return preserves workshop draft")
 check(game.start_game("forest",axe) and game.state.mapId=="forest","native forest also available")
 check(game.state.design.forest.bridges.size()==2,"original forest bridges")
 game.finish()
 print("022 NATIVE CLASSIC TESTS ",checks," checks / ",("PASS" if failures.is_empty() else str(failures)))
