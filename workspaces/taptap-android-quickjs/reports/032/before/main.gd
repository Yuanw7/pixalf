extends Control

const Scenery=preload("res://room_scenery.gd")
const Decor=preload("res://decoration_catalog.gd")
var decor_box: VBoxContainer
var scenery_clock=0.0
const Challenge=preload("res://room_challenge.gd")
const StartScreen=preload("res://start_screen.gd")
var start_screen: Control
var challenge_panel: PanelContainer
var challenge_text: Label
var answer_buttons: Array=[]

const Catalog = preload("res://trap_catalog.gd")
const Traps = preload("res://trap_runtime.gd")
const Library = preload("res://map_library.gd")
var air_time = 0.0
var launch_velocity = Vector2.ZERO
var trap_picker: PanelContainer
var join_buttons: Array=[]
var failure_time=0.0
var failure_reason=""
var switch_check=preload("res://art/ui/UI_Flat_IconCheck01a.png")
var switch_normal=preload("res://art/ui/UI_Flat_Button01a_1.png")
var switch_pressed=preload("res://art/ui/UI_Flat_Button01a_3.png")
var plus_texture=preload("res://art/ui/UI_Flat_ButtonPlus01a.png")
var trap_box: VBoxContainer
const Classic=preload("res://classic_runtime.gd")
const LegacyGame=preload("res://legacy_game.gd")
var legacy_game: Control
var classic_runtime
var classic_poll=0.0
var edit_map_button: Button
var home: PanelContainer
var library_list: ItemList
var library_entries: Array = []
var publish_dialog: ConfirmationDialog
var map_title: LineEdit
var help_dialog: AcceptDialog
var editor_nodes: Array = []
var play_hud: HBoxContainer
var draft_backup: Dictionary = {}
var formal_run = false
var published_path = ""
const Character=preload("res://character_catalog.gd")
const OutfitPanel=preload("res://outfit_panel.gd")
var outfit=Character.DEFAULT.duplicate()
var outfit_panel: PanelContainer
var actor_direction="south"
const Combat=preload("res://combat_visual.gd")
var victory_time=0.0
var attack_cool=0.0
var attack_left=0.0
var jump_cool=0.0
var skill_cool=0.0
var manual_jump=false
var combat_fx: Array=[]
var combat_shots: Array=[]
var actor_time=0.0
var actor_action="idle"
const CELL = 32
const Model = preload("res://map_model.gd")
const VIEW_SIZE = Vector2(704, 512)
const ORIGIN = Vector2(244, 150)
const GOLD = Color("d5bb78")
const MUTED = Color("999d8b")
const TOOLS = ["选择", "地板", "墙壁", "出生点", "隔板门", "开关", "橡皮"]
const VisualRooms=preload("res://visual_rooms.gd")
var add_side=-1
var add_source=""
var shape_description: Label
var dragging_room=false
var drag_start=Vector2.ZERO
var drag_transform: Dictionary={}
var drag_result: Dictionary={}
var drag_moved=false
var overview_selected=false
var overview = false
var preview_level: Dictionary = {}
var preview_error = ""
var join_target = ""
var join_side = 0
var join_offset = 0
var shape_dialog: ConfirmationDialog
var size_width: SpinBox
var size_height: SpinBox
var shape_picker: OptionButton
var rotation_picker: OptionButton
var dimensions_label: Label
var retry_position = Vector2.ZERO
var visited: Array = []
var level: Dictionary
var room_index = 0
var tool = "选择"
var selection = ""
var selections: Array=[]
var additive_selection=false
var room_template_confirm: ConfirmationDialog
var pending_room_template=""
var undo_stack: Array = []
var redo_stack: Array = []
var painting = false
var stroke_cells: Dictionary = {}
var playing = false
var won = false
var alive = true
var runtime: Array = []
var player = Vector2.ZERO
var cooldown = 0.0
var current_path = "user://rooms-v2.json"
var notice = "选择工具，在网格中布置房间。右键擦除，⌘Z 撤销。"
var sidebar: VBoxContainer
var inspector: VBoxContainer
var room_picker: OptionButton
var status: Label
var mode_label: Label
var file_dialog: FileDialog
var confirm: ConfirmationDialog
var pending_load = ""
const Dungeon=preload("res://dungeon_art.gd")
var tiles = preload("res://art/tiles.png")
var spike_tex = preload("res://art/spike.png")
var bomb_tex = preload("res://art/bomb.png")
var hero_tex = preload("res://art/hero.png")
var flame_tex = preload("res://art/traps/Fire.png")
var trap_textures: Dictionary = {}

func _ready():
 Dungeon.warmup()
 for kind in Catalog.KINDS:trap_textures[kind]=load(Catalog.SHEETS[kind][0])
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 var font = SystemFont.new()
 font.font_names = PackedStringArray(["PingFang SC", "Heiti SC", "Noto Sans CJK SC"])
 theme = Theme.new()
 theme.default_font = font
 theme.default_font_size = 16
 level = default_level()
 build_ui()
 editor_nodes=get_children().filter(func(n):return n is Control)
 build_library_ui()
 build_legacy_game()
 build_outfit_ui()
 outfit_panel.visibility_changed.connect(func():
  if not outfit_panel.visible and legacy_game.active:legacy_game.wardrobe_closed(outfit))
 build_start_screen()
 build_challenge_hud()
 room_template_confirm=ConfirmationDialog.new();room_template_confirm.title="应用机关房间模板";room_template_confirm.dialog_text="将清理本房间内部墙体和普通对象，保留配对门和开关。可用撤销恢复；取消不改地图。";add_child(room_template_confirm)
 room_template_confirm.confirmed.connect(func():apply_room_template(pending_room_template))
 build_friendly_tools()
 classic_runtime=Classic.new()
 refresh()
 if OS.get_cmdline_user_args().is_empty():show_start()
 if "--test-031" in OS.get_cmdline_user_args():call_deferred("test_rooms031")
 if "--capture-031" in OS.get_cmdline_user_args():
  level=Library.spatial_challenges();room_index=0;resume_editor();refresh()
  if "--math" in OS.get_cmdline_user_args():room_index=1;refresh()
  if "--play" in OS.get_cmdline_user_args():
   toggle_play()
   if "--math" in OS.get_cmdline_user_args():
    room_index=1;player=Challenge.Spatial.board(room()).get_center();retry_position=cell_center(room().spawn)
    for i in range(18):tick(.05,Vector2.ZERO)
  if "--multi" in OS.get_cmdline_user_args():
   level=Library.showcase();room_index=0;selection="sequence_0";selections=["sequence_0","sequence_1","sequence_2","sequence_3"];refresh()
  refresh();update_challenge_hud();call_deferred("capture031")
 if "--self-test" in OS.get_cmdline_user_args():
  call_deferred("self_test")
 if "--classic" in OS.get_cmdline_user_args():
  show_home();library_list.select(library_entries.size()-2);call_deferred("open_library_map",true)
 if "--capture-combat" in OS.get_cmdline_user_args():
  var review=load("res://tests027.gd").new();add_child(review);review.call_deferred("capture_review",self)
 if "--capture-outfit" in OS.get_cmdline_user_args():
  show_home();outfit_panel.open(outfit)
  if "--outfit-axe" in OS.get_cmdline_user_args():outfit_panel.change_equipment("weapon","axe");outfit_panel.change_equipment("chest","leather");outfit_panel.change_equipment("helmet","barbuta")
  if "--outfit-spear" in OS.get_cmdline_user_args():outfit_panel.change_equipment("weapon","spear")
  if "--weapon-action" in OS.get_cmdline_user_args():outfit_panel.action="attack";outfit_panel.clock=0.28
  call_deferred("capture")
 if "--capture-shape" in OS.get_cmdline_user_args():
  room_index=1;refresh();show_shape();call_deferred("capture")
 if "--capture-room" in OS.get_cmdline_user_args():
  room_index=2;refresh();call_deferred("capture")
 if "--capture-challenge-editor" in OS.get_cmdline_user_args():
  level=Library.challenges();room_index=0;resume_editor();call_deferred("capture")
 if "--capture-math" in OS.get_cmdline_user_args():
  level=Library.challenges();level.rooms[0].challenge={"type":"数字快答"};room_index=0;resume_editor();toggle_play();call_deferred("capture")
 if "--capture-failure" in OS.get_cmdline_user_args():
  resume_editor();toggle_play();die("被机关击中");tick(0.4,Vector2.ZERO);call_deferred("capture")
 if "--capture-scenery" in OS.get_cmdline_user_args():
  level=Library.scenery_showcase();room_index=0;resume_editor();decor_box.show();call_deferred("capture")
 if "--capture-start" in OS.get_cmdline_user_args():
  show_start();call_deferred("capture")
 if "--capture-home" in OS.get_cmdline_user_args():
  show_home();call_deferred("capture")
 if "--capture-traps" in OS.get_cmdline_user_args():
  level=Library.showcase();room_index=0;selection="sequence_1";refresh();trap_picker.open("地刺");call_deferred("capture")
 if "--capture-add" in OS.get_cmdline_user_args():
  overview=true;refresh();show_add_adjacent(3);call_deferred("capture")
 if "--capture-map" in OS.get_cmdline_user_args():
  overview=true;refresh();call_deferred("capture")
 if "--capture-play" in OS.get_cmdline_user_args():
  toggle_play()
  call_deferred("capture")
 if "--capture" in OS.get_cmdline_user_args():
  call_deferred("capture")

func default_level() -> Dictionary:
 return Model.four_rooms()

func label_at(text_value: String, pos: Vector2, font_size: int, color: Color = GOLD) -> Label:
 var l = Label.new()
 l.text=text_value; l.position=pos; l.add_theme_font_size_override("font_size",font_size)
 l.add_theme_color_override("font_color",color);add_child(l);return l

func button(text_value: String, parent: Node, action: Callable) -> Button:
 var b=Button.new();b.text=text_value;b.custom_minimum_size=Vector2(0,36)
 b.focus_mode=Control.FOCUS_NONE
 b.pressed.connect(action);parent.add_child(b);return b

func build_ui():
 label_at("THORNBOUND",Vector2(28,20),26)
 label_at("房间工坊  /  LOCAL WORKSHOP",Vector2(28,58),14,MUTED)
 mode_label=label_at("编辑模式",Vector2(246,101),18)
 var top=HBoxContainer.new();top.position=Vector2(480,24);top.size=Vector2(770,42);add_child(top)
 button("保存草稿",top,func(): save_level(current_path))
 button("另存为…",top,func(): show_file(true))
 button("载入…",top,func(): show_file(false))
 button("撤销",top,undo)
 button("重做",top,redo)
 button("搭建房屋 / M",top,toggle_overview)
 button("▶ 从第1关试玩",top,toggle_play)
 var nav=HBoxContainer.new();nav.position=Vector2(480,69);add_child(nav)
 button("主界面",nav,show_start).icon=load("res://art/icons/fa16.png")
 button("加入游玩列表",nav,show_publish).icon=load("res://art/icons/fa10.png")
 button("角色衣柜",nav,func():outfit_panel.open(outfit))
 button("操作指南",nav,func():help_dialog.popup_centered()).icon=load("res://art/icons/fa13.png")
 var left_scroll=ScrollContainer.new();left_scroll.position=Vector2(28,102);left_scroll.size=Vector2(200,620);left_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(left_scroll)
 sidebar=VBoxContainer.new();sidebar.custom_minimum_size.x=180;left_scroll.add_child(sidebar)
 room_picker=OptionButton.new();room_picker.custom_minimum_size.y=40;sidebar.add_child(room_picker)
 room_picker.item_selected.connect(func(i):
  if not playing: room_index=i;selection="";preview_level={};join_target="";refresh())
 for t in TOOLS:
  var name_copy=t
  button(t,sidebar,func():
   if not playing: tool=name_copy;selection="";refresh())
 button("机关素材库 · 12种",sidebar,func():
  if not playing:trap_picker.open(tool)).icon=load("res://art/ui/UI_Flat_IconDropdown01a.png")
 trap_box=VBoxContainer.new();sidebar.add_child(trap_box)
 trap_box.visible=false
 button("场景装饰 ▾ / 收起",sidebar,func():decor_box.visible=not decor_box.visible)
 decor_box=VBoxContainer.new();sidebar.add_child(decor_box)
 for kind in Decor.KINDS:
  var decor_kind=kind
  var b=button(kind,decor_box,func():
   if not playing:tool=decor_kind;selection="";hint("点击空地摆放"+decor_kind+"，右键删除；装饰不阻挡通行。");refresh())
  b.icon=Decor.icon(kind);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",28)
 decor_box.hide()
 button("＋ 添加相邻房屋",sidebar,func():
  overview=true;preview_level={};refresh();hint("点击选中房间边缘的 ＋，选择大小与房型。"))
 button("新建独立房间",sidebar,add_room)
 button("尺寸 / 房型…",sidebar,show_shape)
 button("重试当前房间 R",sidebar,retry)
 var scroll=ScrollContainer.new();scroll.position=Vector2(975,100);scroll.size=Vector2(290,613)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;add_child(scroll)
 inspector=VBoxContainer.new();inspector.custom_minimum_size.x=270;scroll.add_child(inspector)
 status=label_at("",Vector2(28,737),15,MUTED)
 status.size=Vector2(1210,50);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 dimensions_label=label_at("",Vector2(244,679),14,MUTED)
 label_at("WASD 移动  空格 跳跃  J 攻击  K 技能  F 开关  R 重试",Vector2(244,706),14,MUTED)
 file_dialog=FileDialog.new();file_dialog.access=FileDialog.ACCESS_FILESYSTEM
 file_dialog.filters=PackedStringArray(["*.json ; 房间布局"]);file_dialog.size=Vector2i(850,570)
 file_dialog.file_selected.connect(func(path):
  if file_dialog.file_mode==FileDialog.FILE_MODE_SAVE_FILE:save_level(path)
  else:
   pending_load=path;confirm.dialog_text="载入布局会替换当前编辑内容。当前布局可用撤销恢复。";confirm.popup_centered())
 add_child(file_dialog)
 confirm=ConfirmationDialog.new();confirm.title="载入房间布局"
 confirm.confirmed.connect(func():load_level(pending_load));add_child(confirm)
 build_shape_dialog()

func room() -> Dictionary: return level.rooms[room_index]
func cell_center(cell: Array) -> Vector2: return Vector2(cell[0],cell[1])*CELL+Vector2.ONE*CELL/2
func object_at(cell: Vector2i) -> Dictionary:
 return Model.object_at(room(),cell)

func selected_objects() -> Array:
 return room().objects.filter(func(o):return selections.has(o.id) or (selections.is_empty() and o.id==selection))
func select_object(id: String,append: bool=false):
 if not append:selections.clear()
 if id!="":
  if append and selections.has(id):selections.erase(id)
  else:selections.append(id)
 selection=selections.back() if not selections.is_empty() else ""
 refresh()
func select_same_kind():
 var o=selected()
 if o.is_empty() or not Catalog.known(o.kind):return
 selections=room().objects.filter(func(item):return item.kind==o.kind).map(func(item):return item.id)
 refresh()
func batch_timing(changes: Dictionary) -> bool:
 var targets=selected_objects().filter(func(o):return Catalog.known(o.kind))
 if playing or targets.is_empty():return false
 var copies=[]
 for o in targets:
  var next=o.duplicate(true)
  for key in changes:
   if not key in ["delay","period","active"]:return false
   next[key]=changes[key]
  if changes.has("period"):next.active=minf(float(Catalog.settings(next).active),float(next.period))
  var issue=Catalog.validate(next)
  if issue!="":hint("未应用："+issue);return false
  copies.append(next)
 snapshot()
 for i in range(targets.size()):targets[i].merge(copies[i],true)
 hint("已统一修改 %d 个机关；未选择的机关保持原值。"%targets.size());refresh();return true
func batch_inspector():
 var targets=selected_objects().filter(func(o):return Catalog.known(o.kind))
 inspector_label("已多选 %d 个机关 · 统一时间"%targets.size())
 inspector_label("只应用填写的字段；留空表示保留各自原值。延迟统一后同步启动，需错峰时仅调整周期。")
 var edits={}
 for field in [["delay","启动延迟 / 秒"],["period","重复周期 / 秒"],["active","生效时间 / 秒"]]:
  var row=LineEdit.new();row.placeholder_text=field[1];row.virtual_keyboard_type=LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL;inspector.add_child(row);edits[field[0]]=row
 button("应用到所选机关（一次撤销）",inspector,func():
  var values={}
  for key in edits:
   var value=edits[key].text.strip_edges()
   if value=="":continue
   if not value.is_valid_float():hint("时间请输入数字");return
   values[key]=float(value)
  if not values.is_empty():batch_timing(values))
 button("取消多选",inspector,func():select_object(""))
func apply_room_template(type: String) -> bool:
 if playing:return false
 var result=Challenge.Spatial.apply(room(),type)
 if result.error!="":hint(result.error);return false
 snapshot();level.rooms[room_index]=result.room;selection="";selections.clear()
 hint("已应用机关房间模板 · "+type+" · 可撤销");refresh();return true
func selected() -> Dictionary:
 for o in room().objects:
  if o.id==selection:return o
 return {}
func hint(text_value: String):
 notice=text_value
 if is_instance_valid(status):status.text=notice
func snapshot():
 undo_stack.append(level.duplicate(true));if undo_stack.size()>80:undo_stack.pop_front()
 redo_stack.clear()
func undo():
 if playing or undo_stack.is_empty():return
 redo_stack.append(level.duplicate(true));level=undo_stack.pop_back();room_index=mini(room_index,level.rooms.size()-1);selection="";preview_level={};hint("已撤销上一步编辑。");refresh()
func redo():
 if playing or redo_stack.is_empty():return
 undo_stack.append(level.duplicate(true));level=redo_stack.pop_back();room_index=mini(room_index,level.rooms.size()-1);selection="";preview_level={};hint("已重做上一步编辑。");refresh()
func add_room():
 if playing:return
 if level.rooms.size()>=32:hint("最多32个房间。");return
 snapshot()
 var r=Model.make_room("room_%d"%Time.get_ticks_usec(),"新房间 %d"%(level.rooms.size()+1),18,14,"矩形")
 var right=0
 for existing in level.rooms:right=maxi(right,existing.position[0]+existing.width)
 r.position=[right+4,0];level.rooms.append(r);room_index=level.rooms.size()-1;selection="";preview_level={};overview=false;refresh()
 show_shape()

func delete_room():
 if playing:return
 if level.rooms.size()==1:hint("至少保留一个房间。");return
 for r in level.rooms:
  if r.id==room().id:continue
  for o in r.objects:
   if o.kind=="隔板门" and o.target==room().id:hint("有门通往此房间，请先修改关联。");return
 snapshot();level.rooms.remove_at(room_index);room_index=0;selection="";refresh()

func inspector_label(text_value: String):
 var l=Label.new();l.text=text_value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.custom_minimum_size.x=260;inspector.add_child(l)
func refresh():
 if selection=="" or (not selections.is_empty() and not selections.has(selection)):selections.clear()
 selections=selections.filter(func(id):return room().objects.any(func(o):return o.id==id))
 room_picker.clear()
 for r in level.rooms:room_picker.add_item(r.name)
 room_picker.select(room_index);room_picker.disabled=playing
 mode_label.text=(("游玩 · " if formal_run else "试玩 · ")+room().name) if playing else ("拼接总览" if overview else "编辑 · "+tool)
 dimensions_label.text="%d × %d 格 · %s · 朝向 %d° · 地图坐标 (%d, %d)"%[room().width,room().height,room().shape,int(room().rotation)*90,room().position[0],room().position[1]]
 if playing:dimensions_label.text+=" · 已到达 %d/%d"%[visited.size(),level.rooms.size()]
 status.text=notice
 for n in inspector.get_children():inspector.remove_child(n);n.queue_free()
 inspector_label("房间属性")
 var name_edit=LineEdit.new();name_edit.text=room().name;name_edit.editable=not playing;inspector.add_child(name_edit)
 name_edit.text_submitted.connect(func(v):
  if not playing:snapshot();room().name=v.left(40);refresh())
 if playing:
  inspector_label("\nF / 点击门边按钮完成本关。最终按钮立即胜利；其他门打开后穿门。\nR 从本次入口重试。\nM 查看地图（暂停机关）。\nEsc 返回编辑。\n\n未进入的房间保持待机。\n已通过的入口可原路返回。")
  button("返回编辑",inspector,toggle_play)
 else:
  challenge_inspector()
  if overview:
   inspector_label("点击房间选中，双击进入内部编辑。\n点击边缘 ＋ 添加相邻房间。\n拖动房间：金色吸附连接，红色重叠拒绝。\n已连接房间整组移动；单独重排前先解除拼接。\nEsc 取消拖动；⌘Z 撤销。")
   button("进入选中房间",inspector,func():overview=false;refresh())
  var o=selected()
  if selected_objects().size()>1:
   batch_inspector()
  elif not o.is_empty():
   inspector_label("\n"+o.kind+" · (%d, %d)"%[o.x,o.y])
   if o.kind=="隔板门":
    var target=Model.by_id(level,o.target)
    inspector_label("朝向："+Model.SIDES[o.side]+"\n通往："+("终点" if o.target=="finish" else target.get("name","无效房间")))
    if o.get("legacy",false):inspector_label("旧版传送连接；请解除后重新拼接。")
    elif o.get("entry",false):inspector_label("配对入口 · 随对侧开门\n通过后可原路返回")
   elif o.kind=="开关":
    inspector_label("控制隔板门")
    var picker=OptionButton.new();var ids=[""];picker.add_item("未关联")
    for d in room().objects:
     if d.kind=="隔板门" and not d.get("entry",false):picker.add_item("门 (%d, %d)"%[d.x,d.y]);ids.append(d.id)
    picker.select(maxi(0,ids.find(o.link)));inspector.add_child(picker)
    picker.item_selected.connect(func(i):snapshot();o.link=ids[i];refresh())
   if Catalog.known(o.kind):
    trap_inspector(o);button("选择本房间同类机关",inspector,select_same_kind)
   if Decor.known(o.kind):inspector_label("场景装饰 · 不阻挡通行\n按脚下位置前后遮挡，右键可删除。")
   button("删除对象 / 解除配对门",inspector,func():snapshot();erase_at(Vector2i(o.x,o.y));selection="";refresh())
  inspector_label("\n拼接下一房间")
  var targets=OptionButton.new();var ids=[]
  for r in level.rooms:
   if r.id!=room().id:targets.add_item(r.name);ids.append(r.id)
  if not ids.has(join_target):join_target=ids[0] if not ids.is_empty() else ""
  if not ids.is_empty():targets.select(ids.find(join_target))
  inspector.add_child(targets);targets.item_selected.connect(func(i):join_target=ids[i];preview_level={};queue_redraw())
  var directions=OptionButton.new()
  for value in Model.SIDES:directions.add_item("拼在"+value+"侧")
  directions.select(join_side);inspector.add_child(directions)
  directions.item_selected.connect(func(i):join_side=i;preview_level={};queue_redraw())
  inspector_label("侧向偏移（格）：右/左 +向下；上/下 +向右")
  var offset=SpinBox.new();offset.min_value=-30;offset.max_value=30;offset.step=1;offset.value=join_offset;inspector.add_child(offset)
  offset.value_changed.connect(func(v):join_offset=int(v);preview_level={};queue_redraw())
  var row=HBoxContainer.new();inspector.add_child(row)
  button("预览拼接",row,preview_join);button("应用拼接",row,apply_join)
  button("取消预览",inspector,func():preview_level={};hint("已取消预览，地图未改动。");queue_redraw())
  button("解除本房间拼接",inspector,disconnect_room)
  button("删除此房间",inspector,delete_room)
  inspector_label("\n空白形状区域不可放置对象。\n手动隔板门默认是终点；\n房间间的门由拼接自动生成。\n改名按 Enter；右键擦除。")
 queue_redraw()

func erase_at(c: Vector2i):
 var old=object_at(c)
 if not old.is_empty():
  if old.kind=="隔板门":Model.remove_door(level,room().id,old.id)
  else:room().objects.erase(old)
 elif Model.inside(room(),c) and not Model.boundary(room(),c):room().walls.erase([c.x,c.y])
 preview_level={}

func paint(c: Vector2i, erase: bool):
 if playing or overview or not Model.inside(room(),c):return
 if stroke_cells.has(c):return
 stroke_cells[c]=true
 if tool=="选择" and not erase:
  select_object(object_at(c).get("id",""),additive_selection);return
 if not painting:snapshot();painting=true
 if erase or tool=="橡皮":erase_at(c);refresh();return
 if Decor.known(tool) and room().walls.has([c.x,c.y]):hint("装饰放在空地上，不能覆盖墙体。");return
 var edge=Model.boundary(room(),c)
 if tool=="隔板门":
  if Model.door_side(room(),c)<0:hint("门需放在平直外墙，避开拐角。");return
 elif edge:hint("外墙保持封闭；只有隔板门可放在外墙。");return
 if tool=="出生点":
  if object_at(c).is_empty():room().spawn=[c.x,c.y];room().walls.erase([c.x,c.y])
 elif tool=="墙壁":
  if room().spawn==[c.x,c.y]:hint("请先移动出生点。");return
  erase_at(c)
  if not room().walls.has([c.x,c.y]):room().walls.append([c.x,c.y])
 elif tool=="地板":erase_at(c);room().walls.erase([c.x,c.y])
 else:
  if room().spawn==[c.x,c.y]:hint("出生点不能放机关。");return
  if not object_at(c).is_empty():hint("此格已有对象，请先擦除。");return
  if tool!="隔板门":room().walls.erase([c.x,c.y])
  var o={"id":"obj_%d"%Time.get_ticks_usec(),"kind":tool,"x":c.x,"y":c.y}
  if tool=="隔板门":o.target="finish";o.side=Model.door_side(room(),c);o.pair="";o.entry=false
  if tool=="开关":
   o.link=""
   for d in room().objects:
    if d.kind=="隔板门" and not d.get("entry",false):o.link=d.id;break
  if Catalog.known(tool):o=Catalog.create(tool,c.x,c.y,o.id)
  room().objects.append(o);selection=o.id
 refresh()

func _input(event):
 if trap_picker!=null and trap_picker.visible:
  if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:trap_picker.hide();get_viewport().set_input_as_handled()
  return
 if start_screen!=null and start_screen.visible:return
 if legacy_game!=null and legacy_game.active:return
 if classic_runtime!=null and classic_runtime.active:return
 if dragging_room:
  if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
   cancel_room_drag();get_viewport().set_input_as_handled();return
  if event is InputEventMouseMotion:
   update_room_drag(event.position);return
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
   finish_room_drag(event.position);return
 if room_template_confirm.visible or outfit_panel.visible or home.visible or publish_dialog.visible or help_dialog.visible or file_dialog.visible or confirm.visible or shape_dialog.visible:return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:
   if playing:
    if formal_run:show_home()
    else:toggle_play()
   else:preview_level={};overview=false;refresh()
  if get_viewport().gui_get_focus_owner() is LineEdit:return
  if event.keycode==KEY_A and (event.meta_pressed or event.ctrl_pressed) and not playing:
   selections=room().objects.filter(func(o):return Catalog.known(o.kind)).map(func(o):return o.id);selection=selections.back() if not selections.is_empty() else "";refresh();get_viewport().set_input_as_handled();return
  if event.keycode==KEY_M:toggle_overview()
  if playing and not overview and event.keycode in [KEY_1,KEY_2,KEY_3]:answer_challenge(event.keycode-KEY_1)
  if event.keycode==KEY_F and playing and not overview:activate_switch()
  if event.keycode in [KEY_SPACE,KEY_E] and playing and not overview:workshop_jump();get_viewport().set_input_as_handled()
  if event.keycode==KEY_K and playing and not overview:workshop_skill();get_viewport().set_input_as_handled()
  if event.keycode==KEY_R and playing:retry()
  if event.keycode==KEY_Z and (event.meta_pressed or event.ctrl_pressed):
   if event.shift_pressed:redo()
   else:undo()
 if event is InputEventMouseButton and (event.button_index==MOUSE_BUTTON_LEFT or event.button_index==MOUSE_BUTTON_RIGHT):
  if not event.pressed:painting=false;stroke_cells.clear()
  elif Rect2(ORIGIN,VIEW_SIZE).has_point(event.position):
   if overview:
    if not playing and preview_level.is_empty() and event.button_index==MOUSE_BUTTON_LEFT:
     var side=plus_at(event.position)
     if side>=0:return
     else:
      select_overview(event.position)
      if overview_selected:
       if event.double_click:overview=false;refresh()
       else:begin_room_drag(event.position)
   elif playing and event.button_index==MOUSE_BUTTON_LEFT:
    var clicked=object_at(screen_cell(event.position))
    if clicked.get("kind","")=="开关":activate_switch(clicked.id)
   else:
    additive_selection=event.shift_pressed;paint(screen_cell(event.position),event.button_index==MOUSE_BUTTON_RIGHT)
 if event is InputEventMouseMotion and not additive_selection and tool!="选择" and event.button_mask!=0 and not overview and Rect2(ORIGIN,VIEW_SIZE).has_point(event.position):
  paint(screen_cell(event.position),bool(event.button_mask&MOUSE_BUTTON_MASK_RIGHT))

func state_for(r: Dictionary) -> Dictionary:
 var state={"cleared":false,"challenge":Challenge.fresh(r),"time":0.0,"doors":{},"bombs":{},"mechanisms":{},"projectiles":[]}
 for o in r.objects:
  if o.kind=="隔板门":state.doors[o.id]=0.0
  if o.kind=="炸弹":state.bombs[o.id]=-1.0
  if Catalog.known(o.kind):state.mechanisms[o.id]={"cycle":-1,"armed":-1.0,"cooldown":0.0}
 return state
func toggle_play():
 if trap_picker!=null:trap_picker.hide()
 failure_time=0.0;victory_time=0.0;attack_cool=0;attack_left=0;combat_fx=[];combat_shots=[];jump_cool=0;skill_cool=0;manual_jump=false
 actor_time=0;actor_action="idle";actor_direction="south"
 air_time=0;launch_velocity=Vector2.ZERO
 if playing:
  playing=false;won=false;preview_level={};hint("已返回编辑，试玩没有更改布局。");refresh();return
 var issue=validate(level, true)
 if issue!="":hint("无法试玩："+issue);return
 runtime.clear()
 for r in level.rooms:runtime.append(state_for(r))
 room_index=0;visited=[room().id];overview=false;preview_level={}
 playing=true;won=false;alive=true;player=cell_center(room().spawn);retry_position=player;cooldown=0
 hint("从第1关开始。F 按附近开关，开门后穿入拼接房间。");refresh()

func retry():
 failure_time=0.0;victory_time=0.0;attack_cool=0;attack_left=0;combat_fx=[];combat_shots=[];jump_cool=0;skill_cool=0;manual_jump=false
 actor_time=0;actor_action="idle";actor_direction="south"
 air_time=0;launch_velocity=Vector2.ZERO
 if not playing:return
 runtime[room_index]=state_for(room());player=retry_position;alive=true;won=false;cooldown=0
 overview=false
 for o in room().objects:
  if o.kind=="隔板门" and o.get("entry",false) and visited.has(o.target):runtime[room_index].doors[o.id]=1.0
 hint("本房间已重置。");refresh()
func activate_switch(target_id: String=""):
 if not playing or not alive or won:return
 if Challenge.config(room()).type!="普通房间" and not runtime[room_index].challenge.done:
  hint("先完成房间挑战，再按开关开门。");return
 for o in room().objects:
  if o.kind=="开关" and (target_id=="" or o.id==target_id) and player.distance_to(cell_center([o.x,o.y]))<54:
   if runtime[room_index].doors.has(o.link):
    if runtime[room_index].doors[o.link]==0:
     runtime[room_index].doors[o.link]=0.001
     var gate=Model.door_by_id(room(),o.link)
     if not gate.get("entry",false):runtime[room_index].cleared=true
     if gate.get("target","")=="finish":
      won=true;victory_time=0;combat_fx=[];combat_shots=[];hint("已按下终点按钮 · 地图通关！R 重试 / Esc 返回")
     else:hint("已按按钮完成本关，隔板打开后可进入下一房间。")
   return
func can_move(pos: Vector2) -> bool:
 for corner in [Vector2(-9,-9),Vector2(9,-9),Vector2(-9,9),Vector2(9,9)]:
  if not Model.inside(room(),Vector2i(((pos+corner)/CELL).floor())):return false
 var state=runtime[room_index]
 for c in room().walls:
  var gate=object_at(Vector2i(c[0],c[1]))
  if gate.get("kind")=="隔板门" and state.doors[gate.id]>=1:continue
  if Rect2(Vector2(c[0],c[1])*CELL-Vector2(9,9),Vector2(CELL+18,CELL+18)).has_point(pos):return false
 return true

func cross_door() -> bool:
 for o in room().objects:
  if o.kind!="隔板门" or runtime[room_index].doors[o.id]<1:continue
  var p=cell_center([o.x,o.y]);var outward=Vector2(Model.DIRS[o.side]);var relative=player-p
  if absf(relative.dot(Vector2(-outward.y,outward.x)))>CELL/2-9:continue
  if relative.dot(outward)<-9:continue
  if o.target=="finish":return false
  for i in range(level.rooms.size()):
   if level.rooms[i].id!=o.target:continue
   var previous=room_index;room_index=i
   var paired=Model.door_by_id(room(),o.get("pair",""))
   if paired.is_empty():player=cell_center(room().spawn)
   else:
    player=cell_center([paired.x,paired.y])-Vector2(Model.DIRS[paired.side])*CELL
    runtime[room_index].doors[paired.id]=1.0
   air_time=0;launch_velocity=Vector2.ZERO;combat_fx=[];combat_shots=[];attack_left=0
   retry_position=player
   if not visited.has(room().id):visited.append(room().id)
   hint("已进入 "+room().name+"；入口与上一房间门洞对齐。");refresh()
   print("ROOM ",previous+1," -> ",room_index+1," position=",player)
   return true
 return false

func die(reason: String):
 if not alive:return
 alive=false;actor_time=0;failure_time=0.0;failure_reason=reason;actor_action="hurt"
 hint(reason+" · R 重试 / "+("Esc 主界面" if formal_run else "Esc 返回编辑"))
func tick(delta: float, direction: Vector2):
 if not playing:return
 if won:
  victory_time+=delta
  for id in runtime[room_index].doors:
   if runtime[room_index].doors[id]>0:runtime[room_index].doors[id]=minf(1,runtime[room_index].doors[id]+delta/.65)
  return
 if not alive:actor_action="hurt";actor_time+=delta;failure_time+=delta;return
 attack_cool=maxf(0,attack_cool-delta);attack_left=maxf(0,attack_left-delta)
 jump_cool=maxf(0,jump_cool-delta);skill_cool=maxf(0,skill_cool-delta)
 for e in combat_fx:e.age+=delta
 combat_fx=combat_fx.filter(func(e):return e.age<e.life)
 for shot in combat_shots:
  var travel=minf(shot.left,620*delta);var steps=maxi(1,int(ceil(travel/4)))
  for _i in range(steps):
   shot.x+=shot.dx*travel/steps;shot.y+=shot.dy*travel/steps;shot.left-=travel/steps
   if not can_move(Vector2(shot.x,shot.y)):
    combat_fx.append({"kind":"wall","x":shot.x,"y":shot.y-20,"age":0.0,"life":.24});shot.left=0;break
 combat_shots=combat_shots.filter(func(p):return p.left>.01)
 var next_action="attack" if attack_left>0 else ("walk" if direction.length()>0.01 or air_time>0 else "idle")
 if next_action!=actor_action:actor_time=0;actor_action=next_action
 actor_time+=delta
 if direction.length()>0.01:
  if absf(direction.x)>absf(direction.y):actor_direction="east" if direction.x>0 else "west"
  else:actor_direction="south" if direction.y>0 else "north"
 var previous_player=player
 var state=runtime[room_index];state.time+=delta
 for id in state.doors:
  if state.doors[id]>0:state.doors[id]=minf(1.0,state.doors[id]+delta/0.65)
 var movement=direction.limit_length()*160*delta
 if air_time>0:
  movement+=launch_velocity*minf(delta,air_time);air_time=maxf(0,air_time-delta)
 var steps=maxi(1,int(ceil(movement.length()/4.0)))
 for step in range(steps):
  var m=movement/steps
  if can_move(player+Vector2(m.x,0)):player.x+=m.x
  if can_move(player+Vector2(0,m.y)):player.y+=m.y
  if cross_door():return
 Challenge.update(self,delta,previous_player)
 if alive and not (Challenge.config(room()).type=="木头人" and runtime[room_index].challenge.done):Traps.update(self,delta)
func _process(delta):
 scenery_clock+=delta
 update_join_buttons()
 update_challenge_hud()
 if start_screen!=null and start_screen.visible:return
 if legacy_game!=null and legacy_game.active:return
 if classic_runtime!=null and classic_runtime.active:
  classic_poll+=delta
  if classic_poll>=0.2:
   classic_poll=0;classic_runtime.request({"op":"status"})
   if not classic_runtime.active:hint("已返回我的地图；经典地图游玩已结束。")
  return
 if playing and not overview and not home.visible and not help_dialog.visible and not outfit_panel.visible:
  var direction=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
  if get_viewport().gui_get_focus_owner() is LineEdit:direction=Vector2.ZERO
  if Input.is_physical_key_pressed(KEY_J):workshop_attack()
  tick(minf(delta,0.05),direction)
 queue_redraw()

func _draw():
 draw_rect(Rect2(Vector2.ZERO,size),Color("121914"))
 draw_rect(Rect2(ORIGIN-Vector2(3,3),VIEW_SIZE+Vector2(6,6)),Color("5b6046"),false,2)
 if home.visible or (start_screen!=null and start_screen.visible):return
 if level.is_empty():return
 if overview:
  draw_overview();return
 var zoom=view_scale()
 draw_set_transform(view_origin(),0,Vector2.ONE*zoom)
 var wall_set=Scenery.walls(room())
 var gate_cells=Scenery.door_cells(room())
 for y in range(int(room().height)):
  for x in range(int(room().width)):
   if not Model.inside(room(),Vector2i(x,y)):continue
   var rect=Rect2(Vector2(x,y)*CELL,Vector2(CELL,CELL))
   Scenery.floor_tile(self,Vector2i(x,y))
   if not playing:draw_rect(rect,Color(0.7,0.75,0.6,0.09),false)
 Scenery.shadows(self,room(),wall_set)
 for cell in wall_set:Scenery.wall(self,cell,wall_set,1.0,gate_cells)
 for o in room().objects:
  var center=cell_center([o.x,o.y]);var kind=o.kind
  if kind=="隔板门":
   var progress=float(runtime[room_index].doors[o.id]) if playing else (1.0 if o.get("entry",false) else 0.0)
   if o.side%2==0:
    draw_rect(Rect2(center+Vector2(-5,-16),Vector2(10,32*(1-progress))),Color("787e65"))
    draw_line(center+Vector2(-5,-16),center+Vector2(-5,16-32*progress),GOLD,2)
   else:
    draw_rect(Rect2(center+Vector2(-16,-5),Vector2(32*(1-progress),10)),Color("787e65"))
    draw_line(center+Vector2(-16,-5),center+Vector2(16-32*progress,-5),GOLD,2)
   draw_line(center,center+Vector2(Model.DIRS[o.side])*11,GOLD,1)
  elif kind=="开关":
   var pressed=playing and runtime[room_index].doors.get(o.link,0)>0
   draw_texture_rect(switch_pressed if pressed else switch_normal,Rect2(center-Vector2(12,12),Vector2(24,24)),false,Color("879569") if pressed else Color("687057"))
   draw_texture_rect(switch_check if pressed else plus_texture,Rect2(center-Vector2(7,7),Vector2(14,14)),false)
   if not playing and (o.id==selection or selections.has(o.id)):
    for d in room().objects:
     if d.id==o.link:draw_dashed_line(center,cell_center([d.x,d.y]),GOLD,2,6)
  elif Catalog.known(kind):draw_trap(o)
  if not playing and (o.id==selection or selections.has(o.id)):draw_rect(Rect2(center-Vector2(16,16),Vector2(32,32)),GOLD,false,2)
 if playing:
  for arrow in runtime[room_index].projectiles:
   draw_line(arrow.position-arrow.velocity.normalized()*10,arrow.position,GOLD,3)
 draw_room_challenge()
 var hero_pos=player if playing else cell_center(room().spawn)
 if air_time>0:hero_pos.y-=32*sin(PI*clampf(air_time/.55,0,1)) if manual_jump else 12
 var props=room().objects.filter(func(o):return Decor.known(o.kind))
 props.sort_custom(func(a,b):return a.y<b.y)
 for prop in props:
  if prop.y*32+25<=hero_pos.y:Decor.draw_prop(self,prop,scenery_clock)
 draw_circle(hero_pos+Vector2(0,8),11,Color(0,0,0,0.5))
 Character.draw_actor(self,outfit,hero_pos,"victory" if won else (actor_action if playing else "idle"),actor_direction if playing else "south",victory_time if won else actor_time,1.0)
 if playing:Combat.air(self,combat_fx,combat_shots)
 if won:Combat.victory(self,hero_pos,victory_time)
 for prop in props:
  if prop.y*32+25>hero_pos.y:Decor.draw_prop(self,prop,scenery_clock)
 for cell in wall_set:
  if (cell.y+1)*32>hero_pos.y:
   var near_actor=absf(cell.x*32+16-hero_pos.x)<36 and absf(cell.y*32-hero_pos.y)<42
   Scenery.wall(self,cell,wall_set,0.55 if playing and near_actor else 1.0,gate_cells)
 if not playing:
  var chosen=selected()
  if not chosen.is_empty() and Decor.known(chosen.kind):draw_rect(Rect2(Vector2(chosen.x,chosen.y)*32,Vector2(32,32)),GOLD,false,2)
 draw_set_transform(Vector2.ZERO)
 if playing and not alive:
  var pulse=maxf(0,1.0-failure_time/0.3)
  draw_rect(Rect2(ORIGIN,VIEW_SIZE),Color(0.65,0.15,0.10,pulse*0.32))
 if playing and ((won and victory_time>=1.6) or (not alive and failure_time>=0.65)):
  draw_rect(Rect2(ORIGIN,VIEW_SIZE),Color(0,0,0,minf(.6,(victory_time-1.6)*1.5) if won else minf(0.6,(failure_time-0.65)*1.8)))
  draw_string(theme.default_font,ORIGIN+Vector2(225,242),"地图通关" if won else "挑战失败",HORIZONTAL_ALIGNMENT_LEFT,-1,36,GOLD)
  draw_string(theme.default_font,ORIGIN+Vector2(203,287),("R 重试  ·  Esc 主界面" if formal_run else "R 重试  ·  Esc 返回编辑"),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)

func validate(data: Variant, playable: bool = false) -> String:
 return Model.validate(data,playable)

func valid_cell(c: Variant) -> bool:
 return Model.pair_valid(c)

func normalize_cells(data: Variant):
 Model.normalize(data)

func show_file(save: bool):
 if playing:hint("请先返回编辑再读写布局。");return
 file_dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE if save else FileDialog.FILE_MODE_OPEN_FILE
 file_dialog.current_dir=OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
 file_dialog.current_file="rooms.json";file_dialog.popup_centered()
func save_level(path: String) -> bool:
 if playing:return false
 var temp=path+".tmp";var f=FileAccess.open(temp,FileAccess.WRITE)
 if f==null:hint("保存失败：无法写入该目录。");return false
 f.store_string(JSON.stringify(level,"  "));f.flush();var error=f.get_error();f.close()
 if error!=OK:hint("写入失败，原文件未更改。");return false
 if FileAccess.file_exists(path):
  if DirAccess.copy_absolute(path,path+".bak")!=OK:hint("备份失败，原文件未更改。");return false
 if DirAccess.rename_absolute(temp,path)!=OK:hint("替换文件失败，原文件与临时文件已保留。");return false
 current_path=path;hint("已保存："+ProjectSettings.globalize_path(path));return true
func load_level(path: String) -> bool:
 if playing:return false
 var f=FileAccess.open(path,FileAccess.READ)
 if f==null:hint("无法打开文件。");return false
 if f.get_length()>2*1024*1024:hint("文件过大，未载入。");return false
 var parsed=Model.migrate(JSON.parse_string(f.get_as_text()));f.close()
 normalize_cells(parsed)
 var issue=validate(parsed)
 if issue!="":hint("未载入："+issue+"；当前布局已保留。");return false
 snapshot();level=parsed;published_path="";room_index=0;selection="";preview_level={}
 current_path="user://rooms-v2.json" if path.begins_with("res://") or path.begins_with(ProjectSettings.globalize_path("res://")) else path
 hint("已载入："+path);refresh();return true

func capture():
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var path="user://024-start.png" if start_screen.visible else "user://022-native.png" if legacy_game.active and not outfit_panel.visible else ("user://019-outfit.png" if outfit_panel.visible else ("user://019-home.png" if home.visible else ("user://018-traps.png" if "--capture-traps" in OS.get_cmdline_user_args() else "user://workshop.png")))
 get_viewport().get_texture().get_image().save_png(path)
 print("CAPTURE "+ProjectSettings.globalize_path(path))

func self_test():
 var suite=load("res://tests.gd").new()
 add_child(suite)
 await suite.run(self)

func view_scale() -> float:
 return minf(1.5,minf(VIEW_SIZE.x/(room().width*CELL),VIEW_SIZE.y/(room().height*CELL+Scenery.HEIGHT+8)))
func view_origin() -> Vector2:
 return ORIGIN+(VIEW_SIZE-Vector2(room().width*CELL,room().height*CELL+Scenery.HEIGHT+8)*view_scale())/2+Vector2(0,Scenery.HEIGHT*view_scale())
func screen_cell(p: Vector2) -> Vector2i:
 return Vector2i(((p-view_origin())/view_scale()/CELL).floor())
func toggle_overview():
 overview=not overview;preview_level={};refresh()
func overview_transform(data: Dictionary) -> Dictionary:
 var bounds=Rect2(Vector2(data.rooms[0].position[0],data.rooms[0].position[1]),Vector2(data.rooms[0].width,data.rooms[0].height))
 for r in data.rooms:bounds=bounds.merge(Rect2(Vector2(r.position[0],r.position[1]),Vector2(r.width,r.height)))
 var scale=minf((VIEW_SIZE.x-100)/bounds.size.x,(VIEW_SIZE.y-110)/bounds.size.y)
 return {"scale":scale,"origin":ORIGIN+(VIEW_SIZE-bounds.size*scale)/2-bounds.position*scale}
func draw_overview():
 var data=level if preview_level.is_empty() else preview_level
 var transform=drag_transform if dragging_room else overview_transform(data);var scale=transform.scale;var origin=transform.origin
 var palette=[Color("708761"),Color("96815d"),Color("608784"),Color("8c7190")]
 for i in range(data.rooms.size()):
  var r=data.rooms[i];var color=palette[i%4]
  var solid=Scenery.walls(r)
  if dragging_room and drag_result.get("error","")!="" and Model.connected_component(level,room().id).has(r.id):color=Color("bc5555")
  for y in range(int(r.height)):
   for x in range(int(r.width)):
    var c=Vector2i(x,y)
    if not Model.inside(r,c):continue
    var rect=Rect2(origin+Vector2(c+Model.position(r))*scale,Vector2.ONE*scale)
    draw_texture_rect(Dungeon.texture("wall_mid" if solid.has(c) else "floor_1"),rect,false,Color.WHITE if i==room_index else Color(.8,.8,.8))
    if solid.has(c):draw_texture_rect_region(Dungeon.texture("wall_top_mid"),Rect2(rect.position,Vector2(scale,scale*.1875)),Rect2(0,13,16,3))
    if color==Color("bc5555"):draw_rect(rect,Color(.7,.15,.15,.4))
    if i==room_index:
     if not Model.inside(r,c+Vector2i.UP):draw_line(rect.position,rect.position+Vector2(scale,0),GOLD,2)
     if not Model.inside(r,c+Vector2i.DOWN):draw_line(rect.position+Vector2(0,scale),rect.end,GOLD,2)
     if not Model.inside(r,c+Vector2i.LEFT):draw_line(rect.position,rect.position+Vector2(0,scale),GOLD,2)
     if not Model.inside(r,c+Vector2i.RIGHT):draw_line(rect.position+Vector2(scale,0),rect.end,GOLD,2)
  var caption=origin+(Vector2(Model.position(r))+Vector2(r.spawn[0],r.spawn[1]))*scale
  draw_string(theme.default_font,caption,"%02d"%(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
 for r in data.rooms:
  for o in r.objects:
   if o.kind!="隔板门":continue
   var center=origin+(Vector2(Model.position(r))+Vector2(o.x+0.5,o.y+0.5))*scale
   draw_rect(Rect2(center-Vector2.ONE*scale*0.35,Vector2.ONE*scale*0.7),GOLD)
   if not o.get("entry",false):draw_line(center,center+Vector2(Model.DIRS[o.side])*scale*1.4,Color.WHITE,2)
 if dragging_room:
  var message="重叠：松手会取消" if drag_result.get("error","")!="" else ("已吸附 · 松手连接门与开关" if drag_result.get("snapped",false) else "移动房间组 · 靠近另一房间边缘吸附")
  draw_string(theme.default_font,ORIGIN+Vector2(12,22),message,HORIZONTAL_ALIGNMENT_LEFT,-1,16,GOLD)
 if not preview_level.is_empty() and not dragging_room:draw_string(theme.default_font,ORIGIN+Vector2(12,22),"拼接预览 · 尚未应用",HORIZONTAL_ALIGNMENT_LEFT,-1,18,GOLD)
 if playing:draw_string(theme.default_font,ORIGIN+Vector2(12,22),"地图暂停 · M 返回游戏",HORIZONTAL_ALIGNMENT_LEFT,-1,18,GOLD)
func select_overview(point: Vector2):
 overview_selected=false
 var transform=overview_transform(level)
 var cell=Vector2i(((point-transform.origin)/transform.scale).floor())
 for i in range(level.rooms.size()):
  var r=level.rooms[i]
  if Model.inside(r,cell-Model.position(r)):
   room_index=i;selection="";overview_selected=true;join_target="";refresh();return
func preview_join():
 if playing:return
 var result=Model.join(level,room().id,join_target,join_side,join_offset)
 preview_error=result.error
 if preview_error!="":preview_level={};hint(preview_error);queue_redraw();return
 preview_level=result.level;overview=true;hint("预览有效：门洞、开关已对齐。点击应用拼接保存修改。");queue_redraw()
func apply_join():
 if playing:return
 var result=Model.join(level,room().id,join_target,join_side,join_offset)
 if result.error!="":hint(result.error);return
 snapshot();level=result.level;preview_level={};overview=true;selection=result.door
 hint("拼接已应用；自动生成配对门和开关，可撤销。");refresh()
func disconnect_room():
 if playing:return
 snapshot()
 for o in room().objects.duplicate():
  if o.kind=="隔板门" and o.target!="finish":Model.remove_door(level,room().id,o.id)
 preview_level={};selection="";hint("已解除拼接；自动开关已移除；手动开关需重新关联或删除。可撤销。");refresh()
func build_shape_dialog():
 shape_dialog=ConfirmationDialog.new();shape_dialog.title="房间尺寸与形状";shape_dialog.size=Vector2i(540,440);add_child(shape_dialog)
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",10);shape_dialog.add_child(box)
 shape_description=Label.new();var description=shape_description;description.text="调整宽高、轮廓与朝向。已拼接房间需先解除拼接。\n超出新形状的对象会移除；应用后可以撤销。";box.add_child(description)
 for key in ["宽（10–30格）","高（10–24格）"]:
  var row=HBoxContainer.new();box.add_child(row);var caption=Label.new();caption.text=key;caption.custom_minimum_size.x=230;row.add_child(caption)
  var value=SpinBox.new();value.min_value=10;value.max_value=30 if key.begins_with("宽") else 24;value.step=1;row.add_child(value)
  if key.begins_with("宽"):size_width=value
  else:size_height=value
 shape_picker=OptionButton.new()
 for value in Model.SHAPES:shape_picker.add_item(value)
 box.add_child(shape_picker)
 rotation_picker=OptionButton.new()
 for value in ["朝向 0°","朝向 90°","朝向 180°","朝向 270°"]:rotation_picker.add_item(value)
 box.add_child(rotation_picker)
 shape_dialog.get_ok_button().text="添加房屋"
 shape_dialog.get_cancel_button().text="取消"
 shape_dialog.dialog_hide_on_ok=false
 shape_dialog.confirmed.connect(apply_shape)
func show_shape():
 if playing:return
 add_side=-1;shape_dialog.get_ok_button().text="应用修改";shape_dialog.title="房间尺寸与形状";shape_description.text="已拼接房间需先解除拼接；超出新形状的对象会移除。可撤销。"
 size_width.value=room().width;size_height.value=room().height;shape_picker.select(Model.SHAPES.find(room().shape));rotation_picker.select(room().rotation)
 shape_dialog.popup_centered()
func apply_shape():
 if add_side>=0:
  var added=VisualRooms.add_adjacent(level,add_source,add_side,int(size_width.value),int(size_height.value),Model.SHAPES[shape_picker.selected],rotation_picker.selected,"room_%d"%Time.get_ticks_usec())
  if added.error!="":shape_description.text=added.error;return
  snapshot();level=added.level;room_index=level.rooms.size()-1;selection="";preview_level={};overview=true
  add_side=-1;shape_dialog.hide();hint("已添加相邻房间，门与开关自动配对。可继续点 ＋ 或拖动房间组。");refresh();return
 var result=Model.reshape(level,room().id,int(size_width.value),int(size_height.value),Model.SHAPES[shape_picker.selected],rotation_picker.selected)
 if result.error!="":shape_description.text=result.error;hint(result.error);return
 shape_dialog.hide()
 snapshot();level=result.level;preview_level={};selection="";overview=false
 hint("房型已更新；移除 %d 个超出范围的对象，可撤销。"%result.removed);refresh()

func trap_inspector(o: Dictionary):
 inspector_label(Catalog.HELP[o.kind])
 var settings=Catalog.settings(o)
 var fields=[["delay","启动延迟 / 秒",0,120],["period","重复周期 / 秒",0.4,30],["active","生效时间 / 秒",0.1,float(settings.period)]]
 if o.kind=="炸弹":fields=[["delay","启动延迟 / 秒",0,120],["fuse","靠近后引信 / 秒",0.3,30]]
 if o.kind=="塌落平台":fields[2][1]="踩上后承重 / 秒"
 for field in fields:
  inspector_label(field[1]);var spin=SpinBox.new();spin.min_value=field[2];spin.max_value=field[3];spin.step=0.1;spin.value=settings[field[0]];inspector.add_child(spin)
  var key=field[0]
  spin.value_changed.connect(func(v):
   snapshot();o[key]=v
   if key=="period":o.active=minf(Catalog.settings(o).active,v);call_deferred("refresh")
   queue_redraw())
 if Catalog.directed(o.kind):
  inspector_label("方向")
  var picker=OptionButton.new()
  for side in Model.SIDES:picker.add_item(side)
  picker.select(int(settings.direction));inspector.add_child(picker)
  picker.item_selected.connect(func(i):snapshot();o.direction=i;queue_redraw())
 if Catalog.ranged(o.kind):
  inspector_label("距离 / 格")
  var spin=SpinBox.new();spin.min_value=1;spin.max_value=6;spin.step=1;spin.value=settings.travel;inspector.add_child(spin)
  spin.value_changed.connect(func(v):snapshot();o.travel=int(v);queue_redraw())
 inspector_label("Shift 点击多选；⌘/Ctrl+A 选全部机关。同类选择后统一调整时间。")

func draw_trap(o: Dictionary):
 var time=float(runtime[room_index].time) if playing else 0.0
 var p=Catalog.settings(o);var phase=Catalog.phase(o,time);var center=cell_center([o.x,o.y]);var at=Traps.position(o,time)
 var active=phase.active if playing else true
 var tint=Color.WHITE if active else Color("778573")
 if phase.warning and playing:draw_arc(center,23,0,TAU,24,GOLD,2)
 if Catalog.ranged(o.kind):
  var end=center+Vector2(Model.DIRS[int(p.direction)])*float(p.travel)*CELL
  if not playing:draw_dashed_line(center,end,Color("798665"),1,5)
  if o.kind in ["火焰箱","伸缩长矛","风扇"] and active:
   draw_line(center,end,Color(0.9,0.4,0.16,0.5) if o.kind=="火焰箱" else Color(0.75,0.8,0.62,0.4),22)
   draw_line(center,end,GOLD,2)
   if o.kind=="火焰箱":
    for i in range(1,int(p.travel)+1):
     var flame=center+Vector2(Model.DIRS[int(p.direction)])*CELL*i
     draw_texture_rect_region(flame_tex,Rect2(flame-Vector2(16,16),Vector2(32,32)),Rect2((int(time*12)%4)*16,0,16,16))
 if o.kind=="摆动刺球":draw_line(center,at,Color("879480"),3)
 if o.kind=="炸弹" and playing:
  var remaining=float(runtime[room_index].bombs[o.id])
  if remaining==0:draw_circle(center,12,Color("443527"));return
  if remaining>0:
   draw_arc(center,86,0,TAU,40,Color(1,0.4,0.2,0.5),1)
   draw_string(theme.default_font,center+Vector2(-10,-20),"%.1f"%remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,15,GOLD)
 if o.kind=="塌落平台" and playing:
  var armed=runtime[room_index].mechanisms[o.id].armed
  if armed>=float(p.active):draw_rect(Rect2(center-Vector2(14,14),Vector2(28,28)),Color("0b100d"));return
  if armed>=0:tint=Color("f5ac60")
 var info=Catalog.SHEETS[o.kind];var frame=int(time*10)%int(info[3]) if active else 0
 if o.kind=="地刺":frame=5 if active else 0
 var target=Rect2(at-Vector2(16,16),Vector2(32,32))
 if o.kind=="伸缩长矛":
  var zoom=view_scale();var angle=Vector2(Model.DIRS[int(p.direction)]).angle()+PI/2
  draw_set_transform(view_origin()+center*zoom,angle,Vector2.ONE*zoom)
  draw_texture_rect_region(trap_textures[o.kind],Rect2(-8,-float(p.travel)*CELL,16,float(p.travel)*CELL+16),Rect2((11 if active else 0)*16,0,16,64),tint)
  draw_set_transform(view_origin(),0,Vector2.ONE*zoom)
  return
 draw_texture_rect_region(trap_textures[o.kind],target,Rect2(frame*info[1],0,info[1],info[2]),tint)
 if not playing and (o.id==selection or selections.has(o.id)):
  draw_string(theme.default_font,center+Vector2(-14,-22),"延迟 %.1fs"%p.delay,HORIZONTAL_ALIGNMENT_LEFT,-1,13,GOLD)

func build_library_ui():
 for state in ["normal","hover","pressed"]:
  var style=StyleBoxTexture.new();style.texture=load("res://art/ui/UI_Flat_Button01a_%d.png"%(["normal","hover","pressed"].find(state)+1))
  style.texture_margin_left=8;style.texture_margin_right=8;style.texture_margin_top=8;style.texture_margin_bottom=8
  style.content_margin_left=10;style.content_margin_right=10;style.content_margin_top=5;style.content_margin_bottom=5
  style.modulate_color=Color("687057") if state=="normal" else Color("9b986c")
  theme.set_stylebox(state,"Button",style)
  theme.set_stylebox(state,"OptionButton",style)
 home=PanelContainer.new();home.position=Vector2(18,92);home.size=Vector2(1244,630);add_child(home)
 var panel=StyleBoxFlat.new();panel.bg_color=Color("18221b");panel.content_margin_left=40;panel.content_margin_right=40;panel.content_margin_top=24;panel.content_margin_bottom=24;home.add_theme_stylebox_override("panel",panel)
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",12);home.add_child(box)
 var title=Label.new();title.text="我的地图  /  选择一张地图开始";title.add_theme_font_size_override("font_size",24);box.add_child(title)
 var subtitle=Label.new();subtitle.text="内置地图与已加入游玩列表的作品 · 地图保存在本机，退出后仍保留";box.add_child(subtitle)
 library_list=ItemList.new();library_list.custom_minimum_size.y=325;library_list.size_flags_vertical=Control.SIZE_EXPAND_FILL;library_list.fixed_icon_size=Vector2i(32,32);box.add_child(library_list)
 var selected_style=StyleBoxFlat.new();selected_style.bg_color=Color("3d4d35");selected_style.border_color=GOLD;selected_style.set_border_width_all(1)
 library_list.add_theme_stylebox_override("selected",selected_style);library_list.add_theme_stylebox_override("selected_focus",selected_style)
 var row=HBoxContainer.new();box.add_child(row)
 button("‹ 启动界面",row,show_start)
 button("开始游戏",row,func():open_library_map(true)).icon=load("res://art/ui/UI_Flat_IconPlay01a.png")
 edit_map_button=button("编辑选中地图",row,func():open_library_map(false))
 library_list.item_selected.connect(func(i):
  edit_map_button.disabled=library_entries[i].get("runtime","").begins_with("native080")
  hint("经典0.8.0关卡 + 新版模块化角色；衣柜可换装，原关卡布局固定。" if edit_map_button.disabled else "选择地图开始游戏，或进入工坊继续创造。"))
 button("继续当前草稿",row,func():resume_editor())
 button("新建空白地图",row,new_map)
 button("角色衣柜",row,func():outfit_panel.open(outfit))
 button("操作指南",row,func():help_dialog.popup_centered())
 var foot=Label.new();foot.text="导入外部地图：继续草稿 → 载入 JSON → 加入游玩列表。\n保存草稿不会自动更新正式地图；修改后请再次加入游玩列表。";box.add_child(foot)
 home.hide()
 play_hud=HBoxContainer.new();play_hud.position=Vector2(28,26);add_child(play_hud)
 button("返回主界面",play_hud,show_home).icon=load("res://art/icons/fa16.png")
 button("重试当前房间 R",play_hud,retry)
 button("地图 / 暂停 M",play_hud,toggle_overview)
 button("角色衣柜",play_hud,func():outfit_panel.open(outfit))
 button("操作指南",play_hud,func():help_dialog.popup_centered())
 play_hud.hide()
 publish_dialog=ConfirmationDialog.new();publish_dialog.title="加入本机游玩列表";publish_dialog.size=Vector2i(460,160);add_child(publish_dialog)
 map_title=LineEdit.new();map_title.placeholder_text="地图名称";map_title.max_length=60;publish_dialog.add_child(map_title)
 publish_dialog.get_ok_button().text="加入 / 更新";publish_dialog.get_cancel_button().text="取消"
 publish_dialog.confirmed.connect(func():
  var result=Library.save_map(level,map_title.text,published_path)
  if result.error!="":hint("未加入："+result.error);return
  published_path=result.path;level.title=map_title.text;hint("已加入游玩列表。点击主界面即可正式开始；草稿后续修改需再次加入。"))
 help_dialog=AcceptDialog.new();help_dialog.title="工坊操作指南";help_dialog.size=Vector2i(740,540);add_child(help_dialog)
 help_dialog.dialog_text="房间挑战：右侧房间属性选择木头人/数字快答，调整时间与题数。\n木头人：绿灯走、红灯停，到出口后按 F 撤离；数字快答：按 1/2/3 回答。\n\n1. 主界面选择地图后点「编辑」，或新建空白地图。\n2. 左侧尺寸/房型可选宽高与轮廓；点击「搭建房屋」，点房间边缘 ＋ 添加；拖动吸附拼接。\n3. 展开机关选择，选机关后点网格放置；选择工具再点单个机关。\n4. 右侧单独调整延迟、周期、生效时间、方向、距离。\n   四个地刺可分别设延迟 0 / 0.5 / 1 / 1.5 秒。\n5. 最后房间外墙放隔板门（默认终点），门旁放开关并关联。\n6. 保存草稿；点击从第1关试玩，WASD移动，F按开关，R重试。\n7. 确认能通关后返回编辑 → 加入游玩列表 → 填名称。\n8. 主界面选地图 → 开始游戏。可保存多张，重开软件仍能选。\n\nM 查看总览并暂停；Esc 返回编辑（正式游戏返回主界面）。\n只有穿过已打开的门才进入下一关；未进入房间的计时保持待机。\n保存草稿 ≠ 加入游玩列表；编辑已收藏地图后再次加入会更新原作品。\n要制作副本：载入另存的 JSON 后重新加入。\n主界面或游玩时打开「角色衣柜」换装，保存后所有地图生效。\n衣柜暂停游戏；经典地图 J 攻击，飞刀带真实弹道和墙体阻挡。\n空格跳跃（E仍可用），经典地图 Shift 冲刺；K 爆发技能。\n工坊 J 可试挥或投掷（工坊房间尚无战斗敌人）；装备掉落未加入。"

func show_home():
 if trap_picker!=null:trap_picker.hide()
 if start_screen!=null:start_screen.hide()
 if formal_run and not draft_backup.is_empty():
  level=draft_backup.level;room_index=draft_backup.room_index;published_path=draft_backup.published_path;current_path=draft_backup.current_path;selection="";draft_backup={}
 if playing:playing=false;won=false
 for n in editor_nodes:n.hide()
 editor_nodes[0].show();editor_nodes[1].show();status.show()
 play_hud.hide()
 formal_run=false;library_entries=Library.entries()
 library_entries.append({"title":"立体地宫 · 场景装饰示例","path":"","data":Library.scenery_showcase()})
 library_entries.append({"title":"挑战试炼 · 木头人与数字快答","path":"","data":Library.challenges()})
 library_entries.append({"title":"经典地宫 · 0.8.0 / 新版角色","runtime":"native080","path":""})
 library_entries.append({"title":"低语森林 · 0.8.0 / 新版角色","runtime":"native080_forest","path":""})
 library_list.clear()
 for entry in library_entries:
  var caption=entry.title+("    · Godot原生画面" if entry.get("runtime","").begins_with("native080") else "    · %d 个房间"%entry.data.rooms.size())
  library_list.add_item(caption,load("res://art/icons/fa16.png"))
 edit_map_button.disabled=false
 if not library_entries.is_empty():library_list.select(0)
 home.show();hint("选择地图开始游戏，或进入工坊继续创造。");refresh()

func open_library_map(play_now: bool):
 var items=library_list.get_selected_items()
 if items.is_empty():return
 var entry=library_entries[items[0]]
 if entry.get("runtime","").begins_with("native080"):
  if not play_now:hint("经典地图保留原版玩法，暂不支持工坊编辑。");return
  if not legacy_game.start_game("forest" if entry.runtime=="native080_forest" else "catacombs",outfit):hint("无法开始经典地图："+str(legacy_game.state.get("error","未知错误")))
  return
 if play_now:draft_backup={"level":level.duplicate(true),"room_index":room_index,"published_path":published_path,"current_path":current_path}
 else:snapshot()
 level=entry.data.duplicate(true);published_path=entry.path;current_path="user://rooms-v2.json"
 room_index=0;selection="";overview=false;resume_editor()
 if play_now:
  toggle_play();formal_run=playing
  if formal_run:
   for n in editor_nodes:n.hide()
   mode_label.show();dimensions_label.show();status.show();play_hud.show();refresh()
  hint("正式游玩 · "+entry.title+" · WASD移动 / F开关 / R重试 / Esc主界面")

func show_publish():
 if playing:hint("请先返回编辑再加入游玩列表。");return
 var issue=Model.validate(level,true)
 if issue!="":hint("无法加入："+issue);return
 map_title.text=level.get("title","我的地图");publish_dialog.popup_centered()

func new_map():
 snapshot();level={"schema":2,"rooms":[Model.make_room("room_first","第一关",18,14,"矩形")]}
 room_index=0;published_path="";current_path="user://rooms-v2.json";selection="";overview=false;resume_editor()
 hint("空白地图：先布置房间，再在外墙放终点门并添加关联开关。")

func resume_editor():
 if start_screen!=null:start_screen.hide()
 home.hide();formal_run=false
 for n in editor_nodes:n.show()
 play_hud.hide();refresh()

func build_outfit_ui():
 var saved=Character.read_profile();outfit=saved.outfit
 outfit_panel=OutfitPanel.new();add_child(outfit_panel)
 outfit_panel.outfit_applied.connect(func(value):outfit=value;hint("角色外观已保存，所有地图使用当前搭配。");queue_redraw())
 if saved.error!="":hint(saved.error)


func plus_center(side: int) -> Vector2:
 var transform=overview_transform(level);var r=room()
 var anchor=Vector2(r.width,r.height)/2
 var best=-INF
 for y in range(int(r.height)):
  for x in range(int(r.width)):
   var cell=Vector2i(x,y)
   if Model.door_side(r,cell)!=side:continue
   var score=Vector2(cell).dot(Vector2(Model.DIRS[side]))*100-absf((y-r.height/2.0) if side%2==0 else (x-r.width/2.0))
   if score>best:best=score;anchor=Vector2(cell)+Vector2.ONE/2
 return transform.origin+(Vector2(Model.position(r))+anchor)*transform.scale+Vector2(Model.DIRS[side])*(transform.scale/2+19)

func plus_at(point: Vector2) -> int:
 for side in range(4):
  if Rect2(plus_center(side)-Vector2(20,20),Vector2(40,40)).has_point(point):return side
 return -1
func show_add_adjacent(side: int):
 if playing:return
 if level.rooms.size()>=32:hint("最多32个房间。");return
 add_side=side;add_source=room().id;shape_dialog.get_ok_button().text="添加房屋"
 shape_dialog.title="在「%s」%s侧添加房屋"%[room().name,Model.SIDES[side]]
 shape_description.text="选择大小、形状与朝向。确认后自动对齐墙壁并生成门和开关。\n无可用空间时保持原地图；取消不会添加房间。"
 size_width.value=18;size_height.value=14;shape_picker.select(0);rotation_picker.select(0)
 shape_dialog.popup_centered()
func begin_room_drag(point: Vector2):
 dragging_room=true;drag_start=point;drag_transform=overview_transform(level);drag_result={};drag_moved=false
func update_room_drag(point: Vector2):
 if point.distance_to(drag_start)<6 and not drag_moved:return
 drag_moved=true
 var delta=Vector2i(((point-drag_start)/drag_transform.scale).round())
 drag_result=VisualRooms.move_preview(level,room().id,delta,minf(3,20/drag_transform.scale))
 preview_level=drag_result.level;queue_redraw()
func cancel_room_drag():
 dragging_room=false;drag_moved=false;preview_level={};drag_result={};hint("已取消移动，地图未改变。");refresh()
func finish_room_drag(point: Vector2):
 if not Rect2(ORIGIN,VIEW_SIZE).has_point(point):cancel_room_drag();return
 update_room_drag(point)
 if drag_moved:
  if drag_result.get("error","")!="":hint("移动取消："+drag_result.error)
  elif drag_result.level!=level:
   snapshot();level=drag_result.level;hint("房间已吸附连接，配对门与开关已生成。" if drag_result.snapped else "房间组已移动，可撤销。")
 dragging_room=false;drag_moved=false;drag_result={};preview_level={};refresh()

func _exit_tree():
 if classic_runtime!=null and classic_runtime.active:classic_runtime.close()

func build_legacy_game():
 legacy_game=LegacyGame.new();legacy_game.theme=theme;add_child(legacy_game)
 legacy_game.returned.connect(func():hint("已返回我的地图，当前草稿保持不变。"))
 legacy_game.wardrobe_requested.connect(func():outfit_panel.open(outfit))

func build_start_screen():
 start_screen=StartScreen.new();add_child(start_screen);start_screen.hide()
 start_screen.start_requested.connect(show_home)
 start_screen.workshop_requested.connect(resume_editor)

func show_start():
 show_home();home.hide();status.hide()
 for n in editor_nodes:n.hide()
 start_screen.show();queue_redraw()

func challenge_inspector():
 inspector_label("房间挑战")
 var c=Challenge.config(room())
 var picker=OptionButton.new()
 for value in Challenge.TYPES:picker.add_item(value)
 picker.select(Challenge.TYPES.find(c.type));inspector.add_child(picker)
 picker.item_selected.connect(func(i):
  var value=Challenge.TYPES[i]
  if value in Challenge.Spatial.TYPES and value!="普通房间":pending_room_template=value;room_template_confirm.popup_centered()
  else:snapshot();room().challenge=c.duplicate();room().challenge.type=value;refresh())
 if c.type=="普通房间":return
 var spatial=c.type in ["木头人机关房","数字地砖"]
 if spatial:inspector_label("大型机关房：至少18×12矩形。模板保留门与开关，可拼接/存档。木头人需在纵向火带间停步；数字地砖需走到正确数字，按键答题无效。")
 if not spatial:inspector_label("绿灯前进，红灯停步。到出口开关旁触发炸弹，再按 F 开门撤离。" if c.type=="木头人" else "进入房间开始计时，点击答案或按 1 / 2 / 3；完成全部题目后按 F 开门。")
 var fields=[["green","绿灯（秒）"],["warning","转身预警（秒）"],["red","红灯（秒）"],["fuse","炸弹引信（秒）"]] if c.type in ["木头人","木头人机关房"] else [["rounds","连续答对题数"],["seconds","每题时限（秒）"]]
 if c.type=="木头人机关房":fields=fields.slice(0,3)
 for field in fields:
  inspector_label(field[1])
  var spin=SpinBox.new();spin.min_value=(0.4 if field[0]=="warning" else 1.5 if field[0]=="green" else 2 if field[0]=="seconds" else 1) if spatial else (0.2 if field[0]=="warning" else 1);spin.max_value=({"green":10,"warning":2,"red":6,"seconds":10,"rounds":6}.get(field[0],30)) if spatial else 30;spin.step=1 if field[0]=="rounds" else 0.1;spin.value=c[field[0]];inspector.add_child(spin)
  var key=field[0]
  spin.value_changed.connect(func(value):snapshot();room().challenge=Challenge.config(room());room().challenge[key]=value)

func build_challenge_hud():
 challenge_panel=PanelContainer.new();challenge_panel.position=Vector2(976,110);challenge_panel.size=Vector2(282,510);add_child(challenge_panel)
 var style=StyleBoxFlat.new();style.bg_color=Color("18251e");style.border_color=GOLD;style.set_border_width_all(2);style.content_margin_left=18;style.content_margin_right=18;style.content_margin_top=20;challenge_panel.add_theme_stylebox_override("panel",style)
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",16);challenge_panel.add_child(box)
 challenge_text=Label.new();challenge_text.custom_minimum_size=Vector2(238,250);challenge_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;challenge_text.add_theme_font_size_override("font_size",20);box.add_child(challenge_text)
 for i in range(3):
  var index=i
  var b=button("",box,func():answer_challenge(index));b.custom_minimum_size.y=46;answer_buttons.append(b)
 challenge_panel.hide()

func answer_challenge(index: int):
 if not playing or not alive or won or overview or home.visible or outfit_panel.visible or help_dialog.visible:return
 var c=Challenge.config(room())
 if c.type!="数字快答":return
 if not Challenge.answer(runtime[room_index].challenge,c,index):die("回答错误")
 elif runtime[room_index].challenge.done:hint("数字快答完成！前往门旁按 F 开门。")
 update_challenge_hud()

func update_challenge_hud():
 if challenge_panel==null:return
 var enabled=playing and not home.visible and not overview and not legacy_game.active and not outfit_panel.visible and not help_dialog.visible and not start_screen.visible and Challenge.config(room()).type!="普通房间"
 challenge_panel.visible=enabled
 inspector.visible=not enabled
 if not enabled:return
 var c=Challenge.config(room());var st=runtime[room_index].challenge
 for b in answer_buttons:b.hide()
 if Challenge.spatial(room()):
  if c.type=="数字地砖":challenge_text.text="算术熔岩房  %d / %d\n\n"%[st.round,int(c.rounds)]+("已通过 · 按 F 开门" if st.done else "进入九宫格开始答题" if st.phase=="prepare" else st.question+"\n剩余 %.1f 秒\n站到正确数字上；其他地砖会坠落。"%st.timer if st.phase=="question" else "留在正确数字上，等待地板复原")
  else:challenge_text.text="木偶守卫 · 机关房\n\n"+("已通过 · 按 F 开门" if st.done else {"green":"绿灯前进","warning":"转身预警 · 停步","red":"红灯停步"}.get(st.phase,"准备"))+"\n\n纵向火焰会间歇喷发，停在火带之间。红灯位移会被激光击中。"
 elif c.type=="数字快答":
  challenge_text.text="数字快答   %d / %d\n\n"%[st.round,int(c.rounds)]+("挑战完成\n按 F 完成本关并开门。" if st.done else st.question+"\n\n剩余 %.1f 秒\n点击答案 / 按 1、2、3"%maxf(0,c.seconds-st.question_time))
  if not st.done:
   for i in range(3):answer_buttons[i].show();answer_buttons[i].text="%d    ·    %d"%[i+1,st.choices[i]];answer_buttons[i].disabled=not alive or won
 else:
  challenge_text.text="木头人试炼\n\n"+({"green":"绿灯 · 前进","warning":"即将转身 · 停步","red":"红灯 · 不要移动"}[st.phase] if not st.done else "守卫变成炸弹！\n引信 %.1f 秒"%maxf(0,c.fuse-st.bomb))+"\n\n到达出口开关旁\n按 F 开门并撤离\n\nR 重试 · M 地图暂停"
 if not alive:challenge_text.text+="\n\n挑战失败 · R 重试"

func draw_room_challenge():
 if Challenge.spatial(room()):
  Challenge.Spatial.draw(self);return
 var c=Challenge.config(room())
 if c.type!="木头人":return
 for o in room().objects:
  if o.kind!="开关":continue
  var door=Model.door_by_id(room(),o.link)
  if door.is_empty() or door.get("entry",false):continue
  var center=cell_center([o.x,o.y])+Vector2(0,-24)
  var st=runtime[room_index].challenge if playing else {}
  if st.get("done",false):
   draw_texture_rect_region(bomb_tex,Rect2(center-Vector2(16,16),Vector2(32,32)),Rect2(0,0,32,32))
  else:
   Dungeon.draw_enemy(self,"Monster01",center+Vector2(0,16),false,float(st.get("time",0)),1,0,false,0,.8)
   var color={"green":Color("80bb79"),"warning":GOLD,"red":Color("dd7665")}[st.get("phase","green")]
   draw_circle(center+Vector2(0,-47),5,color)

func build_friendly_tools():
 var shade=ColorRect.new();shade.color=Color(0,0,0,0.58);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade);shade.hide()
 trap_picker=preload("res://trap_picker.gd").new();add_child(trap_picker)
 trap_picker.visibility_changed.connect(func():shade.visible=trap_picker.visible)
 trap_picker.picked.connect(func(kind):tool=kind;selection="";hint("已选择 "+kind+"：点击画布放置；用选择工具点击单个机关可设置时间。");refresh())
 for side in range(4):
  var direction=side
  var b=button("",self,func():show_add_adjacent(direction));b.icon=plus_texture;b.expand_icon=true;b.custom_minimum_size=Vector2(40,40);b.size=Vector2(40,40);b.tooltip_text="在"+Model.SIDES[side]+"侧添加并自动拼接房屋";b.hide();join_buttons.append(b)

func update_join_buttons():
 for i in range(join_buttons.size()):
  var b=join_buttons[i]
  b.visible=overview and not playing and not dragging_room and preview_level.is_empty() and not home.visible and not start_screen.visible and not shape_dialog.visible and not trap_picker.visible and not outfit_panel.visible
  if b.visible:b.position=plus_center(i)-Vector2(20,20)

func workshop_attack():
 if not playing or not alive or won or attack_cool>0:return
 attack_cool=.38 if outfit.weapon=="kunai" else .55;attack_left=.32;actor_time=0;actor_action="attack"
 var direction={"east":Vector2.RIGHT,"west":Vector2.LEFT,"north":Vector2.UP,"south":Vector2.DOWN}[actor_direction]
 if outfit.weapon=="kunai":
  combat_shots.append({"x":player.x,"y":player.y,"dx":direction.x,"dy":direction.y,"left":460.0})
  combat_fx.append({"kind":"launch","x":player.x+direction.x*20,"y":player.y+direction.y*20-20,"age":0.0,"life":.24})
 else:combat_fx.append({"kind":"thrust" if outfit.weapon=="spear" else "slash","x":player.x,"y":player.y-18,"angle":direction.angle(),"r":145 if outfit.weapon=="spear" else 90,"age":0.0,"life":.24})

func workshop_jump():
 if not playing or not alive or won or air_time>0 or jump_cool>0:return
 air_time=.55;jump_cool=.78;launch_velocity=Vector2.ZERO;manual_jump=true
func workshop_skill():
 if not playing or not alive or won or skill_cool>0:return
 skill_cool=7;attack_left=.22;actor_action="attack";actor_time=0
 var direction={"east":Vector2.RIGHT,"west":Vector2.LEFT,"north":Vector2.UP,"south":Vector2.DOWN}[actor_direction]
 combat_fx.append({"kind":"skill","x":player.x,"y":player.y-18,"angle":direction.angle(),"r":145,"age":0.0,"life":.24})

func test_rooms031():
 var suite=load("res://tests031.gd").new();add_child(suite);await suite.run(self)
 get_tree().quit(0 if suite.failures.is_empty() else 1)
func capture031():
 set_process(false)
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var mode="multi" if "--multi" in OS.get_cmdline_user_args() else "math" if "--math" in OS.get_cmdline_user_args() else "wood"
 var path="res://../reports/031/"+mode+".png"
 get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path));print("CAPTURE "+ProjectSettings.globalize_path(path))
 get_tree().quit()
