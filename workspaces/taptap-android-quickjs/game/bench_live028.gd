extends SceneTree
func _initialize():call_deferred("run")
func run():
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 await process_frame
 var game=app.legacy_game;game.persist_records=false
 var results=[]
 for scenario in [{"optimized":false,"visible":false},{"optimized":true,"visible":false},{"optimized":false,"visible":true},{"optimized":true,"visible":true}]:
  var optimized=scenario.optimized
  game.start_game("catacombs",app.outfit);game.frozen=true
  var source=game.simulation_source()
  if not optimized:source=source.replace(FileAccess.get_file_as_string("res://performance_extension.js"),"")
  var end=source.rfind("})();");source=source.substr(0,end)+FileAccess.get_file_as_string("res://test_fixtures/performance.js")+source.substr(end)
  game.runtime.bridge.run_json(JSON.stringify({"op":"sim_boot","source":source,"payload":{"op":"boot","map":"catacombs","assets":game.assets,"records":{}}}))
  game.state=game.invoke("sim_step",{"op":"perf_setup","stage":3,"x":400,"count":84,"visible":scenario.visible});game.refresh_state()
  await process_frame
  game.frozen=true;game.set_process(false);game.frame_budget=0
  var start=Time.get_ticks_usec();var previous=start;var deltas=[];var costs=[];var backlogs=[];var draws=[];var last_step=Time.get_ticks_usec()
  while Time.get_ticks_usec()-start<6000000:
   await process_frame
   var step_time=Time.get_ticks_usec();game.frozen=false;game._process((step_time-last_step)/1000000.0);game.frozen=true;last_step=step_time
   var now=Time.get_ticks_usec()
   if now-start>1000000:
    deltas.append((now-previous)/1000.0);costs.append(game.elapsed_cost/1000.0);backlogs.append(game.frame_budget);draws.append(game.surface.last_draw_usec/1000.0)
   previous=now
  game.frozen=true
  var wall=(Time.get_ticks_usec()-start)/1000000.0
  var sum=0.0
  for d in deltas:sum+=d
  deltas.sort();costs.sort();backlogs.sort();draws.sort()
  var result={"visible_stress":scenario.visible,"optimized":optimized,"wall_seconds":wall,"simulated_seconds":game.state.time-180,"fps":1000.0/(sum/deltas.size()),"frame_ms_p95":deltas[int(deltas.size()*.95)],"frame_ms_max":deltas.back(),"simulation_batch_ms_p95":costs[int(costs.size()*.95)],"canvas_ms_p95":draws[int(draws.size()*.95)],"backlog_seconds_max":backlogs.back(),"enemies":game.state.enemies.size(),"mode":game.state.mode}
  print(JSON.stringify(result));results.append(result)
  if optimized:root.get_texture().get_image().save_png("res://../reports/028/bridge-visible.png" if scenario.visible else "res://../reports/028/bridge.png")
  game.finish()
 var file=FileAccess.open("res://../reports/028/live.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"  "));file.close();quit()
