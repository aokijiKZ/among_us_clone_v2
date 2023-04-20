extends PopupDialog


func _ready():
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("connection_failed", self, "_connection_failed")
	
	## set default name
	if OS.has_environment("USERNAME"):
		get_node('%name_line_edit').text = OS.get_environment("USERNAME")
	else:
		var desktop_path = OS.get_system_dir(0).replace("\\", "/").split("/")
		get_node('%name_line_edit').text = desktop_path[desktop_path.size() - 2]

func _on_join_button_pressed():
	Network.ip_address = get_node('%ip_line_edit').text
	Network.join_server()

func _connected_to_server():
	get_tree().change_scene("res://multiplayer.tscn")

func _connection_failed():
	printerr('connection_failed')
