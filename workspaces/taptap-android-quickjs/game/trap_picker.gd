extends PanelContainer
signal picked(kind: String)
const Catalog=preload("res://trap_catalog.gd")
const GROUPS={"接触机关":["地刺","旋转刺阵","移动锯轮","摆动刺球","伸缩长矛"],"远程与爆炸":["炸弹","箭塔","火焰箱","落石"],"移动与地形":["风扇","塌落平台","弹簧"]}
var search: LineEdit
var category: OptionButton
var grid: GridContainer
var detail: Label
var chosen="地刺"
var place: Button
func _ready():
 position=Vector2(220,96);size=Vector2(844,620)
 var style=StyleBoxFlat.new();style.bg_color=Color("18251e");style.border_color=Color("d5bb78");style.set_border_width_all(2)
 for edge in [0,1,2,3]:style.set_content_margin(edge,24)
 add_theme_stylebox_override("panel",style)
 var box=VBoxContainer.new();box.add_theme_constant_override("separation",12);add_child(box)
 var header=HBoxContainer.new();box.add_child(header)
 var title=Label.new();title.text="机关素材库 · 12 种";title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.add_theme_font_size_override("font_size",24);header.add_child(title)
 var close=Button.new();close.text="收起 / Esc";close.pressed.connect(hide);header.add_child(close)
 var filter_row=HBoxContainer.new();box.add_child(filter_row)
 search=LineEdit.new();search.placeholder_text="搜索名称或用途，例如：喷火、跳跃";search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;search.custom_minimum_size.y=40;filter_row.add_child(search)
 category=OptionButton.new();category.add_item("全部机关")
 for group in GROUPS:category.add_item(group)
 filter_row.add_child(category)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(790,286);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(scroll)
 grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",10);scroll.add_child(grid)
 detail=Label.new();detail.custom_minimum_size=Vector2(780,92);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(detail)
 place=Button.new();place.custom_minimum_size.y=46;place.pressed.connect(func():picked.emit(chosen);hide());box.add_child(place)
 search.text_changed.connect(func(_value):rebuild());category.item_selected.connect(func(_i):rebuild())
 rebuild();hide()
func open(current: String):
 if Catalog.known(current):chosen=current
 search.text="";category.select(0);rebuild();show();search.grab_focus()
func rebuild():
 for child in grid.get_children():grid.remove_child(child);child.queue_free()
 for kind in Catalog.KINDS:
  if category.selected>0 and not GROUPS[category.get_item_text(category.selected)].has(kind):continue
  if not search.text.strip_edges().is_empty() and not (kind+Catalog.HELP[kind]).contains(search.text.strip_edges()):continue
  var b=Button.new();b.text=kind;b.icon=Catalog.icon(kind);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",38);b.custom_minimum_size=Vector2(250,68);b.toggle_mode=true;b.button_pressed=kind==chosen;b.tooltip_text=Catalog.HELP[kind];grid.add_child(b)
  b.pressed.connect(func():chosen=kind;rebuild())
 place.disabled=grid.get_child_count()==0
 if grid.get_child_count()==0:
  var empty=Label.new();empty.text="没有匹配的机关，试试其他关键词。";grid.add_child(empty)
 var p=Catalog.defaults(chosen)
 detail.text=chosen+"  ·  "+Catalog.HELP[chosen]+"\n默认周期 %.1f 秒 / 生效 %.1f 秒。放置后用“选择”点击单个机关，分别调整时间与方向。"%[p.period,p.active]
 place.text="使用「"+chosen+"」 · 返回画布放置"
