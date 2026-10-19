extends Node
const Character=preload("res://character_catalog.gd")
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 019 ",label)
func run(app):
 check(Character.valid(Character.DEFAULT),"default equipment valid")
 var original=Character.DEFAULT.duplicate();var changed=Character.equip(original,"weapon","axe")
 check(changed.error=="" and changed.outfit.shield=="none","two-handed axe unequips shield")
 check(original.shield=="roundshield" and original.weapon=="sword","equip does not mutate input")
 var rejected=Character.equip(changed.outfit,"shield","roundshield")
 check(rejected.error!="" and rejected.outfit.shield=="none","shield conflict is rejected atomically")
 check(not Character.valid({"helmet":"???"}),"unknown items rejected")
 # Validate imported atlas bounds once per layer/clip, then validate every legal composition.
 for id in Character.LAYERS:
  var frames=Character.frames(id)
  check(frames!=null,"baked layer exists "+id)
  for animation in frames.get_animation_names():
   if animation=="default":continue
   var valid_bounds=true
   for frame in range(frames.get_frame_count(animation)):
    var texture=frames.get_frame_texture(animation,frame)
    valid_bounds=valid_bounds and texture is AtlasTexture and Rect2(Vector2.ZERO,texture.atlas.get_size()).encloses(texture.region)
   check(valid_bounds,"atlas frame bounds "+id+" "+animation)
 var combinations=0
 for helmet in Character.OPTIONS.helmet:
  for chest in Character.OPTIONS.chest:
   for weapon in Character.OPTIONS.weapon:
    for shield in Character.OPTIONS.shield:
     var outfit={"helmet":helmet,"chest":chest,"weapon":weapon,"shield":shield}
     if not Character.valid(outfit):continue
     combinations+=1
     for action in ["idle","walk","attack","hurt"]:
      for direction in Character.DIRECTIONS:
       var clip=Character.clip(outfit,action,direction);var body=Character.frames("body")
       var coherent=body.has_animation(clip);var body_count=body.get_frame_count(clip);var sorted=-100
       for id in Character.layers(outfit,action):
        coherent=coherent and Character.LAYERS[id]>=sorted;sorted=Character.LAYERS[id]
        var frames=Character.frames(id)
        if not frames.has_animation(clip):
         coherent=coherent and action=="hurt" and id in ["roundshield","axe_back"]
         continue
        coherent=coherent and frames.get_frame_count(clip)==body_count
       check(coherent,"synchronized composition %d %s"%[combinations,clip])
 check(combinations==48,"48 compatible outfit combinations")
 print("019 compatible combinations=",combinations)
 # Per-profile storage is isolated from authored map JSON.
 var path="user://test-appearance019.json"
 check(Character.save_profile(changed.outfit,path)=="","profile save")
 check(Character.read_profile(path).outfit==changed.outfit,"profile roundtrip")
 check(Character.save_profile(original,path)=="" and FileAccess.file_exists(path+".bak"),"profile overwrite backup")
 check(Character.save_profile({"weapon":"bad"},path)!="" and Character.read_profile(path).outfit==original,"invalid update preserves profile")
 var file=FileAccess.open(path,FileAccess.WRITE);file.store_string("broken");file.close()
 check(Character.read_profile(path).outfit==Character.DEFAULT and FileAccess.get_file_as_string(path)=="broken","corrupt profile fallback preserves file")
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
 var saved=app.outfit.duplicate();var map_before=JSON.stringify(app.level)
 app.outfit_panel.open(saved);app.outfit_panel.change_equipment("weapon","spear")
 check(app.outfit_panel.draft.weapon=="spear" and app.outfit==saved,"preview changes do not apply early")
 app.outfit_panel.hide();check(app.outfit==saved,"cancel preserves live outfit")
 check(JSON.stringify(app.level)==map_before,"appearance independent of map")
 app.home.hide();app.playing=false;app.toggle_play()
 for pair in [[Vector2.RIGHT,"east"],[Vector2.UP,"north"],[Vector2.LEFT,"west"],[Vector2.DOWN,"south"]]:
  app.tick(0.01,pair[0]);check(app.actor_direction==pair[1] and app.actor_action=="walk","movement direction "+pair[1])
 app.tick(0.01,Vector2.ZERO);check(app.actor_action=="idle","stop uses idle")
 app.outfit_panel.open(saved);var old_time=app.runtime[0].time;app._process(0.05)
 check(app.runtime[0].time==old_time,"wardrobe pauses traps")
 app.outfit_panel.hide();app.die("test");app.tick(0.05,Vector2.ZERO)
 check(app.actor_action=="hurt" and app.actor_time>0,"death animation clock")
 app.retry();check(app.actor_action=="idle" and app.actor_time==0,"retry resets actor clock")
 app.toggle_play();app.outfit=saved;app.show_home()
 print("019 CHARACTER TESTS ",checks," checks / ",("PASS" if failures.is_empty() else str(failures)))
