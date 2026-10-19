extends Control
signal start_requested
signal workshop_requested
const Character=preload("res://character_catalog.gd")
var clock=0.0
var multiplayer_dialog: AcceptDialog
func text(value: String,at: Vector2,font_size: int,color: Color):
 var label=Label.new();label.text=value;label.position=at;label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",color);add_child(label)
func _ready():
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 text("THORNBOUND",Vector2(92,94),18,Color("a9ad86"))
 text("荆棘盟约",Vector2(88,132),64,Color("e5d4a0"))
 text("穿过古老地宫，创造属于你的试炼。",Vector2(94,224),19,Color("a7b39a"))
 var labels=["开始游戏","多人游戏","创意工坊"]
 for i in range(3):
  var b=Button.new();b.text=labels[i];b.position=Vector2(94,322+i*84);b.size=Vector2(360,64);b.add_theme_font_size_override("font_size",24);add_child(b)
  match i:
   0:b.pressed.connect(func():start_requested.emit())
   1:b.pressed.connect(func():multiplayer_dialog.popup_centered(Vector2i(540,240)))
   2:b.pressed.connect(func():workshop_requested.emit())
 text("开发中",Vector2(475,428),15,Color("a7b39a"))
 text("单人冒险  /  房屋拼接  /  机关挑战",Vector2(94,628),16,Color("a7b39a"))
 text("LOCAL DEMO   ·   本地实验版",Vector2(94,733),13,Color("788770"))
 text("THE GATE AWAITS",Vector2(811,665),16,Color("a9ad86"))
 multiplayer_dialog=AcceptDialog.new();multiplayer_dialog.title="多人游戏 · 开发中";multiplayer_dialog.dialog_text="当前版本支持单人冒险与本地创意工坊。\n联机房间、邀请与同步尚未接入。\n可先在创意工坊制作并试玩自己的挑战地图。";add_child(multiplayer_dialog)
func _process(delta):
 if visible:clock+=delta;queue_redraw()
func _draw():
 draw_rect(Rect2(0,0,1280,800),Color("101b18"))
 for i in range(36):
  var x=520+i*24;var h=80+(i*71)%160
  draw_rect(Rect2(x,330-h,18,500+h),Color("192b25"))
 draw_rect(Rect2(602,533,650,267),Color("202e26"))
 for y in range(6):
  for x in range(11):
   draw_rect(Rect2(602+x*64+(y%2)*24,540+y*48,60,44),Color("2b392c") if (x+y)%3 else Color("34412f"))
 for y in range(9):
  for x in range(6):
   if x in [0,5] or y<2:draw_rect(Rect2(754+x*48,158+y*44,44,40),Color("4b5540") if (x+y)%3 else Color("606348"))
 draw_rect(Rect2(804,249,184,286),Color("090f10"))
 draw_rect(Rect2(814,259,164,276),Color("172620"),false,3)
 for x in [738,1044]:
  draw_rect(Rect2(x,350,10,72),Color("605137"))
  var flicker=sin(clock*7+x)*3
  draw_rect(Rect2(x-6,327+flicker,22,32),Color("b86c3d"))
  draw_rect(Rect2(x,322+flicker,10,24),Color("e2bc70"))
 Character.draw_actor(self,Character.DEFAULT,Vector2(899,548),"idle","north",clock,2.4)
 for i in range(22):
  var p=Vector2(620+(i*79)%590,130+fmod(i*43+clock*8,520))
  draw_rect(Rect2(p,Vector2(2,2)),Color("8a9860"))
 draw_rect(Rect2(26,26,1228,748),Color("536049"),false,2)
 draw_line(Vector2(94,286),Vector2(454,286),Color("68724e"),2)
