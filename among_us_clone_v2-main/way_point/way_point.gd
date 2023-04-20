extends Node2D

var target_global_pose :Vector2

#for test
#func _input(event):
#	if event.is_action("click"):
#		target_global_pose = get_global_mouse_position()

func _process(delta):
#	if abs(global_position.distance_to(target_global_pose)) > 128*2:
#		show()
#		look_at(target_global_pose)
#	else:
#		hide()
	look_at(target_global_pose)
