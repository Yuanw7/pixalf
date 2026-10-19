extends Control
signal returned
signal wardrobe_requested
const Runtime=preload("res://classic_runtime.gd")
const Canvas=preload("res://legacy_canvas.gd")
const Character=preload("res://character_catalog.gd")
var runtime
var state: Dictionary={}
var outfit=Character.DEFAULT.duplicate()
var surface: Control
var background: SubViewport
var assets: Dictionary
var pending_actions: Array=[]
var pending_pointer: Array=[]
var victory_confirmed=false
var defeat_time=0.0
var victory_time=0.0
var frozen=false
var active=false
var stats: Label
var message: Label
var title: Label
var resume_button: Button
var frame_budget=0.0
var last_records=""
var persist_records=true
var elapsed_cost=0
var impact_pause=0.0
var last_skill_impact=0
const RECORDS="user://classic-native-records.json"
func _ready():
 persist_records=not ("--self-test" in OS.get_cmdline_user_args() or "--capture-combat" in OS.get_cmdline_user_args() or "--capture-dungeon" in OS.get_cmdline_user_args())
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 var backdrop=ColorRect.new();backdrop.color=Color("141e17");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
 var bar=HBoxContainer.new();bar.position=Vector2(16,18);add_child(bar)
 add_button("‹ 我的地图",bar,finish)
 add_button("角色衣柜",bar,func():frozen=true;wardrobe_requested.emit())
 add_button("暂停 / P",bar,func():command("pause"))
 add_button("重试 / R",bar,func():command("retry"))
 add_button("地图 / M",bar,func():pending_actions.append("m"))
 title=Label.new();title.position=Vector2(20,64);title.add_theme_font_size_override("font_size",20);add_child(title)
 surface=Canvas.new();surface.font=theme.default_font;surface.position=Vector2(16,112);surface.size=Vector2(960,600);surface.mouse_filter=Control.MOUSE_FILTER_IGNORE;surface.clip_contents=true;add_child(surface)
 stats=Label.new();stats.position=Vector2(994,112);stats.size=Vector2(268,500);stats.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(stats)
 message=Label.new();message.position=Vector2(16,729);message.size=Vector2(1240,60);message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(message)
 resume_button=add_button("继续 / 重试",self,func():
  if state.get("mode","")=="won" and not victory_confirmed:confirm_victory()
  else:command("continue"));resume_button.position=Vector2(994,624);resume_button.size=Vector2(248,48)
 background=SubViewport.new();background.size=Vector2i(2240,1440);background.disable_3d=true;background.render_target_update_mode=SubViewport.UPDATE_DISABLED;add_child(background)
 assets=JSON.parse_string(FileAccess.get_file_as_string("res://legacy_rules/assets.json"))
 for id in assets:
  var image=(load("res://legacy_rules/art/"+id+"."+assets[id][2]) as Texture2D).get_image()
  surface.textures[id]=ImageTexture.create_from_image(image)
 runtime=Runtime.new();hide()
func add_button(text_value: String,parent: Node,action: Callable) -> Button:
 var b=Button.new();b.text=text_value;b.custom_minimum_size=Vector2(0,36);b.focus_mode=Control.FOCUS_NONE;b.pressed.connect(action);parent.add_child(b);return b
func invoke(op: String,payload: Dictionary={}) -> Dictionary:
 if runtime.bridge==null:return {"error":runtime.error}
 var request={"op":op,"payload":payload,"root":ProjectSettings.globalize_path("res://legacy_rules")}
 if op=="sim_boot":request["source"]=simulation_source()
 var parsed=JSON.parse_string(runtime.bridge.run_json(JSON.stringify(request)))
 return parsed if parsed is Dictionary else {"error":"关卡逻辑返回了无效结果"}
func start_game(map_id: String,equipment: Dictionary) -> bool:
 impact_pause=0;last_skill_impact=0
 victory_confirmed=false;victory_time=0.0;defeat_time=0.0;surface.defeated=false
 outfit=equipment.duplicate(true);surface.outfit=outfit
 var records={}
 if FileAccess.file_exists(RECORDS):
  var parser=JSON.new()
  if parser.parse(FileAccess.get_file_as_string(RECORDS))==OK and parser.data is Dictionary:records=parser.data
 state=invoke("sim_boot",{"op":"boot","map":map_id,"weapon":outfit.weapon,"assets":assets,"records":records})
 if state.has("error"):message.text=state.error;return false
 for child in background.get_children():background.remove_child(child);child.queue_free()
 var background_canvas=Canvas.new();background_canvas.font=theme.default_font;background_canvas.commands=state.background.commands;background_canvas.textures=surface.textures.duplicate();background.add_child(background_canvas)
 if map_id=="catacombs":background_canvas.prepare_depth()
 background.render_target_update_mode=SubViewport.UPDATE_ONCE;surface.textures[state.background.id]=background.get_texture()
 active=true;frozen=false;pending_actions=[];pending_pointer=[];frame_budget=0;last_records=JSON.stringify(records);show();refresh_state();return true
func command(op: String):
 if not active:return
 if state.get("mode","")=="won" and not victory_confirmed and op in ["retry","continue"]:
  start_game(state.mapId,outfit);return
 if op in ["retry","continue"]:victory_confirmed=false;victory_time=0.0;defeat_time=0.0;impact_pause=0;last_skill_impact=0
 state=invoke("sim_step",{"op":op});refresh_state()
func finish():
 active=false;invoke("sim_close");hide();returned.emit()
func wardrobe_closed(equipment: Dictionary):
 outfit=equipment.duplicate(true);surface.outfit=outfit;frozen=false;pending_actions=[];pending_pointer=[]
 if active:state=invoke("sim_step",{"op":"state","weapon":outfit.weapon});refresh_state()
func _input(event):
 if not active or frozen:return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_F and state.get("mode","")=="won":confirm_victory();get_viewport().set_input_as_handled();return
  if event.keycode==KEY_R:command("retry");get_viewport().set_input_as_handled();return
  var names={KEY_E:"e",KEY_K:"k",KEY_SPACE:"e",KEY_SHIFT:" ",KEY_R:"r",KEY_M:"m",KEY_P:"p"}
  if event.keycode==KEY_ESCAPE:command("pause");get_viewport().set_input_as_handled();return
  if names.has(event.keycode):pending_actions.append(names[event.keycode]);get_viewport().set_input_as_handled()
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and Rect2(surface.position,surface.size).has_point(event.position):
  pending_pointer=[event.position.x-surface.position.x,event.position.y-surface.position.y];get_viewport().set_input_as_handled()
func _process(delta):
 if not active or frozen:return
 if impact_pause>0:
  impact_pause=maxf(0,impact_pause-delta);return
 if state.get("mode","")=="lost":
  defeat_time+=delta;surface.defeat_time=defeat_time;refresh_state();return
 if state.get("mode","")=="won":
  if victory_confirmed:victory_time+=minf(delta,.05);refresh_state()
  return
 frame_budget+=minf(delta,.1)
 if frame_budget<1.0/60:return
 var pressed=[]
 for pair in [[KEY_W,"w"],[KEY_UP,"w"],[KEY_S,"s"],[KEY_DOWN,"s"],[KEY_A,"a"],[KEY_LEFT,"a"],[KEY_D,"d"],[KEY_RIGHT,"d"],[KEY_J,"j"]]:
  if Input.is_physical_key_pressed(pair[0]):pressed.append(pair[1])
 var tick_start=Time.get_ticks_usec()
 var steps=mini(6,int(frame_budget*60))
 for i in range(steps):
  var payload={"op":"step","dt":1.0/60,"keys":pressed,"actions":pending_actions if i==0 else [],"render":i==steps-1}
  if i==0 and not pending_pointer.is_empty():payload.pointer=pending_pointer
  state=invoke("sim_step",payload);frame_budget-=1.0/60
  var impact=int(state.get("combat",{}).get("skillImpact",0))
  if impact!=last_skill_impact:
   last_skill_impact=impact
   if impact>0:
    impact_pause=.045;frame_budget=0
    if state.commands.is_empty():state=invoke("sim_step",{"op":"state"})
    break
 pending_actions=[];pending_pointer=[];elapsed_cost=Time.get_ticks_usec()-tick_start;refresh_state()
func refresh_state():
 if state.has("error"):frozen=true;message.text="运行错误："+state.error;return
 surface.defeated=state.mode=="lost";surface.defeat_time=defeat_time
 surface.victorious=victory_confirmed and state.mode=="won";surface.victory_time=victory_time
 surface.commands=state.commands;surface.queue_redraw()
 var hero=state.heroes[state.selected]
 title.text=("经典地宫 · %d / 4 关"%(state.trial.stage+1) if state.mapId=="catacombs" else "低语森林 · 守到黎明")+"  /  新版角色"
 stats.text="模块化主角\n生命 %d / %d\n武器：%s\n击败 %d · 用时 %.1fs\n\n%s\n\nWASD / 点击地面移动\nJ 攻击 · K 技能\n空格 跳跃 · Shift 冲刺\nR 重试 · P 暂停\nM 全图\n\n保留 0.8.0 关卡布局。\n飞刀：直线弹道，墙体可阻挡。\n攻击自动朝向范围内可见敌人。"%[hero.hp,hero.maxHp,Character.NAMES[outfit.weapon],state.kills,state.time,state.challenge]
 if state.mode in ["lost","won","paused"] and not state.mapOpen and (state.mode!="won" or (victory_confirmed and victory_time>=1.5)) and (state.mode!="lost" or defeat_time>=0.65):stats.text+="\n\n"+state.title+"\n"+state.description
 stats.text=stats.text.replace("E 跳","空格 跳")
 resume_button.visible=(state.mode!="won" or not victory_confirmed or victory_time>=1.5) and state.mode in ["lost","won","paused"] and not state.mapOpen and (state.mode!="lost" or defeat_time>=0.65)
 resume_button.text="继续游玩" if state.mode=="paused" else ("重试本关" if state.mode=="lost" else "再玩一次")
 message.text=state.status.replace("Esc 返回选择","左上返回我的地图").replace("E 跳","空格 跳")
 if state.mode=="won" and not victory_confirmed:
  stats.text+="\n\n抵达终点 · 等待按下通关按钮"
  resume_button.text="按下终点按钮 / F"
  message.text="挑战已完成；点击右侧终点按钮或按 F，确认通关。"
  return
 if not persist_records:return
 var record_text=JSON.stringify(state.records)
 if record_text!=last_records:
  var file=FileAccess.open(RECORDS+".tmp",FileAccess.WRITE)
  if file:
   file.store_string(record_text);file.flush();var error=file.get_error();file.close()
   if error==OK and (not FileAccess.file_exists(RECORDS) or DirAccess.copy_absolute(RECORDS,RECORDS+".bak")==OK) and DirAccess.rename_absolute(RECORDS+".tmp",RECORDS)==OK:last_records=record_text
   else:message.text+=" · 记录保存失败，原文件保留"
  else:message.text+=" · 无法保存记录"

func _notification(what):
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and active and not frozen:
  command("pause");pending_actions=[];pending_pointer=[]

func confirm_victory():
 if not active or state.get("mode","")!="won" or victory_confirmed:return
 victory_confirmed=true;victory_time=0;refresh_state()

func simulation_source() -> String:
 var source=FileAccess.get_file_as_string("res://legacy_rules/rules.js")
 var end=source.rfind("})();")
 return source.substr(0,end)+FileAccess.get_file_as_string("res://combat_extension.js")+FileAccess.get_file_as_string("res://performance_extension.js")+FileAccess.get_file_as_string("res://appearance_extension.js")+source.substr(end)
