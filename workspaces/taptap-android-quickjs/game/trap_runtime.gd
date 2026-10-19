extends RefCounted
const Catalog=preload("res://trap_catalog.gd")
const DIRECTIONS=[Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT,Vector2.UP]
static func point(o: Dictionary) -> Vector2:return Vector2(o.x*32+16,o.y*32+16)
static func position(o: Dictionary,time: float) -> Vector2:
 var p=Catalog.settings(o);var phase=Catalog.phase(o,time);var fraction=maxf(0,phase.age)/float(p.period)
 if o.kind=="移动锯轮":return point(o)+DIRECTIONS[int(p.direction)]*float(p.travel)*32*(0.5-0.5*cos(TAU*fraction))
 if o.kind=="摆动刺球":return point(o)+DIRECTIONS[int(p.direction)].rotated(sin(TAU*fraction)*1.05)*float(p.travel)*32
 return point(o)
static func line_hit(player: Vector2,o: Dictionary,p: Dictionary,width: float=15) -> bool:
 var relative=player-point(o);var direction=DIRECTIONS[int(p.direction)]
 return relative.dot(direction)>=-12 and relative.dot(direction)<=float(p.travel)*32+10 and absf(relative.cross(direction))<=width
static func hit(app,message: String):
 if app.air_time<=0:app.die(message)
static func update(app,delta: float):
 var state=app.runtime[app.room_index]
 for o in app.room().objects:
  if not Catalog.known(o.kind):continue
  var p=Catalog.settings(o);var phase=Catalog.phase(o,state.time);var mechanism=state.mechanisms[o.id];var distance=app.player.distance_to(point(o))
  if phase.age<0:continue
  match o.kind:
   "地刺","旋转刺阵":
    if phase.active and distance<21:hit(app,"被"+o.kind+"击中")
   "炸弹":
    var remaining=float(state.bombs[o.id])
    if remaining==-1 and distance<80:state.bombs[o.id]=float(p.fuse);app.hint("炸弹引信已点燃，尽快离开！")
    elif remaining>0:
     state.bombs[o.id]=maxf(0,remaining-delta)
     if state.bombs[o.id]==0 and distance<86:hit(app,"被炸弹爆炸击中")
   "移动锯轮","摆动刺球":
    if phase.active and app.player.distance_to(position(o,state.time))<21:hit(app,"被"+o.kind+"击中")
   "伸缩长矛","火焰箱":
    if phase.active and line_hit(app.player,o,p):hit(app,"被"+o.kind+"击中")
   "箭塔":
    if phase.active and mechanism.cycle!=phase.cycle:
     mechanism.cycle=phase.cycle
     state.projectiles.append({"position":point(o),"velocity":DIRECTIONS[int(p.direction)]*240,"life":3.0})
   "风扇":
    if phase.active and line_hit(app.player,o,p,25):
     var next=app.player+DIRECTIONS[int(p.direction)]*90*delta
     if app.can_move(next):app.player=next
   "落石":
    if phase.active and distance<23:hit(app,"被落石砸中")
   "塌落平台":
    if mechanism.armed<0 and distance<22 and app.air_time<=0:mechanism.armed=0.0
    if mechanism.armed>=0:
     mechanism.armed+=delta
     if mechanism.armed>=float(p.period):mechanism.armed=-1.0
     elif mechanism.armed>=float(p.active) and distance<22:hit(app,"塌落平台坠落")
   "弹簧":
    mechanism.cooldown=maxf(0,mechanism.cooldown-delta)
    if phase.active and distance<22 and app.air_time<=0 and mechanism.cooldown==0:
     app.manual_jump=false;app.air_time=0.45;app.launch_velocity=DIRECTIONS[int(p.direction)]*float(p.travel)*32/0.45;mechanism.cooldown=float(p.period)
  if not app.alive:return
 for projectile in state.projectiles.duplicate():
  projectile.life-=delta
  var step=projectile.velocity*delta;var count=maxi(1,int(ceil(step.length()/4.0)));var remove=false
  for i in range(count):
   projectile.position+=step/count
   if not app.can_move(projectile.position):remove=true;break
   if app.player.distance_to(projectile.position)<14:hit(app,"被箭塔击中");remove=true;break
  if remove or projectile.life<=0:state.projectiles.erase(projectile)
 app.cross_door()
