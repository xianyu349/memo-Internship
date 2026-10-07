extends Area2D

func _ready() -> void:
	body_entered.connect(_on_enter)

func _on_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameState.strawberries += 1
		print("草莓：", GameState.strawberries)
		queue_free()
