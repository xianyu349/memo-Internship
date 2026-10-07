extends Area2D

func _ready() -> void:
	body_entered.connect(_on_flag_enter)

func _on_flag_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("到达山顶！")
