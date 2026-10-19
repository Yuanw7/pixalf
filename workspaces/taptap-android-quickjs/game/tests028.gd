extends Node
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 028 ",label)
func run(app):
 var game=app.legacy_game;game.start_game("catacombs",app.outfit)
 check(game.simulation_source().contains("floorPoint"),"collision optimization is installed")
 check(game.state.commands.any(func(c):return c[0]=="ellipse"),"compact ellipse commands reach Godot")
 var c=["ellipse",[1,0,0,1,0,0],1,"#fff",100,80,17,7,0,0,7,true,0,null]
 var points=game.surface.ellipse_points(c)
 check(points.size()==52,"same 8 samples per radian as original recorder")
 check(points[0].is_equal_approx(Vector2(17,0)) and points[-1].distance_to(points[0])<.0001,"ellipse shape closes without including world origin")
 c[8]=PI/2
 points=game.surface.ellipse_points(c)
 check(points[0].distance_to(Vector2(0,17))<.0001,"rotated ellipse preserves axes")
 c[8]=0;c[9]=-.7;c[10]=2.6
 points=game.surface.ellipse_points(c)
 check(points.size()==28 and points[0].distance_to(Vector2(cos(-.7)*17,sin(-.7)*7))<.0001,"partial attack arc keeps original samples")
 for i in range(200):c[6]=i+1;game.surface.ellipse_points(c)
 check(game.surface.ellipse_cache.size()<=128,"changing attack radii cannot grow cache forever")
 var before=game.state.time;game.command("pause");game._process(.05)
 check(game.state.time==before,"optimization retains pause behavior")
 game.command("retry");check(game.state.trial.stage==0 and game.state.heroes[0].hp==170,"retry retains checkpoint health and position")
 game.finish()
 print("028 PERFORMANCE REGRESSION ",checks," checks / ",("PASS" if failures.is_empty() else str(failures)))
