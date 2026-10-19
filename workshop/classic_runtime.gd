extends RefCounted
const EXTENSION="res://native/classic.gdextension"
var bridge: Object
var active=false
var error=""
func _init():
 if OS.get_name()!="macOS":error="此版本经典地图的内置运行器仅支持macOS。";return
 if not ClassDB.class_exists("ClassicRuntime"):
  var result=GDExtensionManager.load_extension(EXTENSION)
  if result!=GDExtensionManager.LOAD_STATUS_OK and result!=GDExtensionManager.LOAD_STATUS_ALREADY_LOADED:error="无法加载经典地图运行器。";return
 bridge=ClassDB.instantiate("ClassicRuntime")
func request(args: Dictionary) -> Dictionary:
 if bridge==null:return {"active":false,"error":error}
 var result=JSON.parse_string(bridge.run_json(JSON.stringify(args)))
 if not result is Dictionary:return {"active":false,"error":"运行器返回无效状态"}
 active=result.get("active",false);error=result.get("error","");return result
func open() -> bool:
 if DisplayServer.get_name()=="headless":error="无窗口环境不能显示经典地图。";return false
 var result=request({"op":"open","window":DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE),"root":ProjectSettings.globalize_path("res://demo080"),"records":ProjectSettings.globalize_path("user://classic080-records.json")})
 return result.get("active",false) and error==""
func close():request({"op":"close"})
