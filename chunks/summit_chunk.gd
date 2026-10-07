extends Node2D
func _ready() -> void:
	$FlagArea.body_entered.connect(_on_flag_enter)
func _on_flag_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.nearby_save_point = self
		GameState.trigger_win()
