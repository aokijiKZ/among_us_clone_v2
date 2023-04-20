extends PopupDialog


func _ready():
	## set default name
	if OS.has_environment("USERNAME"):
		get_node('%name_line_edit').text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		get_node('%name_line_edit').text = desktop_path[desktop_path.size() - 2]
	
func _on_host_button_pressed():
	var is_can = Network.create_server()
	if is_can:
		get_tree().change_scene("res://multiplayer.tscn")
	else:
		printerr('cant create server')
