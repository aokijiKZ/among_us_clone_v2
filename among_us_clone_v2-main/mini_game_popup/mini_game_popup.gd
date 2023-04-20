extends base_mini_game

var task_index :int
var mini_game_type := ''

func _on_button_pressed():
	emit_signal('mini_game_complate')
	if mini_game_type == 'good':
		get_node("/root/multiplayer").rpc_id(1,'player_task_done')
	get_node("/root/multiplayer").my_task_index_list.erase(task_index)
	get_node("/root/multiplayer").get_node('%player_group').get_node('player_'+str(get_tree().get_network_unique_id())).get_node('%way_ponit_group').get_node('way_point_'+str(task_index)).queue_free()
	hide()
	queue_free()


