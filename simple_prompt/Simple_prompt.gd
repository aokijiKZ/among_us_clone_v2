extends Control

func _on_Ok_pressed():
	
	get_tree().call_deferred('change_scene',"res://title_menu/title_menu.tscn")
	self.queue_free()
	get_tree().paused = false

func set_text(text) -> void:
	$Label.text = text
