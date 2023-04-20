extends PopupDialog

var by_who setget set_by_who
var player_vote_dict := {}

func _ready():
	if get_tree().network_peer != null:
		if get_tree().is_network_server():
			var box_position_dict := {}
			box_position_dict[1] = 0
			var index = 1
			for p_id in get_tree().get_network_connected_peers():
				box_position_dict[p_id] = index
				index = index + 1
			
			rpc("update_player_box", box_position_dict)
	
	get_node('%-1').group.connect("pressed",self,'_on_meeting_buttongroup_pressed')
	
#	yield(get_tree(),"idle_frame")
#	self.popup()
	
func _process(delta):
	if get_node('%timer').time_left >0:
		get_node('%time_progress_bar').value = (get_node('%timer').time_left / get_node('%timer').wait_time)*100

sync func update_player_box(box_position_dict):
	for pid in box_position_dict:
		var bt = get_node('%player_box_grid_container').get_child(box_position_dict[pid])
		if pid == get_tree().get_network_unique_id():
			bt.text = Profile.data.get('player_name')
		else:
			bt.text = Network.other_player_data_dict.get(pid).get('player_name')
	
	for bt in get_node('%player_box_grid_container').get_children().slice(box_position_dict.size(),get_node('%player_box_grid_container').get_child_count()):
		bt.disabled = true
	
func _on_timer_timeout():
	if get_tree().get_network_unique_id() in player_vote_dict:
		return
	var bt = get_node('%-1').group.get_pressed_button()
	var index = int(bt.name)
	rpc("update_player_vote_dict",index)
		
sync func end_meeting():
	get_node('%timer').stop()
	print_debug(player_vote_dict)
	var count_vote := {-1:0,0:0,1:0,2:0,3:0,4:0,5:0,6:0,7:0,8:0}
	for pid in player_vote_dict:
		count_vote[player_vote_dict[pid]] += 1
	for box in get_node('%player_box_grid_container').get_children():
		box.get_node('label').text = str(count_vote[int(box.name)])
	yield(get_tree().create_timer(2),"timeout")
	get_tree().paused = false
	self.hide()
	yield(get_tree().create_timer(0.1),"timeout")
	self.queue_free()

func _on_meeting_buttongroup_pressed(bt):
	var index = int(bt.name)
	var confrim_dialog = ConfirmationDialog.new()
	add_child(confrim_dialog)
	confrim_dialog.popup_centered()
	confrim_dialog.connect("confirmed",self,'_on_confirmed_vote',[index,bt],CONNECT_ONESHOT)
	
func _on_confirmed_vote(index,prees_bt):
	for bt in get_node('%-1').group.get_buttons():
		bt.disabled = true
	var shader_material = ShaderMaterial.new()
	shader_material.shader = load('res://shaders/outline.shader')
#	shader_material.set_shader_param('outline_color',Color(0,1,1,1))
	prees_bt.material = shader_material
	rpc("update_player_vote_dict",index)

sync func update_player_vote_dict(index):
	player_vote_dict[get_tree().get_rpc_sender_id()] = index
	
	if get_tree().has_network_peer() and get_tree().is_network_server():
		if player_vote_dict.size() >= get_tree().get_network_connected_peers().size()+1:
			rpc('end_meeting')
	
func set_by_who(new_by_who):
	by_who = new_by_who
	get_node('%by_who_label').text = str(by_who)

func _on_meething_about_to_show():
	get_tree().paused = true

func _on_meething_popup_hide():
	get_tree().paused = false
