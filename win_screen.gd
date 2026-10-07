extends CanvasLayer
func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$MenuPanel/RestartButton.pressed.connect(_on_restart)
	$MenuPanel/MainMenuButton.pressed.connect(_on_main_menu)
	GameState.win_triggered.connect(show_win)
func show_win() -> void:
	visible = true
	get_tree().paused = true
	AudioManager.play_bgm("bgm_victory")
	$MenuPanel/StatsLabel.text = "草莓：" + str(GameState.strawberries) + "\n用时：" + GameState.get_run_time_text() + "\n死亡：" + str(GameState.death_count) + " 次"
func _on_restart() -> void:
	AudioManager.play_sfx("ui_click")
	get_tree().paused = false
	GameState.start_run()
	get_tree().reload_current_scene()
func _on_main_menu() -> void:
	AudioManager.play_sfx("ui_back")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
