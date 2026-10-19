extends RefCounted
const KINDS=["地刺","炸弹","旋转刺阵","移动锯轮","摆动刺球","伸缩长矛","箭塔","火焰箱","风扇","落石","塌落平台","弹簧"]
const SHEETS={
 "地刺":["res://art/spike.png",32,32,10],"炸弹":["res://art/bomb.png",32,32,5],
 "旋转刺阵":["res://art/traps/Trap_Spike_Run.png",32,32,4],"移动锯轮":["res://art/traps/Suriken.png",32,32,8],
 "摆动刺球":["res://art/traps/SpikeBall.png",21,21,2],"伸缩长矛":["res://art/traps/Spear.png",16,64,12],
 "箭塔":["res://art/traps/Shooter_Arrow_Trap.png",16,16,6],"火焰箱":["res://art/traps/FireBox.png",16,32,13],
 "风扇":["res://art/traps/Fan.png",16,16,16],"落石":["res://art/traps/FallingRock.png",32,32,12],
 "塌落平台":["res://art/traps/FallingPlatfrom.png",32,16,8],"弹簧":["res://art/traps/Jumper.png",16,16,12]}
const HELP={
 "地刺":"伸出时触碰致命。独立延迟可让多个地刺依次启动。", "炸弹":"靠近80px启动引信；爆炸半径86px。开门不停止引信。",
 "旋转刺阵":"原地旋转的近身刺阵，生效阶段触碰致命。", "移动锯轮":"沿方向往返移动，碰到工作中的锯片致命。",
 "摆动刺球":"围绕链条支点摆动；球体触碰致命，链条不伤人。", "伸缩长矛":"沿方向伸出，工作阶段刺中致命。",
 "箭塔":"每周期发射一支箭，墙体会阻挡箭；箭飞行时仍有危险。", "火焰箱":"工作时沿方向喷火，火焰范围内致命。",
 "风扇":"沿方向吹动玩家，可把人推向机关；墙和关闭的门挡住玩家。", "落石":"落下前显示警示圈，落地生效阶段砸中致命。",
 "塌落平台":"踩上后开始承重倒计时，随后坍塌；周期结束恢复。", "弹簧":"踩上工作中的弹簧会向指定方向跃起；不能穿墙。"}
static func known(kind: String) -> bool:return KINDS.has(kind)
static func defaults(kind: String) -> Dictionary:
 var value={"delay":0.0,"period":2.4,"active":1.08,"direction":0,"travel":2,"fuse":3.5}
 match kind:
  "移动锯轮":value.period=3.0;value.active=3.0;value.travel=2
  "摆动刺球":value.period=3.0;value.active=3.0;value.direction=1;value.travel=1
  "伸缩长矛":value.period=3.0;value.active=0.8
  "箭塔":value.period=2.5;value.active=0.4
  "火焰箱":value.period=3.0;value.active=1.2;value.travel=3
  "风扇":value.period=3.0;value.active=1.5;value.travel=3
  "落石":value.period=3.0;value.active=0.45
  "塌落平台":value.period=3.0;value.active=0.8
  "弹簧":value.period=1.5;value.active=1.5
 return value
static func settings(o: Dictionary) -> Dictionary:
 var values=defaults(o.kind)
 for key in values:values[key]=o.get(key,values[key])
 if o.kind=="地刺" and not o.has("active"):values.active=float(values.period)*0.45
 return values
static func create(kind: String,x: int,y: int,id: String) -> Dictionary:
 var o={"id":id,"kind":kind,"x":x,"y":y};o.merge(defaults(kind));return o
static func directed(kind: String) -> bool:return ["移动锯轮","摆动刺球","伸缩长矛","箭塔","火焰箱","风扇","弹簧"].has(kind)
static func ranged(kind: String) -> bool:return ["移动锯轮","摆动刺球","伸缩长矛","火焰箱","风扇","弹簧"].has(kind)
static func phase(o: Dictionary,time: float) -> Dictionary:
 var p=settings(o);var age=time-float(p.delay);var part=fposmod(maxf(0,age),float(p.period));var start=float(p.period)-float(p.active)
 return {"age":age,"part":part,"cycle":int(floor(maxf(0,age)/float(p.period))),"active":age>=0 and part>=start,"warning":age>=0 and part>=maxf(0,start-0.4) and part<start}
static func validate(o: Dictionary) -> String:
 var p=settings(o)
 for key in ["delay","period","active","fuse"]:
  var v=p[key]
  if not (v is int or v is float) or not is_finite(float(v)):return "机关时间必须是有限数字"
 if p.delay<0 or p.delay>120:return "启动延迟需0–120秒"
 if p.period<0.4 or p.period>30:return "周期需0.4–30秒"
 if p.active<0.1 or p.active>p.period:return "生效/承重时间不能大于周期，最少0.1秒"
 if p.fuse<0.3 or p.fuse>30:return "引信需0.3–30秒"
 if not (p.direction is int or p.direction is float) or p.direction!=int(p.direction) or p.direction<0 or p.direction>3:return "机关方向无效"
 if not (p.travel is int or p.travel is float) or p.travel!=int(p.travel) or p.travel<1 or p.travel>6:return "作用距离需1–6格"
 return ""
static func icon(kind: String) -> Texture2D:
 var info=SHEETS[kind];var atlas=AtlasTexture.new();atlas.atlas=load(info[0]);var index=5 if kind=="地刺" else 0
 atlas.region=Rect2(index*info[1],0,info[1],info[2]);return atlas
