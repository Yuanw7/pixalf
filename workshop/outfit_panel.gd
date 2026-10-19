extends PanelContainer
const Character=preload("res://character_catalog.gd")
signal outfit_applied(outfit: Dictionary)
var draft=Character.DEFAULT.duplicate()
var action="walk"
var clock=0.0
var selectors: Dictionary={}
var feedback: Label
var preview: Control
var credits: AcceptDialog
class Preview extends Control:
 var panel
 func _draw():
  draw_rect(Rect2(Vector2.ZERO,size),Color("101912"))
  var spots=[Vector2(180,190),Vector2(495,190),Vector2(180,410),Vector2(495,410)]
  if panel.action=="hurt":spots=[Vector2(350,290)]
  for i in range(spots.size()):
   var at=spots[i]
   draw_line(at+Vector2(-100,16),at+Vector2(100,16),Color("39442e"),1)
   draw_circle(at+Vector2(0,8),22,Color(0,0,0,0.55))
   Character.draw_actor(self,panel.draft,at,panel.action,Character.DIRECTIONS[i],panel.clock,2.0)
   draw_string(get_theme_default_font(),at+Vector2(-24,51),("倒地 · 单方向素材" if panel.action=="hurt" else ["背面 / 北","左侧 / 西","正面 / 南","右侧 / 东"][i]),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("d5bb78"))
 func _process(_delta):queue_redraw()
func _ready():
 position=Vector2.ZERO;size=Vector2(1280,800);mouse_filter=Control.MOUSE_FILTER_STOP
 var style=StyleBoxFlat.new();style.bg_color=Color("18221b");style.content_margin_left=40;style.content_margin_right=40;style.content_margin_top=28;style.content_margin_bottom=28;add_theme_stylebox_override("panel",style)
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",14);add_child(box)
 var title=Label.new();title.text="角色衣柜  /  LPC 模块化装备";title.add_theme_font_size_override("font_size",26);box.add_child(title)
 var intro=Label.new();intro.text="四方向共用动作时钟 · 装备保留独立图层 · 切换后可带入所有地图";box.add_child(intro)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",28);row.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(row)
 var controls=VBoxContainer.new();controls.custom_minimum_size.x=310;controls.add_theme_constant_override("separation",9);row.add_child(controls)
 for slot in Character.SLOTS:
  var caption=Label.new();caption.text=Character.SLOTS[slot];controls.add_child(caption)
  var picker=OptionButton.new();picker.custom_minimum_size=Vector2(310,40)
  for id in Character.OPTIONS[slot]:picker.add_item(Character.NAMES[id])
  controls.add_child(picker);selectors[slot]=picker
  var selected_slot=slot
  picker.item_selected.connect(func(index):change_equipment(selected_slot,Character.OPTIONS[selected_slot][index]))
 var note=Label.new();note.text="固定底层：成人体型、长裤、靴子。\n双手战斧/长矛与盾互斥。\n当前为外观与动作版本，\n尚未接入战斗伤害或装备掉落。";controls.add_child(note)
 feedback=Label.new();feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;feedback.custom_minimum_size=Vector2(310,85);controls.add_child(feedback)
 preview=Preview.new();preview.panel=self;preview.custom_minimum_size=Vector2(740,480);preview.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(preview)
 var actions=HBoxContainer.new();box.add_child(actions)
 for pair in [["idle","待机"],["walk","行走"],["attack","武器动作"],["hurt","倒地"]]:
  var mode=pair[0];add_button(pair[1],actions,func():action=mode;clock=0)
 add_button("作者与素材许可",actions,func():credits.popup_centered())
 var footer=HBoxContainer.new();box.add_child(footer)
 add_button("保存并用于游玩",footer,apply_outfit)
 add_button("恢复默认搭配",footer,func():draft=Character.DEFAULT.duplicate();sync();clock=0;feedback.text="已恢复预览，点击保存后生效。")
 add_button("取消 / 返回",footer,func():hide())
 credits=AcceptDialog.new();credits.title="LPC 素材作者与许可";credits.size=Vector2i(870,610);add_child(credits)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(820,530);credits.add_child(scroll)
 var text=Label.new();text.text=FileAccess.get_file_as_string("res://art/lpc/CREDITS.txt");text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.custom_minimum_size.x=790;scroll.add_child(text)
 sync();hide()
func add_button(text: String,parent: Node,callback: Callable):
 var b=Button.new();b.text=text;b.custom_minimum_size.y=38;b.focus_mode=Control.FOCUS_NONE;b.pressed.connect(callback);parent.add_child(b)
func open(outfit: Dictionary):
 draft=outfit.duplicate(true);action="walk";clock=0;sync();feedback.text="先预览搭配；取消不会修改已保存角色。";show()
func sync():
 for slot in selectors:selectors[slot].select(Character.OPTIONS[slot].find(draft[slot]))
func change_equipment(slot: String,item: String):
 var result=Character.equip(draft,slot,item)
 if result.error!="":feedback.text=result.error;sync();return
 draft=result.outfit;feedback.text=result.note;clock=0;sync()
func apply_outfit():
 var error=Character.save_profile(draft)
 if error!="":feedback.text=error;return
 outfit_applied.emit(draft.duplicate(true));hide()
func _process(delta):
 if visible and not credits.visible:clock+=minf(delta,0.05)
func _input(event):
 if visible and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  if credits.visible:credits.hide()
  else:hide()
  get_viewport().set_input_as_handled()
