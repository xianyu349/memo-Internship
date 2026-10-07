extends CanvasLayer
@onready var stamina_bar : ProgressBar = $StaminaBar
@onready var strawberry_label : Label = $StrawberryLabel
@onready var dash_label : Label = $DashLabel
@onready var log_label : Label = $LogLabel
@onready var depth_label : Label = $DepthLabel
@onready var slot_icons : Array = [
	$Backpack/Slot1/Icon,
	$Backpack/Slot2/Icon,
	$Backpack/Slot3/Icon,
]
var player : Node = null
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if not GameState.backpack_changed.is_connected(update_backpack):
		GameState.backpack_changed.connect(update_backpack)
	if not LogManager.log_added.is_connected(_on_log_added):
		LogManager.log_added.connect(_on_log_added)
	update_backpack()
	_on_log_added("")
func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
	var cur = player.get("stamina")
	var mx = player.get("max_stamina")
	if cur != null and mx != null:
		stamina_bar.max_value = mx
		stamina_bar.value = cur
	strawberry_label.text = "草莓数：" + str(GameState.strawberries)
	var dc = player.get("current_dash_count")
	var dmax = player.get("max_dash_count")
	if dc != null and dmax != null:
		dash_label.text = "冲刺 " + str(dc) + " / " + str(dmax)
	var world = get_tree().current_scene
	if world != null:
		var ch = world.get("chunk_height")
		if ch != null and ch > 0:
			var level = int(floor(-player.global_position.y / float(ch)))
			if level < 0:
				level = 0
			depth_label.text = "第 " + str(level) + " 层"
func _on_log_added(_line: String) -> void:
	log_label.text = LogManager.get_text()
func update_backpack() -> void:
	for i in range(slot_icons.size()):
		var icon : TextureRect = slot_icons[i]
		if i < GameState.item_slots.size() and GameState.item_slots[i] != null:
			var key = str(GameState.item_slots[i])
			if GameState.ITEM_TEXTURES.has(key):
				icon.texture = GameState.ITEM_TEXTURES[key]
			else:
				icon.texture = null
		else:
			icon.texture = null
