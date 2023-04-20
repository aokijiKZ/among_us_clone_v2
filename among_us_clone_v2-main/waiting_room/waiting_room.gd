extends Node2D

var player = load("res://player/Player.tscn")

var current_spawn_location_instance_number = 1
var current_player_for_spawn_location_number = null

var player_ready_list := []

func _ready():
	instance_player(get_tree().get_network_unique_id())
	for p_id in get_tree().get_network_connected_peers():
		instance_player(p_id)
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	Network.connect("other_player_data_dict_changed",self,"refesh_player_item_list")
	if get_tree().network_peer != null:
		if get_tree().is_network_server():
			get_node('%ready_button').visible = false
		else:
			get_node('%start_button').visible = false
	refesh_player_item_list(Network.other_player_data_dict)
	refesh_ip_address_label()
	
	
func _player_connected(id) -> void:
	print("Player " + str(id) + " has connected")
	instance_player(id)


func _player_disconnected(id) -> void:
	print("Player " + str(id) + " has disconnected")
	if  get_node('%player_group').has_node(str(id)):
		get_node('%player_group').get_node(str(id)).queue_free()

func instance_player(id) -> void:
	var player_instance = Global.instance_node_at_location(player, get_node('%player_group'), get_node("%spawn_location_group").get_node("0").global_position)
	player_instance.name = str(id)
	player_instance.set_network_master(id)
	if id == get_tree().get_network_unique_id():
		player_instance.username = Profile.data.get('player_name')
	current_spawn_location_instance_number += 1

func refesh_player_item_list(other_player_data_dict):
	get_node('%item_list').clear()
	get_node('%item_list').add_item(Profile.data.player_name+str('(คุณ)'))
	for pid in other_player_data_dict:
		var player_name =  other_player_data_dict[pid].player_name
		get_node('%item_list').add_item(player_name)
			
func refesh_ip_address_label():
	get_node('%ip_address_label').text = Network.ip_address

func _process(_delta: float) -> void:
	if get_tree().network_peer != null:
		if get_tree().get_network_connected_peers().size() >= 1 and get_tree().is_network_server() and player_ready_list.size() >= get_tree().get_network_connected_peers().size():
			get_node('%start_button').disabled = false
		else:
			get_node('%start_button').disabled = true

func _on_start_button_pressed():
	if get_tree().has_network_peer() and get_tree().is_network_server():
		rpc("switch_to_pre_game")

remotesync func switch_to_pre_game() -> void:
#	get_tree().call_deferred('change_scene',"res://pre_game/pre_game.tscn")
	var pre_game_instance = load("res://pre_game/pre_game.tscn").instance()
	get_tree().get_root().add_child(pre_game_instance)
	self.hide()
	yield(get_tree().create_timer(1),"timeout")
	self.queue_free()

func _on_exit_button_pressed():
	Network.reset_network_connection()
	get_tree().change_scene("res://title_menu/title_menu.tscn")

func _on_ready_button_toggled(button_pressed):
	var p_id = get_tree().get_network_unique_id()
	rpc("update_player_ready_list",button_pressed,p_id)
			
remote func update_player_ready_list(button_pressed,p_id) -> void:
	if button_pressed:
		if not player_ready_list.has(p_id):
			player_ready_list.append(p_id)
	else:
		if player_ready_list.has(p_id):
			player_ready_list.erase(p_id)
