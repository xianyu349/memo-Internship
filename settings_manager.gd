extends Node
const CONFIG_PATH = "user://settings.cfg"
var return_to : String = "res://main_menu.tscn"
const REMAPPABLE_ACTIONS = [
	{"action": "left", "name": "向左移动"},
	{"action": "right", "name": "向右移动"},
	{"action": "up", "name": "向上"},
	{"action": "down", "name": "向下"},
	{"action": "ui_accept", "name": "跳跃"},
	{"action": "climb", "name": "抓墙"},
	{"action": "dash", "name": "冲刺"},
	{"action": "interact", "name": "交互"},
	{"action": "use_item_1", "name": "使用道具 1"},
	{"action": "use_item_2", "name": "使用道具 2"},
	{"action": "use_item_3", "name": "使用道具 3"},
]
func _ready() -> void:
	load_settings()
func save_settings() -> void:
	var cfg = ConfigFile.new()
	for item in REMAPPABLE_ACTIONS:
		var action = item["action"]
		var events = InputMap.action_get_events(action)
		var saved = []
		for ev in events:
			if ev is InputEventKey:
				var code = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
				saved.append(["key", code])
			elif ev is InputEventJoypadButton:
				saved.append(["joy", ev.button_index])
		cfg.set_value("keys", action, saved)
	cfg.save(CONFIG_PATH)
func load_settings() -> void:
	var cfg = ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	for item in REMAPPABLE_ACTIONS:
		var action = item["action"]
		if not cfg.has_section_key("keys", action):
			continue
		var saved = cfg.get_value("keys", action)
		InputMap.action_erase_events(action)
		for entry in saved:
			if entry[0] == "key":
				var ev = InputEventKey.new()
				ev.physical_keycode = entry[1]
				InputMap.action_add_event(action, ev)
			elif entry[0] == "joy":
				var ev = InputEventJoypadButton.new()
				ev.button_index = entry[1]
				InputMap.action_add_event(action, ev)
func rebind_action(action: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	save_settings()
