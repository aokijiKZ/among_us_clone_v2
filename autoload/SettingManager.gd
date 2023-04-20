extends Node

const SETTING_PATH = "user://setting.setting"

func _ready():
	self.load_setting_from_file()

func save_setting_to_file():
	var setting = {
		"music_volume":AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Music')),
		"effect_volume":AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Effect')),
		"dialog_volume":AudioServer.get_bus_volume_db(AudioServer.get_bus_index('Effect')),
		"window_size":OS.get_window_size(),
		"window_fullscreen":OS.window_fullscreen
	}
	var setting_file = File.new()
	setting_file.open(SETTING_PATH, File.WRITE)
	setting_file.store_string(var2str(setting))
	setting_file.close()

func load_setting_from_file():
	var setting_file = File.new()
	if not setting_file.file_exists(SETTING_PATH):
		return
	setting_file.open(SETTING_PATH, File.READ)
	var setting_text = setting_file.get_as_text()
	setting_file.close()
	var setting = str2var(setting_text)
	
	OS.set_window_size(setting["window_size"])
	OS.window_fullscreen = setting["window_fullscreen"]
	# volume 0 is normal
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Music'),setting.get("music_volume",0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Effect'),setting.get("effect_volume",0))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index('Dialog'),setting.get("dialog_volume",0))
	
func _exit_tree():
	self.save_setting_to_file()
	
