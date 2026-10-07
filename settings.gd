extends Control
var waiting_action : String = ""
var bind_buttons : Dictionary = {}
const ACTION_ICONS = {
	"left": preload("res://Graphics/UI/Keys/move_left.png"),
	"right": preload("res://Graphics/UI/Keys/move_right.png"),
	"up": preload("res://Graphics/UI/Keys/move_up.png"),
	"down": preload("res://Graphics/UI/Keys/move_down.png"),
	"ui_accept": preload("res://Graphics/UI/Keys/jump.png"),
	"climb": preload("res://Graphics/UI/Keys/grab.png"),
	"dash": preload("res://Graphics/UI/Keys/dash.png"),
	"interact": preload("res://Graphics/UI/Keys/interact.png"),
	"use_item_1": preload("res://Graphics/UI/Keys/item_1.png"),
	"use_item_2": preload("res://Graphics/UI/Keys/item_2.png"),
	"use_item_3": preload("res://Graphics/UI/Keys/item_3.png"),
}
func _ready() -> void:
	$CenterContainer/VBoxContainer/BackButton.pressed.connect(_on_back)
	build_action_list()
func build_action_list() -> void:
	var list = $CenterContainer/VBoxContainer/ScrollContainer/ActionList
	for item in SettingsManager.REMAPPABLE_ACTIONS:
		create_action_row(list, item["action"], item["name"])
func create_action_row(list: Node, action: String, display_name: String) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var icon = TextureRect.new()
	if ACTION_ICONS.has(action):
		icon.texture = ACTION_ICONS[action]
	icon.custom_minimum_size = Vector2(36, 36)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var label = Label.new()
	label.text = display_name
	label.custom_minimum_size = Vector2(140, 0)
	label.add_theme_font_size_override("font_size", 16)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	var btn = Button.new()
	btn.text = get_action_keys_text(action)
	btn.custom_minimum_size = Vector2(200, 32)
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(_on_bind_pressed.bind(action))
	row.add_child(btn)
	bind_buttons[action] = btn
	list.add_child(row)
func get_action_keys_text(action: String) -> String:
	var events = InputMap.action_get_events(action)
	var names = []
	for ev in events:
		if ev is InputEventKey:
			var code = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
			names.append(OS.get_keycode_string(code))
		elif ev is InputEventJoypadButton:
			names.append("手柄" + str(ev.button_index))
	if names.is_empty():
		return "未绑定"
	return " / ".join(names)
func _on_bind_pressed(action: String) -> void:
	AudioManager.play_sfx("ui_click")
	if waiting_action != "":
		_cancel_waiting()
	waiting_action = action
	if bind_buttons.has(action):
		bind_buttons[action].text = "按任意键..."
func _input(event: InputEvent) -> void:
	if waiting_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
			_cancel_waiting()
			return
		var new_event = InputEventKey.new()
		new_event.physical_keycode = event.physical_keycode
		new_event.keycode = event.keycode
		SettingsManager.rebind_action(waiting_action, new_event)
		_finish_waiting()
		get_viewport().set_input_as_handled()
func _finish_waiting() -> void:
	if bind_buttons.has(waiting_action):
		bind_buttons[waiting_action].text = get_action_keys_text(waiting_action)
	waiting_action = ""
func _cancel_waiting() -> void:
	if bind_buttons.has(waiting_action):
		bind_buttons[waiting_action].text = get_action_keys_text(waiting_action)
	waiting_action = ""
func _on_back() -> void:
	AudioManager.play_sfx("ui_back")
	get_tree().change_scene_to_file(SettingsManager.return_to)
