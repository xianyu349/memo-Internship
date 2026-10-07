extends Area2D
@export var target_size : float = 32.0
var is_following : bool = false
var player : Node2D = null
var follow_index : int = 0
var source_global_position : Vector2 = Vector2.ZERO
var source_col : int = 0
var source_level : int = 0
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	fit_sprite()
func fit_sprite() -> void:
	for child in get_children():
		if child is Sprite2D and child.texture != null:
			var s = child.texture.get_size()
			if s.x > 0 and s.y > 0:
				var ratio = target_size / max(s.x, s.y)
				child.scale = Vector2(ratio, ratio)
func _process(_delta: float) -> void:
	if not is_following:
		return
	if player == null or not is_instance_valid(player):
		return
	var offset = Vector2(-25 - follow_index * 18, -25)
	global_position = player.global_position + offset
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if is_following:
		return
	if GameState.has_strawberry_can():
		GameState.strawberries += 1
		LogManager.log("草莓 +1（罐头）共 " + str(GameState.strawberries))
		AudioManager.play_sfx("sfx_strawberry")
		queue_free()
		return
	is_following = true
	player = body
	follow_index = GameState.following_strawberries.size()
	GameState.following_strawberries.append(self)
	LogManager.log("草莓跟随中")
	AudioManager.play_sfx("sfx_strawberry_touch")
func collect() -> void:
	if not is_following:
		return
	is_following = false
	GameState.strawberries += 1
	GameState.following_strawberries.erase(self)
	LogManager.log("草莓 +1 共 " + str(GameState.strawberries))
	AudioManager.play_sfx("sfx_strawberry")
	queue_free()
func return_to_source() -> void:
	if not is_following:
		return
	is_following = false
	global_position = source_global_position
	GameState.following_strawberries.erase(self)
	LogManager.log("草莓返回原位")
