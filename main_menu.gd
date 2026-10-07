extends Control
func _ready() -> void:
	AudioManager.play_bgm("bgm_menu")
	$MenuButtons/StartButton.pressed.connect(_on_start)
	$MenuButtons/EndlessButton.pressed.connect(_on_endless)
	$MenuButtons/SettingsButton.pressed.connect(_on_settings)
	$MenuButtons/QuitButton.pressed.connect(_on_quit)
func _on_start() -> void:
	AudioManager.play_sfx("ui_click")
	GameState.start_normal_run()
	LogManager.clear()
	get_tree().change_scene_to_file("res://地图.tscn")
func _on_endless() -> void:
	AudioManager.play_sfx("ui_click")
	GameState.start_endless_run()
	LogManager.clear()
	get_tree().change_scene_to_file("res://地图.tscn")
func _on_settings() -> void:
	AudioManager.play_sfx("ui_click")
	SettingsManager.return_to = "res://main_menu.tscn"
	get_tree().change_scene_to_file("res://settings.tscn")
func _on_quit() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().quit()
