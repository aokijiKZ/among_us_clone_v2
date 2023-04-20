extends Node2D

var outlie_shader = load('res://shaders/outline.shader')
var meething = load('res://meething/meething.tscn')

var player_network_master

func _ready():
	get_node('%label').visible = false

func _input(event):
	if player_network_master == null:
		return
#	if event.is_action_pressed("report"):
#		get_node('/root/multiplayer').rpc('switch_to_meeting','emergency_call')
		
func _on_press_energency_button_area_2d_body_entered(body):
	if body.is_in_group('Player'):
		if get_tree().has_network_peer():
			if body.is_network_master():
				player_network_master = body
				get_node('%label').visible = true
				var shader_material = ShaderMaterial.new()
				shader_material.shader = outlie_shader
				shader_material.set_shader_param('outline_color',Color(1,0,0,1))
				get_node('%animated_sprite').material = shader_material

func _on_press_energency_button_area_2d_body_exited(body):
	if body.is_in_group('Player'):
		if get_tree().has_network_peer():
			if body.is_network_master():
				player_network_master = null
				get_node('%label').visible = false
				get_node('%animated_sprite').material = null

func _on_press_emergency_button_area_2d_input_event(viewport, event, shape_idx):
	if player_network_master == null:
		return
	if event is InputEventMouse and event.is_action_pressed("click"):
		get_node('/root/multiplayer').rpc('switch_to_meeting','emergency_call')
		
		
		
