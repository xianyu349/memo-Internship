extends Area2D

func _ready() -> void:
	body_entered.connect(_on_enter)

func _on_enter(body: Node2D) -> void:
	if body is CharacterBody2D and body.has_method("die"):
		body.die()
