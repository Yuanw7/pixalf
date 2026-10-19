extends RefCounted
const SLOTS={"helmet":"头部","chest":"护甲","weapon":"主手武器","shield":"副手"}
const OPTIONS={"helmet":["none","armet","barbuta"],"chest":["leather","plate"],"weapon":["none","sword","axe","spear","kunai"],"shield":["none","roundshield"]}
const NAMES={"none":"无","armet":"闭面盔","barbuta":"开面盔","leather":"皮甲","plate":"板甲","sword":"长剑","axe":"战斧 · 双手","spear":"长矛 · 双手","kunai":"地宫飞刀 · 远程","roundshield":"圆盾"}
const DEFAULT={"helmet":"armet","chest":"plate","weapon":"sword","shield":"roundshield"}
const PROFILE="user://appearance-v1.json"
const DIRECTIONS=["north","west","south","east"]
const LAYERS={"body":10,"head":100,"pants":20,"boots":25,"plate":60,"leather":60,"armet":130,"barbuta":130,"roundshield":120,"sword_front":140,"sword_back":9,"sword_attack_front":150,"sword_attack_back":8,"axe_front":140,"axe_back":9,"axe_attack_front":150,"axe_attack_back":8,"spear_front":140,"spear_back":9}
static var frames_cache: Dictionary={}
static func two_handed(weapon: String) -> bool:return weapon in ["axe","spear"]
static func valid(data: Variant) -> bool:
 if not data is Dictionary:return false
 for slot in SLOTS:
  if not data.get(slot) is String or not OPTIONS[slot].has(data[slot]):return false
 return not (two_handed(data.weapon) and data.shield!="none")
static func equip(current: Dictionary,slot: String,item: String) -> Dictionary:
 if not SLOTS.has(slot) or not OPTIONS[slot].has(item):return {"error":"未知装备","outfit":current.duplicate(true)}
 var next=current.duplicate(true)
 if slot=="shield" and item!="none" and two_handed(next.weapon):return {"error":"双手武器不能同时装备盾牌，请先改用长剑、飞刀或空手。","outfit":next}
 next[slot]=item
 var note=""
 if slot=="weapon" and two_handed(item) and next.shield!="none":next.shield="none";note="已自动卸下圆盾，双手武器占用双手。"
 return {"error":"","outfit":next,"note":note}
static func read_profile(path: String=PROFILE) -> Dictionary:
 if not FileAccess.file_exists(path):return {"outfit":DEFAULT.duplicate(),"error":""}
 var f=FileAccess.open(path,FileAccess.READ)
 if f==null or f.get_length()>16384:return {"outfit":DEFAULT.duplicate(),"error":"外观配置无法读取，使用默认角色，原文件保留。"}
 var parser=JSON.new();var result=parser.parse(f.get_as_text());f.close()
 if result!=OK or not parser.data is Dictionary or not ((parser.data.get("schema")==1 and parser.data.get("rig")=="lpc_male_v1") or (parser.data.get("schema")==2 and parser.data.get("rig")=="dungeon_hero_v1")) or not valid(parser.data.get("outfit")):
  return {"outfit":DEFAULT.duplicate(),"error":"外观配置无效，使用默认角色，原文件保留。"}
 return {"outfit":parser.data.outfit.duplicate(),"error":""}
static func save_profile(outfit: Dictionary,path: String=PROFILE) -> String:
 if not valid(outfit):return "装备组合无效"
 var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if file==null:return "无法写入外观配置"
 file.store_string(JSON.stringify({"schema":2,"rig":"dungeon_hero_v1","outfit":outfit},"  "));file.flush();var error=file.get_error();file.close()
 if error!=OK:return "写入失败，原配置保留"
 if FileAccess.file_exists(path) and DirAccess.copy_absolute(path,path+".bak")!=OK:return "备份失败，原配置保留"
 if DirAccess.rename_absolute(path+".tmp",path)!=OK:return "保存失败，原配置保留"
 return ""
static func layers(outfit: Dictionary,action: String) -> Array:
 var result=["body","head","pants","boots",outfit.chest]
 if outfit.helmet!="none":result.append(outfit.helmet)
 if outfit.shield!="none":result.append(outfit.shield)
 var weapon=outfit.weapon
 if weapon not in ["none","kunai"]:
  var prefix=weapon+"_attack" if action=="attack" and weapon in ["sword","axe"] else weapon
  result.append(prefix+"_back");result.append(prefix+"_front")
 result.sort_custom(func(a,b):return LAYERS[a]<LAYERS[b])
 return result
static func frames(id: String) -> SpriteFrames:
 if not frames_cache.has(id):frames_cache[id]=load("res://art/lpc/baked/"+id+".tres")
 return frames_cache[id]
static func clip(outfit: Dictionary,action: String,direction: String) -> String:
 var name=action
 if name=="attack":name="thrust" if outfit.weapon in ["spear","kunai"] else "slash"
 return name+"_"+("south" if name=="hurt" else direction)
static func frame_index(action: String,time: float,count: int) -> int:
 if action=="idle":return 0
 if action=="hurt":return mini(count-1,int(time*10))
 return int(time*(10 if action=="walk" else 9))%count
static func draw_actor(canvas: CanvasItem,outfit: Dictionary,feet: Vector2,action: String,direction: String,time: float,scale: float=1.0):
 if action=="victory":feet.y-=preload("res://combat_visual.gd").victory_height(time)*scale
 preload("res://dungeon_art.gd").draw_hero(canvas,outfit,feet,action,direction,time,scale)
