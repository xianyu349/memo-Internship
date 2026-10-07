extends Node2D
var is_lit : bool = false
@export var texture_unlit : Texture2D
@export var texture_lit : Texture2D
func _ready() -> void:
	$Area2D.body_entered.connect(_on_enter)
	$Area2D.body_exited.connect(_on_exit)
	$Area2D/CheckpointActive.texture = texture_unlit
func get_respawn_position() -> Vector2:
	if has_node("RespawnPoint"):
		return $RespawnPoint.global_position
	return global_position
func _on_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.nearby_save_point = self
		if not is_lit:
			is_lit = true
			$Area2D/CheckpointActive.texture = texture_lit
func _on_exit(body: Node2D) -> void:
	if body.is_in_group("player") and GameState.nearby_save_point == self:
		GameState.nearby_save_point = null
