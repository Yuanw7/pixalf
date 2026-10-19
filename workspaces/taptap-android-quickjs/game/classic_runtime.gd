extends RefCounted
const EXTENSION="res://native/classic.gdextension"
var bridge: Object
var active=false
var error=""
func _init():
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
 error="实验区只使用原生 QuickJS 经典地图入口。"
 return false
func close():request({"op":"close"})
