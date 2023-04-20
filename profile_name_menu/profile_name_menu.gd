extends PopupDialog

onready var save_name = get_node("%save_name")
onready var ok_sound = get_node("%ok_sound")
onready var cancle_sound = get_node("%cancle_sound")
onready var re_generate_name_sound = get_node("%re_generate_name_sound")
onready var focus_button_sound = get_node("%focus_button_sound")
onready var namegenaretor = load("res://profile_name_menu/name_genaretor.gd").new()

func _ready():
	save_name.grab_focus()
	save_name.text = namegenaretor.generate()
	self.popup()

func _on_ok_button_pressed():
	Profile.set_profile_data('player_name',get_node('%save_name').text)
	self.hide()
	self.queue_free()

func _on_cancle_button_pressed():
	self.hide()
	self.queue_free()

func _on_re_generate_name_button_pressed():
	get_tree().get_root().set_disable_input(true)
	self.re_generate_name_sound.play()
	yield(re_generate_name_sound, "finished")
	save_name.text = namegenaretor.generate()
	get_tree().get_root().set_disable_input(false)

func player_focus_button_sound():
	focus_button_sound.play()
	yield(focus_button_sound, "finished")
