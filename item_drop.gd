extends Node2D

const BUBBLE_TEXTURE = preload("res://Graphics/Gameplay/shop_item_bubble.png")

const BUBBLE_POSITIONS = [
	Vector2(150, 180),
	Vector2(256, 150),
	Vector2(362, 180),
]

func _ready() -> void:
	print("【商店】_ready 执行")
	var keys = GameState.ITEMS.keys()
	if keys.is_empty():
		print("【商店】错误：GameState.ITEMS 是空的")
		return
	keys.shuffle()
	for i in range(BUBBLE_POSITIONS.size()):
		var item_key = str(keys[i % keys.size()])
		print("【商店】生成泡泡 ", i, " 道具：", item_key)
		spawn_bubble(BUBBLE_POSITIONS[i], item_key)

func spawn_bubble(pos: Vector2, item_key: String) -> void:
	var area = Area2D.new()
	area.name = "ShopBubble"
	area.position = pos
	area.set_meta("item_key", item_key)
	
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
	area.body_entered.connect(_on_bubble_enter.bind(area))
	area.body_exited.connect(_on_bubble_exit.bind(area))

func _on_bubble_enter(body: Node2D, area: Area2D) -> void:
	if body.is_in_group("player"):
		GameState.nearby_shop_bubble = area
		if area.has_meta("item_key"):
			var key = str(area.get_meta("item_key"))
			print("按 E 购买：", GameState.get_item_display_name(key), "（1 草莓）")

func _on_bubble_exit(body: Node2D, area: Area2D) -> void:
	if not is_instance_valid(area):
		return
	if body.is_in_group("player") and GameState.nearby_shop_bubble == area:
		GameState.nearby_shop_bubble = null
