extends Camera2D
var max_y : float = 1e18
var player : Node2D
func _ready() -> void:
	player = get_parent()
	if not GameState.player_respawned.is_connected(_on_respawn):
		GameState.player_respawned.connect(_on_respawn)
func set_follow_limit() -> void:
	max_y = player.global_position.y
func reset_limit() -> void:
	max_y = 1e18
func _process(_delta: float) -> void:
	if player == null:
		return
	var overflow = player.global_position.y - max_y
	if overflow > 0:
		position.y = -overflow
	else:
		position.y = 0
func _on_respawn() -> void:
	reset_limit()
