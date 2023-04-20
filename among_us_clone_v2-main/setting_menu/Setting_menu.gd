extends PopupDialog



func _ready():
#	self.popup()
	get_node("%WindowFullscreenCheckBox").grab_focus()
	setup_window_full_screen_label()
	setup_window_size_label()
	setup_music_volume_label()
	setup_effect_volume_label()

func setup_window_full_screen_label():
	var checkbox = get_node("%WindowFullscreenCheckBox")
	checkbox.pressed = OS.window_fullscreen

func setup_window_size_label():
	var size = OS.window_size
	var optionButton = get_node("%WindowSizeOptionButton")
	var option_index = window_size_to_option_index(size)
	optionButton.select(option_index)

func setup_music_volume_label():
	var music_volume_slider = get_node("%MusicVolumeSlider")
	var current_music_volume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Music'))
	music_volume_slider.value = volume_db_to_scale_volume(current_music_volume)

func setup_effect_volume_label():
	var effect_volume_slider = get_node("%EffectVolumeSlider")
	var current_effect_volume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Effect'))
	effect_volume_slider.value = volume_db_to_scale_volume(current_effect_volume)

func setup_dialog_volume_label():
	var dialog_volume_slider = get_node("%DialogVolumeSlider")
	var current_dialog_volume = AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Dialog'))
	dialog_volume_slider.value = volume_db_to_scale_volume(current_dialog_volume)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_exitButton_pressed()

func scale_volume_to_volume_db(value_rescale):
	var volume_db = (value_rescale-100)/(-100)*-50
	return volume_db

func volume_db_to_scale_volume(volume_db):
	var value_rescale = ((volume_db/-50)*-100)+100
	return value_rescale
	
func window_size_to_option_index(window_size:Vector2):
	var index
	match window_size:
		Vector2(640, 360):  # 648×648 (1:1)
			index = 0
		Vector2(640, 480):  # 640×480 (4:3)
			index = 1
		Vector2(720, 480):  # 720×480 (3:2)
			index = 2
		Vector2(800, 600):  # 800×600 (4:3)
			index = 3
		Vector2(1152, 648):  # 1152×648 (16:9)
			index = 4
		Vector2(1280, 720):  # 1280×720 (16:9)
			index = 5
		Vector2(1280, 800):  # 1280×800 (16:10)
			index = 6
		Vector2(1680, 720):  # 1680×720 (21:9)
			index = 7
	return index if index !=null else 8

func _on_window_base_size_item_selected(index):
	var window_size:Vector2
	match index:
		0:  # 648×648 (1:1)
			window_size = Vector2(640, 360)
		1:  # 640×480 (4:3)
			window_size = Vector2(640, 480)
		2:  # 720×480 (3:2)
			window_size = Vector2(720, 480)
		3:  # 800×600 (4:3)
			window_size = Vector2(800, 600)
		4:  # 1152×648 (16:9)
			window_size = Vector2(1152, 648)
		5:  # 1280×720 (16:9)
			window_size = Vector2(1280, 720)
		6:  # 1280×800 (16:10)
			window_size = Vector2(1280, 800)
		7:  # 1680×720 (21:9)
			window_size = Vector2(1680, 720)
	
	OS.set_window_size(window_size)
	


func _on_HSlider_music_value_changed(value: float) -> void:
	var volume_db = scale_volume_to_volume_db(value)
	var music_index = AudioServer.get_bus_index('Music')
	AudioServer.set_bus_volume_db(music_index,volume_db)
	var music_value_label = get_node("%MusicVolumeValue")
	music_value_label.text = str(value)
	

func _on_HSlider_efftect_value_changed(value: float) -> void:
	var volume_db = scale_volume_to_volume_db(value)
	var Effect_index = AudioServer.get_bus_index('Effect')
	AudioServer.set_bus_volume_db(Effect_index,volume_db)
	var Effect_value_label = get_node("%EffectVolumeValue")
	Effect_value_label.text = str(value)
	var test_effect = get_node("%test_effect")
	if(!test_effect.playing):
		test_effect.play()
		
func _on_HSlider_dialog_value_changed(value: float) -> void:
	var volume_db = scale_volume_to_volume_db(value)
	var dialog_index = AudioServer.get_bus_index('Dialog')
	AudioServer.set_bus_volume_db(dialog_index,volume_db)
	var dialog_value_label = get_node("%DialogVolumeValue")
	dialog_value_label.text = str(value)
	var test_dialog = get_node("%test_dialog")
	if(!test_dialog.playing):
		test_dialog.play()
	
func _on_checkBox_toggled(button_pressed: bool) -> void:
	OS.window_fullscreen = button_pressed
	var windowSizeOption = get_node("%WindowSizeOptionButton")
	windowSizeOption.disabled = button_pressed
	_on_window_base_size_item_selected(0)
	get_node("%WindowSizeOptionButton").select(0)

func _on_exitButton_pressed() -> void:
	SettingManager.save_setting_to_file()
	self.hide()
