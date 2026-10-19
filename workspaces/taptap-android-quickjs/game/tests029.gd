extends Node
const Art=preload("res://dungeon_art.gd")
const Character=preload("res://character_catalog.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 029 ",label)
func run(app):
 # Every live enemy frame and both modular hero sources must exist.
 for actor in Art.ENEMIES.values()+["elf_m"]:
  for action in ["idle","run"]:
   for frame in range(4):
    var tex=Art.texture(actor+"_"+action+"_anim_f"+str(frame))
    check(tex!=null and tex.get_width()>0,"source frame "+actor+str(frame))
 # Verify the real grip after mirroring, animation, camera-independent scaling.
 for weapon in Art.WEAPONS:
  var tex=Art.texture(Art.WEAPONS[weapon])
  check(Rect2(Vector2.ZERO,tex.get_size()).has_point(Art.GRIPS[weapon]),"grip inside source "+weapon)
  for direction in Character.DIRECTIONS:
   for action in ["idle","walk","attack","victory"]:
    var attached=true
    for frame in range(12):
     var pose=Art.pose(action,frame*.031,direction,weapon)
     var body=Transform2D(Vector2(-2.3 if direction=="west" else 2.3,0),Vector2(0,2.3),Vector2(477,332))
     var grip=Art.weapon_transform(body,pose,weapon)*Art.GRIPS[weapon]
     attached=attached and grip.distance_to(body*pose.hand)<.001
    check(attached,"animated grip "+weapon+" "+direction+" "+action)
 # Upgrade old equipment without modifying it on read or touching map storage.
 var path="user://test-appearance029.json";var outfit=Character.equip(Character.DEFAULT,"weapon","kunai").outfit
 var old=JSON.stringify({"schema":1,"rig":"lpc_male_v1","outfit":outfit})
 var f=FileAccess.open(path,FileAccess.WRITE);f.store_string(old);f.close()
 check(Character.read_profile(path).outfit==outfit and FileAccess.get_file_as_string(path)==old,"legacy outfit read is non-destructive")
 check(Character.save_profile(outfit,path)=="" and Character.read_profile(path).outfit==outfit,"new rig preserves all equipped slots")
 check(JSON.parse_string(FileAccess.get_file_as_string(path)).rig=="dungeon_hero_v1" and FileAccess.get_file_as_string(path+".bak")==old,"migration keeps previous file backup")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 var game=app.legacy_game;game.start_game("catacombs",outfit)
 var commands=game.state.commands
 check(commands.any(func(c):return c[0]=="lpc"),"player still uses shared modular renderer")
 check(commands.any(func(c):return c[0]=="dungeon_actor"),"live classic enemies use new renderer")
 check(not commands.any(func(c):return c[0]=="image" and (str(c[4]).begins_with("Monster") or c[4]=="Slime" or str(c[4]).begins_with("Demon_A"))),"no old enemy images in live frame")
 game.finish()
 print("029 DUNGEON HERO TESTS ",checks," checks / ",("PASS" if failures.is_empty() else str(failures)))
