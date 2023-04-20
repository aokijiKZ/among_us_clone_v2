extends Node2D

var player_network_master
var mini_game_popup = load('res://mini_game_popup/mini_game_popup.tscn')

func _ready():
	get_node('%label').visible = false

func _on_can_do_mini_game_area_2d_body_entered(body):
	if body.is_in_group('Player'):
		if get_tree().has_network_peer() and body.is_network_master():
			if (get_node("/root/multiplayer").my_role == 'good' and get_parent().name == 'good_mini_game_group') or (get_node("/root/multiplayer").my_role == 'bad' and get_parent().name == 'bad_mini_game_group'):
				if get_index() in get_node("/root/multiplayer").my_task_index_list:
					player_network_master = body
					get_node('%label').visible = true
					var shader_material = ShaderMaterial.new()
					shader_material.shader = load('res://shaders/outline.shader')
					shader_material.set_shader_param('outline_color',Color(1,0,0,1))
					get_node('%animated_sprite').material = shader_material
					get_node("/root/multiplayer").get_node('%player_group').get_node('player_'+str(get_tree().get_network_unique_id())).get_node('%way_ponit_group').get_node('way_point_'+str(get_index())).hide()

func _on_can_do_mini_game_area_2d_body_exited(body):
	if body.is_in_group('Player'):
		if get_tree().has_network_peer() and body.is_network_master() and player_network_master!= null:
			player_network_master = null
			get_node('%label').visible = false
			get_node('%animated_sprite').material = null
			if get_node("/root/multiplayer").get_node('%player_group').get_node('player_'+str(get_tree().get_network_unique_id())).get_node('%way_ponit_group').has_node('way_point_'+str(get_index())):
				get_node("/root/multiplayer").get_node('%player_group').get_node('player_'+str(get_tree().get_network_unique_id())).get_node('%way_ponit_group').get_node('way_point_'+str(get_index())).show()

func _input(event):
	if player_network_master == null:
		return
	if event is InputEventMouse and event.is_action_pressed("report"):
		popup_mini_game()

func _on_can_do_mini_game_area_2d_input_event(viewport, event, shape_idx):
	if player_network_master == null:
		return
	if event is InputEventMouse and event.is_action_pressed("click"):
		popup_mini_game()

func popup_mini_game():
	var mini_game_popup_instance = mini_game_popup.instance()
	get_node("/root/multiplayer").get_node('%mini_game_ui').add_child(mini_game_popup_instance)
	mini_game_popup_instance.popup_centered()
	mini_game_popup_instance.task_index = get_index()
	mini_game_popup_instance.mini_game_type = 'good' if get_node("/root/multiplayer").my_role == 'good' else 'bad'
	player_network_master.is_can_move = false
	yield(mini_game_popup_instance,'popup_hide')
	player_network_master.is_can_move = true
