extends CanvasLayer

var player = load("res://player/Player.tscn")

var player_ready_to_start_list := []

func _ready():
	randomize()
	get_tree().paused = true
	
	if get_tree().network_peer != null:
		if get_tree().is_network_server():
			var spawm_point_randi_dict := {}
			spawm_point_randi_dict[1] = randi()
			for p_id in get_tree().get_network_connected_peers():
				spawm_point_randi_dict[p_id] = randi()
			
			rpc("pre_configure_game", spawm_point_randi_dict)
	
sync func pre_configure_game(spawm_point_randi_dict):
	var level = load('res://level/level_0/level_0.tscn').instance()
	get_tree().get_root().add_child(level)
	
	var player_group = level.get_node('%player_group')
	var spawn_location_group = level.get_node("%spawn_location_group")
	for p_id in spawm_point_randi_dict:
		var  spawm_point = spawm_point_randi_dict[p_id] % spawn_location_group.get_child_count()
		var spawn_pos = spawn_location_group.get_node(str(spawm_point)).position
		
		var player_instance = Global.instance_node_at_location(player, player_group, spawn_pos)
		player_instance.name = str(p_id)
		player_instance.set_network_master(p_id)
		if p_id == get_tree().get_network_unique_id():
			player_instance.username = Profile.data.get('player_name')
			
	rpc("done_preconfiguring")
	
sync func done_preconfiguring():
	var p_id = get_tree().get_rpc_sender_id()
	if not p_id in player_ready_to_start_list:
		player_ready_to_start_list.append(p_id)

	if player_ready_to_start_list.size() == get_tree().get_network_connected_peers().size():
		rpc("post_configure_game")
		
sync func post_configure_game():
	if 1 == get_tree().get_rpc_sender_id():
		get_tree().paused = false
		yield(get_tree().create_timer(0.5),"timeout")
		self.queue_free()
