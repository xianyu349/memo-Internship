extends Area2D

var item_key : String = ""
var has_player : bool = false

var textures = {
	"golden_feather": preload("res://Graphics/Items/golden_feather.png"),
	"wind": preload("res://Graphics/Items/wind.png"),
	"pinball": preload("res://Graphics/Items/pinball.png"),
}

func setup(key: String) -> void:
	item_key = key
	if textures.has(key):
		$Sprite2D.texture = textures[key]

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		has_player = true
		GameState.nearby_item_drop = self
		print("按 E 拾取：", GameState.ITEMS[item_key]["name"])

func _on_exit(body: Node2D) -> void:
	if body.is_in_group("player"):
		has_player = false
		if GameState.nearby_item_drop == self:
			GameState.nearby_item_drop = null
