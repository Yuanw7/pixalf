extends RefCounted
const TYPES=["普通房间","木头人机关房","算术熔岩机关房"]
const BOSS=preload("res://art/challenges/wooden-sentinel.png")
static func kind(r: Dictionary) -> String:return r.get("challenge",{}).get("kind","普通房间")
static func config(r: Dictionary) -> Dictionary:
 var c={"kind":kind(r),"green":3.4,"warning":0.6,"red":2.6,"answer_time":3.0,"rounds":2}
 c.merge(r.get("challenge",{}),true);return c
static func validate(r: Dictionary) -> String:
 var raw=r.get("challenge",{})
 if not raw is Dictionary:return "机关房间配置无效"
 var c=config(r)
 if not TYPES.has(c.kind):return "未知机关房间类型"
 if c.kind==TYPES[0]:return ""
 if r.shape!="矩形" or r.width<18 or r.height<12:return "大型机关房需至少18×12格矩形"
 for k in ["green","warning","red","answer_time","rounds"]:
  if not (c[k] is float or c[k] is int) or not is_finite(float(c[k])):return "机关房时间/题数必须为有限数值"
 if c.green<1.5 or c.green>10 or c.warning<0.4 or c.warning>2 or c.red<1 or c.red>6:return "红绿灯时间超出允许范围"
 if c.answer_time<2 or c.answer_time>10 or c.rounds<1 or c.rounds>6 or c.rounds!=int(c.rounds):return "答题时间需2–10秒，题数需1–6题"
 return ""
static func apply(r: Dictionary,type: String) -> Dictionary:
 var result=r.duplicate(true)
 if not TYPES.has(type):return {"error":"未知机关房类型"}
 if type==TYPES[0]:result.erase("challenge");return {"error":"","room":result}
 result.challenge={"kind":type}
 var issue=validate(result)
 if issue!="":return {"error":issue}
 # A room template owns its interior. Paired doors and their switches survive.
 result.objects=result.objects.filter(func(o):return o.kind in ["隔板门","开关"])
 result.walls=result.walls.filter(func(c):return c[0]==0 or c[1]==0 or c[0]==r.width-1 or c[1]==r.height-1)
 result.spawn=[2,int(r.height)-3]
 while result.objects.any(func(o):return [o.x,o.y]==result.spawn):result.spawn[0]+=1
 return {"error":"","room":result}
static func state() -> Dictionary:
 return {"elapsed":0.0,"cleared":false,"phase":"prepare","timer":0.8,"round":0,"question":"","numbers":[],"safe":-1,"laser":0.0,"laser_target":Vector2.ZERO}
static func board(r: Dictionary) -> Rect2:
 return Rect2(Vector2(int(r.width/2)-3,int(r.height/2)-3)*32,Vector2(192,192))
static func tile(r: Dictionary,p: Vector2) -> int:
 var b=board(r)
 if not b.has_point(p):return -1
 var cell=Vector2i(((p-b.position)/64).floor());return cell.y*3+cell.x
static func light(r: Dictionary,time: float) -> String:
 var c=config(r);var t=fposmod(time,float(c.green+c.warning+c.red))
 return "green" if t<c.green else "warning" if t<c.green+c.warning else "red"
static func lanes(r: Dictionary,time: float) -> Array:
 var result=[]
 for i in range(4):
  var x=roundi(4+(r.width-8)*i/3.0)*32+16
  var age=fposmod(time-i*0.45,3.2)
  result.append({"x":x,"active":age>=1.5 and age<2.7,"warning":age>=1.1 and age<1.5})
 return result
static func ask(s: Dictionary):
 var a=randi_range(1,5);var b=randi_range(1,4);var subtract=randf()<.5
 var answer=b if subtract else a+b
 s.question=("%d − %d = ?"%[a+b,a]) if subtract else ("%d + %d = ?"%[a,b])
 s.numbers=range(1,10);s.numbers.shuffle();s.safe=s.numbers.find(answer)
static func update(app,dt: float,before: Vector2):
 var r=app.room();var type=kind(r)
 if type==TYPES[0]:return
 var s=app.runtime[app.room_index].challenge;var c=config(r)
 if s.cleared:return
 s.elapsed+=dt
 if type==TYPES[1]:
  if s.laser>0:
   s.laser-=dt
   if s.laser<=0:app.die("红灯移动，被木偶守卫的激光击中")
   return
  # Inspect the frame's actual displacement; wind, springs and walking count alike.
  if light(r,s.elapsed)=="red" and light(r,maxf(0,s.elapsed-dt))=="red" and app.player.distance_to(before)>.05:
   s.laser=.2;s.laser_target=app.player;app.hint("红灯移动！激光锁定");return
  for lane in lanes(r,s.elapsed):
   if lane.active and absf(app.player.x-lane.x)<22 and app.player.y>64:
    app.die("停在喷火带上了，请在两道火带之间停留");return
  if app.player.x>=(r.width-3)*32 and app.player.y>64:
   s.cleared=true;app.hint("木偶试炼通过！出口开关已解锁")
 else:
  if s.phase=="prepare":
   if tile(r,app.player)<0:return
   s.timer-=dt
   if s.timer<=0:ask(s);s.phase="question";s.timer=c.answer_time
  elif s.phase=="question":
   s.timer=maxf(0,s.timer-dt)
   if s.timer<=0:
    s.phase="collapse";s.timer=1.2
    if tile(r,app.player)!=s.safe or app.air_time>0:app.die("没有站在正确数字上，地砖坠入熔岩")
  elif s.phase=="collapse":
   if tile(r,app.player)!=s.safe:app.die("离开安全数字格，坠入熔岩");return
   s.timer-=dt
   if s.timer<=0:
    s.round+=1
    if s.round>=c.rounds:s.cleared=true;app.hint("算术试炼通过！出口开关已解锁")
    else:s.phase="rest";s.timer=.9
  elif s.phase=="rest":
   s.timer-=dt
   if s.timer<=0:ask(s);s.phase="question";s.timer=c.answer_time
static func draw(app):
 var r=app.room();var type=kind(r)
 if type==TYPES[0]:return
 var live=app.playing;var s=app.runtime[app.room_index].challenge if live else state();var t=float(s.elapsed)
 var font=app.theme.default_font
 if type==TYPES[1]:
  var mode=light(r,t);var col=Color("90d1a1") if mode=="green" else Color("efbd68") if mode=="warning" else Color("ed7972")
  for lane in lanes(r,t):
   var rect=Rect2(lane.x-16,64,32,(r.height-3)*32)
   app.draw_rect(rect,Color("573e30") if not lane.active else Color("af512c"))
   app.draw_texture_rect_region(app.trap_textures["火焰箱"],Rect2(lane.x-16,32,32,48),Rect2(0,0,16,32))
   if lane.active:
    for y in range(80,(r.height-1)*32,24):app.draw_texture_rect_region(app.flame_tex,Rect2(lane.x-16,y,32,32),Rect2((int(t*10)%4)*16,0,16,16))
   elif lane.warning:app.draw_rect(rect,Color("e6b06c"),false,2)
  var boss=Vector2((r.width-3)*32,64)
  app.draw_texture_rect(BOSS,Rect2(boss-Vector2(38,48),Vector2(76,102)),false,Color("798b75") if mode=="green" else Color.WHITE)
  app.draw_rect(Rect2(38,36,190,34),Color("18201e"))
  app.draw_string(font,Vector2(48,60),"已通过 · 去按开关" if s.cleared else ("绿灯前进" if mode=="green" else "即将转身 · 停步" if mode=="warning" else "红灯 · 站住"),HORIZONTAL_ALIGNMENT_LEFT,-1,18,col)
  if s.laser>0:app.draw_line(boss+Vector2(0,-8),s.laser_target,Color("ff4c62"),5)
 else:
  var b=board(r)
  for i in range(9):
   var rect=Rect2(b.position+Vector2(i%3,int(i/3))*64,Vector2(64,64));var safe=s.phase!="collapse" or s.safe==i
   app.draw_rect(rect.grow(-2),Color("43483e") if safe else Color("a94f26"))
   if not safe:
    app.draw_rect(rect.grow(-12),Color("f2aa40"));continue
   app.draw_rect(rect.grow(-5),Color("c9b57b"),false,2)
   var number=s.numbers[i] if s.numbers.size()==9 else i+1
   app.draw_string(font,rect.position+Vector2(24,42),str(number),HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("f0dfb4"))
  var caption="进入九宫格开始答题" if s.phase=="prepare" else "%s  %.1fs"%[s.question,s.timer] if s.phase=="question" else "留在安全格，等待地板复原"
  if s.cleared:caption="算术通过 · 去按出口开关"
  app.draw_string(font,Vector2(45,62),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("e8cf92"))
