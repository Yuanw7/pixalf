extends SceneTree
const Art=preload("res://dungeon_art.gd")
const Character=preload("res://character_catalog.gd")
class Sheet extends Control:
 func _draw():
  draw_rect(Rect2(0,0,1280,800),Color("18221b"))
  draw_string(ThemeDB.fallback_font,Vector2(40,48),"029 / DUNGEON HERO · 持械 / 换装 / 新怪物",HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color("d5bb78"))
  var weapons=["sword","axe","spear","kunai","none","kunai"]
  for i in range(6):
   var outfit=Character.equip(Character.DEFAULT,"weapon",weapons[i]).outfit
   outfit.helmet=["armet","barbuta","none"][i%3];outfit.chest="leather" if i%2 else "plate"
   var at=Vector2(110+i*205,195)
   Character.draw_actor(self,outfit,at,"idle","east",0,2)
   draw_string(ThemeDB.fallback_font,at+Vector2(-55,30),Character.NAMES[weapons[i]],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("d5bb78"))
  var ranged=Character.equip(Character.DEFAULT,"weapon","kunai").outfit
  for i in range(6):
   var at=Vector2(110+i*205,400);var dir=["east","west","north","south","east","west"][i]
   Character.draw_actor(self,ranged,at,"attack" if i<4 else "walk",dir,.14,2)
   draw_string(ThemeDB.fallback_font,at+Vector2(-65,32),["投掷 · 东","投掷 · 西","投掷 · 北","投掷 · 南","跑步 · 东","跑步 · 西"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("d5bb78"))
  var enemies=["Slime","Monster03","Monster00","Monster02","Monster01","Monster09"]
  for i in range(6):
   var at=Vector2(110+i*205,640)
   Art.draw_enemy(self,enemies[i],at,true,.1,-1,0,false,0,1.5)
   Art.draw_remains(self,{"asset":enemies[i],"x":at.x,"y":735,"age":1,"life":12,"face":1})
   draw_string(ThemeDB.fallback_font,at+Vector2(-62,27),Art.ENEMIES[enemies[i]],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("d5bb78"))
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1280,800);root.canvas_item_default_texture_filter=Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
 var sheet=Sheet.new();root.add_child(sheet);sheet.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://../reports/029/hero-monsters.png")
 print("CAPTURE 029 hero-monsters.png");sheet.queue_free()
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 await process_frame
 app.show_home();app.home.hide()
 var game=app.legacy_game;game.persist_records=false
 var equipment=Character.equip(Character.DEFAULT,"weapon","kunai").outfit
 game.start_game("catacombs",equipment);game.frozen=true
 var source=game.simulation_source();var end=source.rfind("})();")
 source=source.substr(0,end)+FileAccess.get_file_as_string("res://test_fixtures/combat.js")+source.substr(end)
 game.runtime.bridge.run_json(JSON.stringify({"op":"sim_boot","source":source,"payload":{"op":"boot","map":"catacombs","weapon":"kunai","assets":game.assets,"records":{}}}))
 game.state=game.invoke("sim_step",{"op":"fixture","weapon":"kunai","distances":[140,200,230]})
 for i in range(7):game.state=game.invoke("sim_step",{"op":"step","dt":1.0/60,"keys":["j"],"render":i==6})
 game.refresh_state()
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://../reports/029/classic-ranged.png")
 game.finish();app.outfit_panel.open(equipment);app.outfit_panel.action="walk"
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://../reports/029/wardrobe.png")
 quit()
