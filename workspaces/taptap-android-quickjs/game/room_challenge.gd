extends RefCounted
const Spatial=preload("res://room_trial.gd")
const TYPES=["普通房间","木头人","数字快答","木头人机关房","数字地砖"]
static func spatial(r: Dictionary) -> bool:return config(r).type in ["木头人机关房","数字地砖"]
const DEFAULT={"type":"普通房间","green":3.4,"warning":0.6,"red":2.6,"fuse":3.5,"rounds":3,"seconds":5.0}
static func config(r: Dictionary) -> Dictionary:
 var c=DEFAULT.duplicate();c.merge(r.get("challenge",{}),true)
 if c.type in ["木头人机关房","数字地砖"]:c.merge(Spatial.config(r),true)
 return c
static func validate(value: Variant) -> String:
 if not value is Dictionary:return "挑战配置必须为对象"
 if not TYPES.has(value.get("type","普通房间")):return "未知房间挑战"
 for key in ["green","warning","red","fuse","seconds","rounds"]:
  if not value.has(key):continue
  var v=value[key]
  if not (v is float or v is int) or not is_finite(float(v)):return "挑战时间/题数无效"
  var minimum=0.2 if key=="warning" else 1.0
  if v<minimum or v>30:return "挑战参数超出范围"
  if key=="rounds" and v!=int(v):return "题数必须为整数"
 return ""
static func fresh(r: Dictionary) -> Dictionary:
 if spatial(r):return Spatial.state()
 var s={"done":false,"elapsed":0.0,"phase":"green","motion":0.0,"bomb":-1.0,"round":0,"question_time":0.0,"question":"","answer":0,"choices":[]}
 if config(r).type=="数字快答":question(s)
 return s
static func question(s: Dictionary):
 var a=randi_range(1,15);var b=randi_range(1,9)
 var subtract=randf()<0.5
 if subtract and b>a:var swap=a;a=b;b=swap
 s.answer=a-b if subtract else a+b
 s.question="%d %s %d = ?"%[a,"−" if subtract else "+",b]
 s.choices=[s.answer,s.answer+randi_range(1,3),s.answer+randi_range(4,7)];s.choices.shuffle();s.question_time=0.0
static func answer(s: Dictionary,c: Dictionary,index: int) -> bool:
 if s.done or index<0 or index>=s.choices.size():return true
 if s.choices[index]!=s.answer:return false
 s.round+=1;s.done=s.round>=int(c.rounds)
 if not s.done:question(s)
 return true
static func phase(c: Dictionary,time: float) -> String:
 var t=fmod(time,c.green+c.warning+c.red)
 return "green" if t<c.green else ("warning" if t<c.green+c.warning else "red")
static func update(app,delta: float,before: Vector2):
 if spatial(app.room()):Spatial.update(app,delta,before);return
 var c=config(app.room());var s=app.runtime[app.room_index].challenge
 if c.type=="普通房间":return
 s.elapsed+=delta
 if c.type=="数字快答":
  if not s.done:
   s.question_time+=delta
   if s.question_time>=c.seconds:app.die("数字快答超时")
  return
 if s.done:
  s.bomb+=delta
  if s.bomb>=c.fuse and s.bomb<1000:
   s.bomb=1000
   if app.player.distance_to(s.get("goal",app.player))<150:app.die("终点炸弹爆炸，未及时撤离")
  return
 var next=phase(c,s.elapsed)
 # Count movement during a red interval, including the tick crossing its end.
 if s.phase=="red" or next=="red":
  s.motion+=app.player.distance_to(before)
  if s.motion>6:app.die("红灯移动，被守卫发现");return
 else:s.motion=0.0
 s.phase=next
 for o in app.room().objects:
  if o.kind!="开关":continue
  var door=app.Model.door_by_id(app.room(),o.link)
  if door.is_empty() or door.get("entry",false):continue
  var goal=app.cell_center([o.x,o.y])
  if app.player.distance_to(goal)<44:
   s.done=true;s.bomb=0.0;s.goal=goal;app.hint("守卫变成炸弹！按 F 开门并尽快离开。")
   return
