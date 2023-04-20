extends Node2D

const game_player_role := ['hamster','cavy']

var amount_bad_player := 1
var amount_task := 2

var my_task_index_list := []
var my_role := ''

var player_profile_data_dict := {}
var player_profile_data_dict_copy := {}
var no_player_list := []
var no_player_list_copy := []
var player_disconnect_during_game_list :=[]
var player_waitng_room_ready_list := []
var player_pre_game_done_config_list:= [] 
var player_pre_meeting_done_list := []
var player_meeting_vote_dict := {}
var player_end_meeting_done_list:= [] 
var player_next_round_done_list := []
var player_end_game_done_list := []
var done_good_task :int

var alive_player_list = []

var alive_good_player_list = []
var alive_bad_player_list = []

signal player_data_dict_changed(player_profile_data_dict)

var game_state := 'waiting_room'

func _ready():
	## mulitplayer config
	randomize()

	for ui in get_node('%multiplayer_ui').get_children():
		ui.visible = false
	
	get_node('%level').visible = false
	
	instance_player(get_tree().get_network_unique_id())
	for pid in get_tree().get_network_connected_peers():
		instance_player(pid)
	
	rpc("register_player", Profile.data)
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	
	
	## wating room
	self.connect("player_data_dict_changed",self,"refesh_player_item_list")
	
	if get_tree().has_network_peer() and get_tree().is_network_server():
		get_node('%ready_button').visible = false
	else:
		get_node('%start_button').visible = false
	
	get_node('%waiting_room_ui').visible = true
	refesh_player_item_list(player_profile_data_dict)
	refesh_ip_address_label()
	
	
func _process(_delta: float) -> void:
	if game_state == 'waiting_room':
		if get_tree().network_peer != null:
			# if player >=4 and is server and all player_cilent ready
			if get_tree().get_network_connected_peers().size() >= 3 and get_tree().is_network_server() and player_waitng_room_ready_list.size() >= get_tree().get_network_connected_peers().size():
				get_node('%start_button').disabled = false
			else:
				get_node('%start_button').disabled = true
	elif game_state == 'meeting':
		pass
	elif game_state == 'in_game':
		if get_tree().has_network_peer() and get_tree().is_network_server():
			if alive_bad_player_list.size() >= alive_good_player_list.size():
				print('bad player win')
				game_state = 'end_game'
				rpc('swich_to_end_game','bad_player_win')
			elif alive_bad_player_list.empty():
				print('good player win')
				game_state = 'end_game'
				rpc('swich_to_end_game','good_player_win')
			elif done_good_task >= ((get_tree().get_network_connected_peers().size() +1 -amount_bad_player) * amount_task):
				print('good task player win')
				game_state = 'end_game'
				rpc('swich_to_end_game','task_win')
	
func _player_connected(pid) -> void:
	if game_state != 'waiting_room':
		printerr("Player " + str(pid) + " has connected during game")
		if get_tree().has_network_peer() and get_tree().is_network_server():
			rpc_id(pid,'connect_on_during_game')
		return
	print("Player " + str(pid) + " has connected")
	instance_player(pid)
	rpc_id(pid, "register_player", Profile.data)

func _player_disconnected(pid) -> void:
	print("Player " + str(pid) + " has disconnected")
	if  get_node('%player_group').has_node(str(pid)):
		get_node('%player_group').get_node(str(pid)).queue_free()
	unregister_player(pid)
	if game_state != 'waiting_room':
		if not pid in player_disconnect_during_game_list:
			player_disconnect_during_game_list.append(pid)
	
	if game_state == 'meeting':
		var v_index = no_player_list_copy.find(pid)
		var v_bt = get_node('%vote_box_container').get_child(v_index)
		v_bt.text = player_profile_data_dict_copy.get(pid,{}).get('player_name','error') + ' (disconnect)'
		v_bt.disabled = true

remote func connect_on_during_game():
	if get_tree().get_rpc_sender_id() != 1:
		printerr('not call from server :connect_on_during_game')
		return
	Network.reset_network_connection()
	get_tree().change_scene("res://title_menu/title_menu.tscn")
	
sync func register_player(other_player_profile):
	var pid = get_tree().get_rpc_sender_id()
	print('register player pid: %s'%pid)
	player_profile_data_dict[pid] = other_player_profile
	no_player_list.append(pid)
	if get_tree().has_network_peer() and get_tree().is_network_server():
		rpc('update_no_player_list',no_player_list)
		
	emit_signal("player_data_dict_changed",player_profile_data_dict)

func unregister_player(pid):
	player_profile_data_dict.erase(pid)
	no_player_list.erase(pid)
	if get_tree().has_network_peer() and get_tree().is_network_server():
		rpc('update_no_player_list',no_player_list)
	emit_signal("player_data_dict_changed",player_profile_data_dict)
	
func instance_player(pid) -> void:
	var player_instance = load("res://player/Player.tscn").instance()
	player_instance.set_network_master(pid)
	get_node('%player_group').add_child(player_instance)
	player_instance.global_position = get_node("%wating_room_spawn_location_group").get_node("0").global_position
	player_instance.name = 'player_'+str(pid)
#	if pid == get_tree().get_network_unique_id():
#		player_instance.username = Profile.data.get('player_name')
	player_instance.username = Profile.data.get('player_name')


func refesh_player_item_list(player_profile_data_dict):
	get_node('%item_list').clear()
	for pid in player_profile_data_dict:
		var player_name =  player_profile_data_dict[pid].player_name
		if pid == get_tree().get_network_unique_id():
			player_name = player_name + ' (คุณ)'
		get_node('%item_list').add_item(player_name)
			
func refesh_ip_address_label():
	get_node('%ip_address_label').text = Network.ip_address

func _on_waiting_room_exit_button_pressed():
	Network.reset_network_connection()
	get_tree().change_scene("res://title_menu/title_menu.tscn")

func _on_waiting_room_ready_button_toggled(button_pressed):
	var pid = get_tree().get_network_unique_id()
	rpc("update_player_ready_list",button_pressed,pid)
			
sync func update_player_ready_list(button_pressed,pid) -> void:
	if button_pressed:
		if not player_waitng_room_ready_list.has(pid):
			player_waitng_room_ready_list.append(pid)
	else:
		if player_waitng_room_ready_list.has(pid):
			player_waitng_room_ready_list.erase(pid)

sync func update_no_player_list(server_no_player_list):
	if get_tree().get_rpc_sender_id() != 1:
		printerr('not call from server :update_no_player_list')
		return
	no_player_list = server_no_player_list
			
func _on_waiting_room_start_button_pressed():
	if get_tree().has_network_peer() and get_tree().is_network_server():
		rpc("switch_to_pre_game")
#################################################################################
#pre_game
sync func switch_to_pre_game() -> void:
	if get_tree().get_rpc_sender_id() != 1:
		printerr('not call from server :switch_to_pre_game')
		return
	
	game_state = 'pre_game'
	get_node('%pre_game_ui').visible = true
	get_tree().paused = true
	
	for dead_body in get_node('%dead_body_group').get_children():
		dead_body.queue_free()
		
	get_node('%waiting_room').visible = false
	get_node('%waiting_room_ui').visible = false
	
	player_disconnect_during_game_list.clear()
	
	get_node('%ready_button').pressed = false
	player_waitng_room_ready_list.clear()
	
	if get_tree().has_network_peer() and get_tree().is_network_server():
		server_config_pre_game()

func server_config_pre_game():
	if get_tree().has_network_peer() and get_tree().is_network_server():
		
		var level_instance = load('res://level/level_0/level_0.tscn').instance()
	
		for level in get_node('%level').get_children():
			level.queue_free()	
		get_node('%level').add_child(level_instance)
		
		alive_bad_player_list.clear()
		alive_good_player_list.clear()
		var player_list = no_player_list.duplicate(true)
		var role_list := []
		for _i in amount_bad_player:
			player_list.shuffle()
			alive_bad_player_list.append(player_list.pop_back())
		alive_good_player_list.append_array(player_list) 
		
		var in_game_spawm_point_randi_dict := {}
		in_game_spawm_point_randi_dict[1] = randi()
		for pid in get_tree().get_network_connected_peers():
			in_game_spawm_point_randi_dict[pid] = randi()
		
		var good_mini_game_group = level_instance.get_node('%good_mini_game_group')
		var bad_mini_game_group = level_instance.get_node('%bad_mini_game_group')
		var good_task_index_list = range(good_mini_game_group.get_child_count())
		var bad_task_index_list = range(bad_mini_game_group.get_child_count())
		var player_list_task_index_dict := {}
#		player_task_randi_dict[1] = randi()
		for pid in alive_good_player_list:
			var good_task_index_list_copy = good_task_index_list.duplicate(true)
			player_list_task_index_dict[pid] = [] 
			for i_task in amount_task:
				if good_task_index_list_copy.empty():
					good_task_index_list_copy = good_task_index_list.duplicate(true)
				good_task_index_list_copy.shuffle()
				player_list_task_index_dict[pid].append(good_task_index_list_copy.pop_back())
		
		for pid in alive_bad_player_list:
			player_list_task_index_dict[pid] = [] 
			for bad_i_task in bad_task_index_list:
				player_list_task_index_dict[pid].append(bad_i_task)
			
			
		rpc("pre_game", in_game_spawm_point_randi_dict,player_list_task_index_dict,alive_bad_player_list,alive_good_player_list)

sync func pre_game(in_game_spawm_point_randi_dict,player_list_task_index_dict,p_alive_bad_player_list,p_alive_good_player_list):
	
	alive_bad_player_list = p_alive_bad_player_list
	alive_good_player_list = p_alive_good_player_list
	
	no_player_list_copy = no_player_list.duplicate(true)
	player_profile_data_dict_copy = player_profile_data_dict.duplicate(true)
	
	var level_instance = load('res://level/level_0/level_0.tscn').instance()
	
	for level in get_node('%level').get_children():
		level.queue_free()	
	get_node('%level').add_child(level_instance)
	
	var in_game_spawn_location_group = level_instance.get_node("%in_game_spawn_location_group")
	for pid in in_game_spawm_point_randi_dict:
		var spawm_point = in_game_spawm_point_randi_dict[pid] % in_game_spawn_location_group.get_child_count()
		var spawn_pos = in_game_spawn_location_group.get_node(str(spawm_point)).global_position
		
		get_node('%player_group').get_node('player_'+str(pid)).global_position =spawn_pos
	
	
	
	if get_tree().get_network_unique_id() in alive_bad_player_list:
		my_role = 'bad'
		get_node('%pre_game_you_ara_label').text = 'bad'
		get_node('%player_group').get_node('player_'+str(get_tree().get_network_unique_id())).is_can_kill = true
	else:
		my_role = 'good'
		get_node('%pre_game_you_ara_label').text = 'good'
	
	my_task_index_list.clear()
	my_task_index_list = player_list_task_index_dict[get_tree().get_network_unique_id()]
	
	for task_index in my_task_index_list:
		var way_point_instance = load('res://way_point/way_point.tscn').instance()
		get_node('%player_group').get_node('player_'+str(get_tree().get_network_unique_id())).get_node('%way_ponit_group').add_child(way_point_instance)
		if my_role == 'good':
			way_point_instance.target_global_pose = level_instance.get_node('%good_mini_game_group').get_child(task_index).global_position
		else:
			way_point_instance.target_global_pose = level_instance.get_node('%bad_mini_game_group').get_child(task_index).global_position
		way_point_instance.name = 'way_point_'+str(task_index)
	rpc("done_pre_game")
	
sync func done_pre_game():
	var p_id = get_tree().get_rpc_sender_id()
	if not p_id in player_pre_game_done_config_list:
		player_pre_game_done_config_list.append(p_id)
	
	if get_tree().has_network_peer() and get_tree().is_network_server():
		if player_pre_game_done_config_list.size() >= get_tree().get_network_connected_peers().size()+1:
			rpc("post_pre_game")
	
sync func post_pre_game():
	if get_tree().get_rpc_sender_id() != 1:
		printerr('not call from server :post_configure_game')
		return
	
	yield(get_tree().create_timer(2),"timeout")
	
	get_node('%pre_game_ui').visible = false
	game_state = 'in_game'
	get_node('%level').visible = true
	get_tree().paused = false
##############################################################################
#ingame
sync func player_task_done():
	if get_tree().has_network_peer() and get_tree().is_network_server():
		print_debug('player_task_done by ',get_tree().get_rpc_sender_id())
		done_good_task = done_good_task +1
################################################################################
#meeting
sync func switch_to_meeting(report_target):
	print_debug('call by ',get_tree().get_rpc_sender_id())
	print_debug('report target ',report_target)
	get_node('%meeting_ui').visible = true
	get_tree().paused = true
	
	game_state = 'meeting'
	
	
#	if get_tree().has_network_peer() and get_tree().is_network_server():
#		server_pre_config_meeting()
#
#func server_pre_config_meeting():
#	if get_tree().has_network_peer() and get_tree().is_network_server():
#		rpc("pre_meeting")
#
#sync func pre_meeting():

	#set to defult
	get_node('%meeting_time_progress_bar').visible = true
	for v_bt in get_node('%vote_box_container').get_children():
		v_bt.text = ''
		v_bt.disabled = true
		v_bt.get_node('label').text = ''
	
	#fill data
	for pid in player_profile_data_dict_copy:
		if pid in alive_good_player_list or pid in alive_bad_player_list:
			var v_index = no_player_list_copy.find(pid)
			var v_bt = get_node('%vote_box_container').get_child(v_index)
			v_bt.text = player_profile_data_dict_copy.get(pid,{}).get('player_name','error')
			v_bt.get_node('label').text = ''
			v_bt.disabled = false
		else:
			var v_index = no_player_list_copy.find(pid)
			var v_bt = get_node('%vote_box_container').get_child(v_index)
			v_bt.text = player_profile_data_dict_copy.get(pid,{}).get('player_name','error') + ' (dead)'
			v_bt.disabled = true
			
	for pid in player_disconnect_during_game_list:
		var v_index = no_player_list_copy.find(pid)
		var v_bt = get_node('%vote_box_container').get_child(v_index)
		v_bt.text = player_profile_data_dict_copy.get(pid,{}).get('player_name','error') + ' (disconnect)'
		v_bt.disabled = true
	
	rpc('done_pre_meeting')

sync func done_pre_meeting():
	var p_id = get_tree().get_rpc_sender_id()
	if not p_id in player_pre_meeting_done_list:
		player_pre_meeting_done_list.append(p_id)
	
	if get_tree().has_network_peer() and get_tree().is_network_server():
		if player_pre_meeting_done_list.size() >= get_tree().get_network_connected_peers().size()+1:
			rpc("start_meeting_vote")
	
sync func start_meeting_vote():
	get_node('%meeting_timer').start()
	get_node('%meeting_ui').pause_mode = Node.PAUSE_MODE_PROCESS
	
func get_my_vote_index():
	var vote_bt = get_node('%vote_bt_skip').group.get_pressed_button()
	if vote_bt == null:
		return 'no_vote'
	var index = vote_bt.name.rsplit("_", true, 1)[1]
	return index

func _on_meeting_timer_timeout():
	var pid = get_tree().get_network_unique_id()
	if not pid in player_meeting_vote_dict:
		rpc('update_meeing_vote_dict',get_my_vote_index())

sync func update_meeing_vote_dict(vote_index):
	var pid = get_tree().get_rpc_sender_id()
	if not pid in player_meeting_vote_dict:
		player_meeting_vote_dict[pid] = vote_index
	
	if get_tree().has_network_peer() and get_tree().is_network_server():
		if player_meeting_vote_dict.size() >= get_tree().get_network_connected_peers().size()+1:
			rpc('end_meeting_vote')

sync func end_meeting_vote():
	get_node('%meeting_timer').stop()
	get_node('%meeting_time_progress_bar').visible = false
	if get_tree().get_rpc_sender_id() != 1:
		printerr('not call from server :end_meeting_vote')
		return
	
	var count_vote := {'no_vote':0,'skip':0,'0':0,'1':0,'2':0,'3':0,'4':0,'5':0,'6':0,'7':0,'8':0}
	for pid in player_meeting_vote_dict:
		count_vote[player_meeting_vote_dict[pid]] += 1
	for v_bt in get_node('%vote_bt_skip').group.get_buttons():
		var v_bt_index = v_bt.name.rsplit("_", true, 1)[1]
		v_bt.get_node('label').text = str(count_vote[v_bt_index])
	
	var max_index_vote
	for pid in count_vote:
		if max_index_vote == null:
			max_index_vote = pid
			continue
		if count_vote[pid] > count_vote[max_index_vote]:
			max_index_vote = pid
	
	var sec_max_index_vote
	for pid in count_vote:
		if pid == max_index_vote:
			continue
		if sec_max_index_vote == null:
			sec_max_index_vote = pid
			continue
		if count_vote[pid] > count_vote[sec_max_index_vote]:
			sec_max_index_vote = pid
	
	var destroy_index
	if count_vote[max_index_vote]>count_vote[sec_max_index_vote]:
		destroy_index = max_index_vote
	
	if destroy_index != null and destroy_index != 'skip' and destroy_index != 'no_vote':
		if get_tree().has_network_peer() and get_tree().is_network_server():
			rpc('kill_player_with_max_vote',no_player_list[int(max_index_vote)])
	
	
	print_debug(count_vote)
	print_debug(max_index_vote)
	print_debug(sec_max_index_vote)
	
	yield(get_tree().create_timer(2),"timeout")
	
	rpc('done_end_meeting')

sync func kill_player_with_max_vote(destroy_pid):
	if get_tree().get_rpc_sender_id() != 1:
		printerr('not call from server :kill_player_with_max_vote')
		return
	get_node('%player_group').get_node('player_'+str(destroy_pid)).rpc('destroy')

sync func done_end_meeting():
	
	var p_id = get_tree().get_rpc_sender_id()
	if not p_id in player_end_meeting_done_list:
		player_end_meeting_done_list.append(p_id)
	
	if get_tree().has_network_peer() and get_tree().is_network_server():
		if player_end_meeting_done_list.size() >= get_tree().get_network_connected_peers().size()+1:
			rpc("switch_to_next_round")

######################################################################
sync func switch_to_next_round():
	if get_tree().get_rpc_sender_id() != 1:
		printerr('not call from server :switch_to_next_round')
		return
	
	get_tree().paused = true
	get_node('%next_round_ui').visible = true
	
	for dead_body in get_node('%dead_body_group').get_children():
		dead_body.queue_free()
	
	player_meeting_vote_dict.clear()
	player_pre_meeting_done_list.clear()
	get_node('%meeting_ui').visible = false
	get_node('%meeting_ui').pause_mode = Node.PAUSE_MODE_INHERIT
	
	if get_tree().has_network_peer() and get_tree().is_network_server():
		server_pre_config_next_round()

func server_pre_config_next_round():
	if get_tree().has_network_peer() and get_tree().is_network_server():
		
		var in_game_spawm_point_randi_dict := {}
		in_game_spawm_point_randi_dict[1] = randi()
		for pid in get_tree().get_network_connected_peers():
			in_game_spawm_point_randi_dict[pid] = randi()
		rpc("next_round", in_game_spawm_point_randi_dict)

sync func next_round(in_game_spawm_point_randi_dict):
	var in_game_spawn_location_group = get_node("%level").get_child(0).get_node("%in_game_spawn_location_group")
	for pid in in_game_spawm_point_randi_dict:
		var spawm_point = in_game_spawm_point_randi_dict[pid] % in_game_spawn_location_group.get_child_count()
		var spawn_pos = in_game_spawn_location_group.get_node(str(spawm_point)).global_position
		get_node('%player_group').get_node('player_'+str(pid)).global_position = spawn_pos
	rpc("done_next_round")


sync func done_next_round():
	var p_id = get_tree().get_rpc_sender_id()
	if not p_id in player_next_round_done_list:
		player_next_round_done_list.append(p_id)
	
	if get_tree().has_network_peer() and get_tree().is_network_server():
		if player_next_round_done_list.size() >= get_tree().get_network_connected_peers().size()+1:
			rpc("post_next_round")
	
sync func post_next_round():
	get_node('%next_round_ui').visible = false
	game_state = 'in_game'
	get_node('%level').visible = true
	get_tree().paused = false
	
#############################################
sync func swich_to_end_game(who_win):
	if get_tree().get_rpc_sender_id() != 1:
		printerr('not call from server :swich_to_end_game')
		return
	
	game_state = 'end_game'
	if who_win == 'bad_player_win':
		get_node('%end_game_label').text = 'bad player win'
	elif who_win == 'good_player_win':
		get_node('%end_game_label').text = 'good player win'
	get_node('%end_game_ui').visible = true
	get_tree().paused = true
	
	yield(get_tree().create_timer(5),"timeout")
	rpc('done_end_game')


sync func done_end_game():
	var p_id = get_tree().get_rpc_sender_id()
	if not p_id in player_end_game_done_list:
		player_end_game_done_list.append(p_id)
	
	if get_tree().has_network_peer() and get_tree().is_network_server():
		if player_end_game_done_list.size() >= get_tree().get_network_connected_peers().size()+1:
			rpc("swich_to_waiting_room")

###################################################
sync func swich_to_waiting_room():
	if get_tree().get_rpc_sender_id() != 1:
		printerr('not call from server :swich_to_waiting_room')
		return
	
	game_state = 'waiting_room'
	get_node('%end_game_label').text = ''
	get_node('%end_game_ui').visible = false
	get_node('%level').visible = false
	for level in get_node('%level').get_children():
		level.queue_free()
	for dead_body in get_node('%dead_body_group').get_children():
		dead_body.queue_free()
	for player in get_node('%player_group').get_children():
		player.rpc('revive')
		player.is_can_kill = false
	for way_point in get_tree().get_nodes_in_group('way_point'):
		way_point.queue_free()
	get_node('%ready_button').pressed = false
	player_waitng_room_ready_list.clear()
	get_node('%start_button').disabled = true
	get_node('%waiting_room').visible = true
	get_node('%waiting_room_ui').visible = true
	
	get_tree().paused = false

## voice chat

remote func update_rec_data(rec_data):
	var sample = AudioStreamSample.new()
	sample.data = rec_data
	sample.format = AudioStreamSample.FORMAT_16_BITS
	sample.mix_rate = AudioServer.get_mix_rate()*2
	get_node('%player_group').get_node('player_'+str(get_tree().get_rpc_sender_id())).get_node('%listen_audio_stream_player_2d').stream = sample
	get_node('%player_group').get_node('player_'+str(get_tree().get_rpc_sender_id())).get_node('%listen_audio_stream_player_2d').play()

func _on_send_recording_timer_timeout():
	if get_tree().has_network_peer():
		if is_network_master():
			if get_tree().get_network_connected_peers().size() > 0:
				var recording  = AudioServer.get_bus_effect(AudioServer.get_bus_index("Record"),0).get_recording()
				AudioServer.get_bus_effect(AudioServer.get_bus_index("Record"),0).set_recording_active(false)
				if recording != null:
					rpc("update_rec_data",recording.data)
				AudioServer.get_bus_effect(AudioServer.get_bus_index("Record"),0).set_recording_active(true)
