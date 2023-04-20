extends CanvasLayer

onready var button_container = get_node("%VBoxContainer_button")
onready var start_button = $VBoxContainer_button/start_button
onready var effect_confirm = $sound_effect_confirm
onready var effect_focus_button = $sound_effect_focus_button

onready var setting_menu = get_node("%setting_menu")

func _ready() -> void:
# warning-ignore:return_value_discarded
	start_button.grab_focus()
	Profile.connect("data_changed",self,'_profile_data_changed')
	_profile_data_changed(Profile.data)
	
	
func _profile_data_changed(data):
	get_node('%profile_name_label').text = data.get('player_name')

func play_effect_focus_button():
	effect_focus_button.play()
	yield(effect_focus_button, "finished")

func _on_start_button_pressed() -> void:
#	get_tree().change_scene('res://network_setup/Network_setup.tscn')
	get_node("%host_menu").popup()

func _on_load_button_pressed() -> void:
	get_node("%join_menu").popup()
	
func _on_option_button_pressed() -> void:
	setting_menu.popup()

func _on_exit_button_pressed() -> void:
	get_tree().get_root().set_disable_input(true)
	effect_confirm.play()
	yield(effect_confirm, "finished")
	get_tree().quit()
	

func _on_profile_name_change_button_pressed():
	Profile.change_name_ui()
