extends KinematicBody2D

var dead_body = load('res://dead_body/dead_body.tscn')

const speed = 400

var velocity = Vector2(0, 0)

var username ="" setget username_set

puppet var puppet_position = Vector2(0, 0) setget puppet_position_set
puppet var puppet_velocity = Vector2()
puppet var puppet_username = "" setget puppet_username_set

onready var tween = $Tween

var is_can_move = true
var is_can_kill = false
var can_kill_player_list := [] 
var outlie_shader = load('res://shaders/outline.shader')

func _ready():
	get_tree().connect("network_peer_connected", self, "_network_peer_connected")
	
	
			
	yield(get_tree(), "idle_frame")
	if get_tree().has_network_peer():
		if is_network_master():
			get_node('/root/multiplayer').alive_player_list.append(get_network_master())
			
			get_node('%camera_2d').current = true
			var shader_material = ShaderMaterial.new()
			shader_material.shader = outlie_shader
			shader_material.set_shader_param('outline_color',Color(0,1,1,1))
			get_node('%animated_sprite').material = shader_material
			
			#rec
			AudioServer.get_bus_effect(AudioServer.get_bus_index("Record"),0).set_recording_active(true)
#			
	

func _process(delta: float) -> void:
	if get_tree().has_network_peer():
		if is_network_master() and visible:
			if is_can_move:
				var x_input = int(Input.is_action_pressed("right")) - int(Input.is_action_pressed("left"))
				var y_input = int(Input.is_action_pressed("down")) - int(Input.is_action_pressed("up"))
				
				velocity = Vector2(x_input, y_input).normalized()
				if velocity.x < 0:
					get_node('%animated_sprite').flip_h = false
					get_node('%animated_sprite').play("walk_left")
				elif  velocity.x > 0:
					get_node('%animated_sprite').flip_h = true
					get_node('%animated_sprite').play("walk_left")
				elif velocity != Vector2.ZERO:
					get_node('%animated_sprite').play("walk_left")
				else:
					get_node('%animated_sprite').play("idle_left")
				
				move_and_slide(velocity * speed)
			
			if is_can_kill:
				if not can_kill_player_list.empty():
					var shader_material = ShaderMaterial.new()
					shader_material.shader = outlie_shader
					shader_material.set_shader_param('outline_color',Color(1,0,0,1))
					can_kill_player_list[0].get_node('%animated_sprite').material = shader_material
					for c_k_p in  can_kill_player_list.slice(1,can_kill_player_list.size()):
						c_k_p.get_node('%animated_sprite').material = null
						pass
			
			if Input.is_action_just_pressed('kill'):
				if is_can_kill and not can_kill_player_list.empty():
					can_kill_player_list[0].rpc('destroy')
					global_position = can_kill_player_list[0].global_position
			
		else:
			if is_can_move:
				if not tween.is_active():
					move_and_slide(puppet_velocity * speed)
				if puppet_velocity.x < 0:
					get_node('%animated_sprite').flip_h = false
					get_node('%animated_sprite').play("walk_left")
				elif  puppet_velocity.x > 0:
					get_node('%animated_sprite').flip_h = true
					get_node('%animated_sprite').play("walk_left")
				elif puppet_velocity != Vector2.ZERO:
					get_node('%animated_sprite').play("walk_left")
				else:
					get_node('%animated_sprite').play("idle_left")
		
func puppet_position_set(new_value) -> void:
	puppet_position = new_value
	
	tween.interpolate_property(self, "global_position", global_position, puppet_position, 0.1)
	tween.start()

func username_set(new_value) -> void:
	username = new_value
	
	if get_tree().has_network_peer():
		if is_network_master():
			get_node('%player_name_label').text = username
			rset("puppet_username", username)

func puppet_username_set(new_value) -> void:
	puppet_username = new_value
	
	if get_tree().has_network_peer():
		if not is_network_master():
			username = puppet_username
			get_node('%player_name_label').text = puppet_username

func _network_peer_connected(id) -> void:
	rset_id(id, "puppet_username", username)

func _on_Network_tick_rate_timeout():
	if get_tree().has_network_peer():
		if is_network_master():
			rset_unreliable("puppet_position", global_position)
			rset_unreliable("puppet_velocity", velocity)

sync func update_global_position(global_pos):
	global_position = global_pos
	puppet_position = global_pos

sync func revive() -> void:
	visible = true
	modulate = Color(1,1,1,1)
	get_node('%collision_shape2d').disabled = false
	get_node('%kill_ability_area').get_node("collision_shape_2d").disabled = false
	
	if not get_node('/root/multiplayer').alive_player_list.has(get_network_master()):
		get_node('/root/multiplayer').alive_player_list.append(get_network_master())

sync func destroy() -> void:

	var dead_body_instance = dead_body.instance()
	get_node('/root/multiplayer').get_node('%dead_body_group').add_child(dead_body_instance)
	dead_body_instance.name = 'dead_body_'+str(get_network_master())
	dead_body_instance.global_position = global_position
	
	if get_tree().has_network_peer() and is_network_master():
		modulate = Color(1,1,1,0.5)
	else:
		visible = false
	
	get_node('%collision_shape2d').disabled = true
	get_node('%kill_ability_area').get_node("collision_shape_2d").disabled = true
	get_node('/root/multiplayer').alive_player_list.erase(get_network_master())
	get_node('/root/multiplayer').alive_good_player_list.erase(get_network_master())
	get_node('/root/multiplayer').alive_bad_player_list.erase(get_network_master())

func _exit_tree() -> void:
	get_node('/root/multiplayer').alive_player_list.erase(self)

func _on_kill_ability_area_body_entered(body):
	if body.is_in_group('Player') and (not body == self):
		if not can_kill_player_list.has(body):
			can_kill_player_list.append(body)
		
func _on_kill_ability_area_body_exited(body):
	if body.is_in_group('Player') and (not body == self):
		if can_kill_player_list.has(body):
			can_kill_player_list.erase(body)
			if get_tree().has_network_peer():
				if body.is_network_master():
					var shader_material = ShaderMaterial.new()
					shader_material.shader = outlie_shader
					shader_material.set_shader_param('outline_color',Color(0,1,1,1))
					body.get_node('%animated_sprite').material = shader_material
				else:
					body.get_node('%animated_sprite').material = null

remote func update_rec_data(rec_data):
	var sample = AudioStreamSample.new()
	sample.data = rec_data
	sample.format = AudioStreamSample.FORMAT_16_BITS
	sample.mix_rate = AudioServer.get_mix_rate()*2
	get_node('%listen_audio_stream_player_2d').stream = sample
	get_node('%listen_audio_stream_player_2d').play()
	

func _on_send_recording_timer_timeout():
	if get_tree().has_network_peer():
		if is_network_master():
			if get_tree().get_network_connected_peers().size() > 0:
				var recording  = AudioServer.get_bus_effect(AudioServer.get_bus_index("Record"),0).get_recording()
				AudioServer.get_bus_effect(AudioServer.get_bus_index("Record"),0).set_recording_active(false)
				if recording != null:
#					rpc('destroy')
					rpc("update_rec_data",recording.data)
				AudioServer.get_bus_effect(AudioServer.get_bus_index("Record"),0).set_recording_active(true)
