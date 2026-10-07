extends Node2D
@export var tree_texture : Texture2D
@export var cloud_texture : Texture2D
@export var layer_count : int = 3
@export var layer_scale : float = 1.5
@export var layer_scale_step : float = 0.25
@export var tree_color_back : Color = Color(0.35, 0.4, 0.5, 1.0)
@export var tree_color_front : Color = Color(0.06, 0.08, 0.12, 1.0)
@export var cloud_color_back : Color = Color(0.5, 0.55, 0.65, 1.0)
@export var cloud_color_front : Color = Color(0.85, 0.9, 1.0, 1.0)
@export var tree_sink : float = 30.0
@export var layer_y_step : float = 20.0
@export var cloud_scale : float = 1.0
@export var cloud_scale_step : float = 0.15
const Z_CLOUD_BASE : int = 0
const Z_TREE_BASE : int = -50
var player : Node2D = null
var decor_root : Node2D = null
func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	decor_root = Node2D.new()
	decor_root.name = "DecorRoot"
	decor_root.z_index = -100
	decor_root.z_as_relative = false
	add_child(decor_root)
	rebuild()
func _process(_delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
func get_design_size() -> Vector2:
	var vw = ProjectSettings.get_setting("display/window/size/viewport_width", 1152)
	var vh = ProjectSettings.get_setting("display/window/size/viewport_height", 648)
	return Vector2(vw, vh)
func rebuild() -> void:
	for c in decor_root.get_children():
		c.queue_free()
	build_cloud_layers()
	build_tree_layers()
func build_cloud_layers() -> void:
	if cloud_texture == null:
		return
	var tex_size = cloud_texture.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return
	var design = get_design_size()
	var vw = design.x
	var base_scale = vw / tex_size.x
	for i in range(layer_count):
		var s = Sprite2D.new()
		s.texture = cloud_texture
		s.centered = true
		var sc = base_scale * (cloud_scale + i * cloud_scale_step)
		s.scale = Vector2(sc, sc)
		s.position = Vector2(0, 0)
		var t = float(i) / max(float(layer_count - 1), 1.0)
		s.modulate = cloud_color_back.lerp(cloud_color_front, t)
		s.z_index = Z_CLOUD_BASE + i
		decor_root.add_child(s)
func build_tree_layers() -> void:
	if tree_texture == null:
		return
	var tex_size = tree_texture.get_size()
	if tex_size.x <= 0 or tex_size.y <= 0:
		return
	var design = get_design_size()
	var vw = design.x
	var vh = design.y
	var screen_bottom = vh * 0.5
	for i in range(layer_count):
		var s = Sprite2D.new()
		s.texture = tree_texture
		s.centered = false
		s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		s.region_enabled = true
		var sc = layer_scale + i * layer_scale_step
		var needed_tex_w = vw / sc
		s.region_rect = Rect2(0, 0, needed_tex_w, tex_size.y)
		s.scale = Vector2(sc, sc)
		var h = tex_size.y * sc
		var y = screen_bottom + tree_sink - h - i * layer_y_step
		s.position = Vector2(-vw * 0.5, y)
		var t = float(i) / max(float(layer_count - 1), 1.0)
		s.modulate = tree_color_back.lerp(tree_color_front, t)
		s.z_index = Z_TREE_BASE + i
		decor_root.add_child(s)
