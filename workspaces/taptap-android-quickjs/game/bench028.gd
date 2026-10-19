extends SceneTree
func _initialize():call_deferred("run")
func run():
 var app=load("res://main.tscn").instantiate();root.add_child(app)
 await process_frame
 var game=app.legacy_game;game.persist_records=false
 var results=[]
 var scenarios=[{"name":"first_room_4","stage":0,"x":400,"count":4},{"name":"bridge_start_4","x":1900,"count":4},{"name":"bridge_middle_4","x":1100,"count":4},{"name":"bridge_end_4","x":400,"count":4},{"name":"bridge_end_84","x":400,"count":84}]
 var frame_count=180
 if "--soak" in OS.get_cmdline_user_args():scenarios=[{"name":"bridge_end_60s","x":400,"count":84,"spawning":true}];frame_count=3600
 for scenario in scenarios:
  game.start_game("catacombs",app.outfit);game.frozen=true
  var source=game.simulation_source();var end=source.rfind("})();")
  source=source.substr(0,end)+FileAccess.get_file_as_string("res://test_fixtures/performance.js")+source.substr(end)
  game.runtime.bridge.run_json(JSON.stringify({"op":"sim_boot","source":source,"payload":{"op":"boot","map":"catacombs","assets":game.assets,"records":{}}}))
  var setup=scenario.duplicate();setup.op="perf_setup";game.state=game.invoke("sim_step",setup)
  var times=[];var commands=0;var bytes=0;var draw_times=[];var frame_times=[]
  for i in range(frame_count):
   var t=Time.get_ticks_usec()
   game.state=game.invoke("sim_step",{"op":"step","dt":1.0/60,"render":true})
   times.append((Time.get_ticks_usec()-t)/1000.0);commands+=game.state.commands.size()
   if i==90:bytes=JSON.stringify(game.state).length()
   game.refresh_state()
   if "--visual-bench" in OS.get_cmdline_user_args():
    await process_frame
    await RenderingServer.frame_post_draw
    draw_times.append(game.surface.last_draw_usec/1000.0)
    frame_times.append((Time.get_ticks_usec()-t)/1000.0)
  times.sort();draw_times.sort();frame_times.sort()
  var result={"scenario":scenario,"step_ms_median":times[int(frame_count*.5)],"step_ms_p95":times[int(frame_count*.95)],"commands_avg":commands/float(frame_count),"json_bytes":bytes,"counters":game.invoke("sim_step",{"op":"perf_stats"}),"frame_wall_p95":frame_times[int(frame_times.size()*.95)] if not frame_times.is_empty() else 0,"canvas_cpu_p95":draw_times[int(draw_times.size()*.95)] if not draw_times.is_empty() else 0,"gradient_cache":game.surface.gradients.size()}
  results.append(result);print(JSON.stringify(result));game.finish()
 var label="after" if "--after" in OS.get_cmdline_user_args() else "before"
 if "--soak" in OS.get_cmdline_user_args():label+="-soak"
 var file=FileAccess.open("res://../reports/028/"+label+("-visual" if "--visual-bench" in OS.get_cmdline_user_args() else "")+".json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"  "));file.close()
 quit()
