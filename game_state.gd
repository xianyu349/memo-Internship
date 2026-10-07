extends Node
signal backpack_changed
signal talents_changed
signal player_respawned
signal win_triggered
var respawn_point : Vector2 = Vector2(0, 0)
var nearby_save_point : Node2D = null
var nearby_item_drop : Node2D = null
var nearby_shop_bubble : Area2D = null
var nearby_talent_bubble : Area2D = null
var strawberries : int = 0
var item_slots : Array = [null, null, null]
var lit_save_points : Array = []
var following_strawberries : Array = []
var death_count : int = 0
var run_start_time : float = 0.0
var endless_mode : bool = false
const MAX_SLOTS = 3
const ITEM_DROP_SIZE : float = 48.0
const TALENTS = {
	"toughness": {"name": "坚韧", "price": 1, "max_level": 5, "desc": "每级 +20 体力上限"},
	"speed": {"name": "加速", "price": 1, "max_level": 5, "desc": "每级 +20 移动速度"},
	"extra_dash": {"name": "更多冲刺", "price": 3, "max_level": 3, "desc": "每级 +1 冲刺次数"},
	"strawberry_can": {"name": "草莓罐头", "price": 5, "max_level": 1, "desc": "触碰草莓立即收集"},
}
const ITEMS = {
	"golden_feather": {"name": "金羽毛", "desc": "化为光飞行 5 秒"},
	"wind": {"name": "风", "desc": "重力减半 10 秒"},
	"pinball": {"name": "弹球", "desc": "放置弹球，触碰弹开"},
}
const ITEM_TEXTURES = {
	"golden_feather": preload("res://Graphics/Items/golden_feather.png"),
	"wind": preload("res://Graphics/Items/wind.png"),
	"pinball": preload("res://Graphics/Items/pinball.png"),
}
var talent_levels : Dictionary = {
	"toughness": 0,
	"speed": 0,
	"extra_dash": 0,
	"strawberry_can": 0,
}
func reset() -> void:
	respawn_point = Vector2(0, 0)
	nearby_save_point = null
	nearby_item_drop = null
	nearby_shop_bubble = null
	nearby_talent_bubble = null
	strawberries = 0
	item_slots = [null, null, null]
	lit_save_points.clear()
	following_strawberries.clear()
	death_count = 0
	run_start_time = 0.0
	for k in talent_levels.keys():
		talent_levels[k] = 0
func start_run() -> void:
	reset()
	run_start_time = Time.get_ticks_msec() / 1000.0
func start_endless_run() -> void:
	endless_mode = true
	start_run()
func start_normal_run() -> void:
	endless_mode = false
	start_run()
func get_run_time() -> float:
	if run_start_time <= 0.0:
		return 0.0
	return Time.get_ticks_msec() / 1000.0 - run_start_time
func get_run_time_text() -> String:
	var t = int(get_run_time())
	var m = t / 60
	var s = t % 60
	return "%02d:%02d" % [m, s]
func trigger_win() -> void:
	win_triggered.emit()
func get_item_display_name(key: String) -> String:
	if ITEMS.has(key):
		var info = ITEMS[key]
		if info is Dictionary and info.has("name"):
			return str(info["name"])
	return key
func consume_item(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= item_slots.size():
		return ""
	var key = item_slots[slot_index]
	if key == null:
		return ""
	item_slots[slot_index] = null
	backpack_changed.emit()
	return str(key)
func get_talent_level(key: String) -> int:
	return int(talent_levels.get(key, 0))
func get_talent_max_level(key: String) -> int:
	if TALENTS.has(key):
		return int(TALENTS[key]["max_level"])
	return 0
func is_talent_maxed(key: String) -> bool:
	return get_talent_level(key) >= get_talent_max_level(key)
func can_upgrade_talent(key: String) -> bool:
	return not is_talent_maxed(key)
func get_available_talents() -> Array:
	var result = []
	for key in TALENTS.keys():
		if can_upgrade_talent(key):
			result.append(key)
	return result
func has_any_talent_available() -> bool:
	return not get_available_talents().is_empty()
func upgrade_talent(key: String) -> bool:
	if not can_upgrade_talent(key):
		return false
	talent_levels[key] = get_talent_level(key) + 1
	talents_changed.emit()
	return true
func get_toughness_bonus() -> float:
	return get_talent_level("toughness") * 20.0
func get_speed_bonus() -> float:
	return get_talent_level("speed") * 20.0
func get_dash_bonus() -> int:
	return get_talent_level("extra_dash")
func has_strawberry_can() -> bool:
	return get_talent_level("strawberry_can") > 0
func spawn_item_drop(parent: Node, pos: Vector2, item_key: String) -> void:
	var area = Area2D.new()
	area.name = "ItemDrop"
	area.position = pos
	area.set_meta("item_key", item_key)
	var sprite = Sprite2D.new()
	if ITEM_TEXTURES.has(item_key):
		var tex = ITEM_TEXTURES[item_key]
		sprite.texture = tex
		var tex_size = tex.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var s = ITEM_DROP_SIZE / max(tex_size.x, tex_size.y)
			sprite.scale = Vector2(s, s)
	area.add_child(sprite)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	area.add_child(shape)
	parent.add_child(area)
	area.body_entered.connect(_on_drop_enter.bind(area))
	area.body_exited.connect(_on_drop_exit.bind(area))
func _on_drop_enter(body: Node2D, area: Area2D) -> void:
	if body.is_in_group("player"):
		nearby_item_drop = area
		if area.has_meta("item_key"):
			LogManager.log("按 E 拾取：" + get_item_display_name(str(area.get_meta("item_key"))))
func _on_drop_exit(body: Node2D, area: Area2D) -> void:
	if not is_instance_valid(area):
		return
	if body.is_in_group("player") and nearby_item_drop == area:
		nearby_item_drop = null
