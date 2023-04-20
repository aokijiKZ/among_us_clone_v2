extends Node

var data :={
	'player_name':'unname',
}

signal data_changed(data)


func _ready():
	pass
#	if data.get('player_name') == 'unname':
#		change_name_ui()


func set_profile_data(key,value):
	data[key] = value
	emit_signal("data_changed",data)

func change_name_ui():
	Global.instance_node(load('res://profile_name_menu/profile_name_menu.tscn'),GlobalUI)
