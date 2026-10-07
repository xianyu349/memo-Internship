extends Node2D
const ITEM_TEXTURES = {
	"golden_feather": preload("res://Graphics/Items/golden_feather.png"),
	"wind": preload("res://Graphics/Items/wind.png"),
	"pinball": preload("res://Graphics/Items/pinball.png"),
}
func _ready() -> void:
	var keys = GameState.ITEMS.keys()
	var key = keys[randi() % keys.size()]
	spawn_item(key)
func get_item_display_name(key: String) -> String:
	if GameState.ITEMS.has(key):
		var info = GameState.ITEMS[key]
		if info is Dictionary and info.has("name"):
			return str(info["name"])
	return key
func spawn_item(item_key: String) -> void:
	var area = Area2D.new()
	area.name = "ItemDrop"
	area.position = Vector2(256, 180)
	area.set_meta("item_key", item_key)
	var sprite = Sprite2D.new()
	if ITEM_TEXTURES.has(item_key):
		var tex = ITEM_TEXTURES[item_key]
		sprite.texture = tex
		var tex_size = tex.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var s = 48.0 / max(tex_size.x, tex_size.y)
			sprite.scale = Vector2(s, s)
	area.add_child(sprite)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_item_enter.bind(area))
	area.body_exited.connect(_on_item_exit.bind(area))
func _on_item_enter(body: Node2D, area: Area2D) -> void:
	if body.is_in_group("player"):
		GameState.nearby_item_drop = area
		if area.has_meta("item_key"):
			var key = str(area.get_meta("item_key"))
			LogManager.log("按 E 拾取：" + get_item_display_name(key))
func _on_item_exit(body: Node2D, area: Area2D) -> void:
	if not is_instance_valid(area):
		return
	if body.is_in_group("player") and GameState.nearby_item_drop == area:
		GameState.nearby_item_drop = null
