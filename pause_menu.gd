extends CanvasLayer
func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$MenuPanel/ContinueButton.pressed.connect(_on_continue)
	$MenuPanel/SettingsButton.pressed.connect(_on_settings)
	$MenuPanel/MainMenuButton.pressed.connect(_on_main_menu)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
func open() -> void:
	visible = true
	get_tree().paused = true
	AudioManager.play_sfx("ui_pause")
func close() -> void:
	visible = false
	get_tree().paused = false
	AudioManager.play_sfx("ui_resume")
func _on_continue() -> void:
	close()
func _on_settings() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().paused = false
	SettingsManager.return_to = "res://main_menu.tscn"
	get_tree().change_scene_to_file("res://settings.tscn")
func _on_main_menu() -> void:
	AudioManager.play_sfx("ui_back")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
