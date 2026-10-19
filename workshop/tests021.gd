extends Node
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);print("FAIL 021 ",label)
func run(app):
 var draft=JSON.stringify(app.level)
 var outfit=app.outfit.duplicate(true)
 app.show_home()
 var classic=-1
 for i in range(app.library_entries.size()):
  if app.library_entries[i].get("runtime","")=="native080":classic=i
 check(classic>=0,"classic is a map library entry")
 app.library_list.select(classic);app.library_list.item_selected.emit(classic)
 check(app.edit_map_button.disabled,"classic editing visibly disabled")
 app.open_library_map(false)
 check(JSON.stringify(app.level)==draft and app.home.visible,"classic edit rejection preserves draft")
 check(ClassDB.class_exists("ClassicRuntime") and app.classic_runtime.bridge!=null,"native extension loaded")
 var invalid=JSON.parse_string(app.classic_runtime.bridge.run_json("invalid JSON"))
 check(invalid.error=="invalid request","malformed native request rejected")
 var absent=app.classic_runtime.request({"op":"open","window":0,"root":"/missing","records":"/missing"})
 check(not absent.active and absent.error!="","missing window fails without mutation")
 app.open_library_map(true)
 check(app.legacy_game.active and not app.classic_runtime.active,"classic starts native renderer without WebView")
 app.legacy_game.finish()
 app.classic_runtime.close();app.classic_runtime.close()
 check(not app.classic_runtime.active,"close idempotent")
 check(JSON.stringify(app.level)==draft and app.outfit==outfit,"classic does not replace workshop data or equipment")
 app.library_list.select(0);app.library_list.item_selected.emit(0)
 check(not app.edit_map_button.disabled,"workshop map editing reenabled")
 app.open_library_map(true)
 check(app.playing and app.formal_run,"ordinary map still playable")
 app.show_home()
 check(JSON.stringify(app.level)==draft,"ordinary play restores prior draft")
 check(not FileAccess.get_file_as_string("res://main.gd").contains("OS.shell_open"),"no external browser launch path")
 for file in ["index.html","index.js","style.css","assets.js"]:
  check(FileAccess.file_exists("res://demo080/"+file),"bundled classic resource "+file)
 print("021 CLASSIC INTEGRATION TESTS ",checks," checks / ",("PASS" if failures.is_empty() else str(failures)))
