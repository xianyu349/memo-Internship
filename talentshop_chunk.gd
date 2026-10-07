extends Node2D
const BUBBLE_TEXTURE = preload("res://Graphics/Gameplay/shop_talent_bubble.png")
const BUBBLE_POSITIONS = [
	Vector2(150, 180),
	Vector2(256, 150),
	Vector2(362, 180),
]
var bubbles : Array = []
func _ready() -> void:
	var available = GameState.get_available_talents()
	if available.is_empty():
		LogManager.log("【天赋商店】所有天赋已满")
		return
	for i in range(BUBBLE_POSITIONS.size()):
		var key = str(available[i % available.size()])
		spawn_bubble(BUBBLE_POSITIONS[i], key)
func spawn_bubble(pos: Vector2, talent_key: String) -> void:
	var area = Area2D.new()
	area.name = "TalentBubble"
	area.position = pos
	area.set_meta("talent_key", talent_key)
	var sprite = Sprite2D.new()
	sprite.texture = BUBBLE_TEXTURE
	sprite.scale = Vector2(2, 2)
	area.add_child(sprite)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	area.add_child(shape)
	add_child(area)
	bubbles.append(area)
	area.body_entered.connect(_on_bubble_enter.bind(area))
	area.body_exited.connect(_on_bubble_exit.bind(area))
func _on_bubble_enter(body: Node2D, area: Area2D) -> void:
	if body.is_in_group("player"):
		GameState.nearby_talent_bubble = area
		if area.has_meta("talent_key"):
			var key = str(area.get_meta("talent_key"))
			if GameState.TALENTS.has(key):
				var info = GameState.TALENTS[key]
				var lv = GameState.get_talent_level(key)
				LogManager.log("按 E 升级：" + str(info["name"]) + " Lv." + str(lv) + "→" + str(lv + 1) + "（" + str(info["price"]) + " 草莓）")
func _on_bubble_exit(body: Node2D, area: Area2D) -> void:
	if not is_instance_valid(area):
		return
	if body.is_in_group("player") and GameState.nearby_talent_bubble == area:
		GameState.nearby_talent_bubble = null
func pop_bubble(popped: Area2D) -> void:
	for b in bubbles:
		if b != popped and is_instance_valid(b):
			b.queue_free()
	bubbles.clear()
	GameState.nearby_talent_bubble = null
