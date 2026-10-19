extends SceneTree
const Model=preload("res://map_model.gd")
func _init():
 var data=Model.four_rooms()
 var issue=Model.validate(data,true)
 if issue!="":push_error(issue);quit(1);return
 var f=FileAccess.open("res://maps/four-rooms.json",FileAccess.WRITE)
 if f==null:push_error("Cannot write map");quit(1);return
 f.store_string(JSON.stringify(data,"  "));f.close()
 var lab=FileAccess.open("res://maps/trap-laboratory.json",FileAccess.WRITE)
 lab.store_string(JSON.stringify(preload("res://map_library.gd").showcase(),"  "));lab.close()
 print("Exported four-rooms.json using the editor's shape/join operations")
 quit()
