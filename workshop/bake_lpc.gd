extends SceneTree
const SpritePlugin=preload("res://addons/LPCAnimatedSprite/LPCAnimatedSprite2D.gd")
const DataPlugin=preload("res://addons/LPCAnimatedSprite/LPCAnimationDataBase.gd")
func _init():
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://art/lpc/manifest.json"))
 var grouped={}
 for row in manifest.files:
  if not grouped.has(row.id):grouped[row.id]=[]
  grouped[row.id].append(row)
 DirAccess.make_dir_recursive_absolute("res://art/lpc/baked")
 for id in grouped:
  var data=DataPlugin.new()
  for row in grouped[id]:
   var action="slash" if row.animation=="slash_oversize" else row.animation
   var frame_size=int(row.size[1]) if action=="hurt" else int(row.size[1])/4
   var count=int(row.size[0])/frame_size
   data.available_animations.append(action)
   data.required_spritesheets[action]=row.animation
   data.available_directions[action]={"south":0} if action=="hurt" else {"north":0,"west":1,"south":2,"east":3}
   data.animation_frame_counts[action]=count
   data.initial_sprite_indices[action]=0
   data.animation_loops[action]=action in ["idle","walk"]
   data.animation_speeds[action]=10 if action=="walk" else 9
   data.animation_rows[action]=0;data.frame_sizes[action]=frame_size
   if action=="walk":
    data.custom_frames[action]=range(1,count)
    data.available_animations.append("idle");data.required_spritesheets.idle="walk"
    data.available_directions.idle=data.available_directions.walk.duplicate()
    data.animation_frame_counts.idle=1;data.initial_sprite_indices.idle=0
    data.animation_loops.idle=true;data.animation_speeds.idle=1;data.animation_rows.idle=0;data.frame_sizes.idle=frame_size
  var sprite=SpritePlugin.new()
  sprite._spritesheets_path="res://art/lpc/"+id
  sprite.animation_data=data
  var result=ResourceSaver.save(sprite.sprite_frames,"res://art/lpc/baked/"+id+".tres")
  if result!=OK:push_error("Bake failed "+id);quit(1);return
  print("BAKED ",id," ",sprite.sprite_frames.get_animation_names().size()," clips")
  sprite.free()
 print("LPCAnimatedSprite2D baked ",grouped.size()," layers")
 quit()
