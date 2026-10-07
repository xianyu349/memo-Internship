extends Node2D
@export var chunk_width : int = 512
@export var chunk_height : int = 288
@export var max_level : int = 30
@export var view_radius : int = 2
@export var unload_radius : int = 20
@export var map_seed : int = 0
@export_group("虚空")
@export var max_void_streak : int = 1
@export var safe_start_levels : int = 0
@export var safe_start_radius : int = 1
@export var kill_y_offset : float = 5.0
@export_group("难度")
@export var void_rate_start : float = 0.35
@export var void_rate_end : float = 0.75
@export var trim_ratio_start : float = 0.5
@export var trim_ratio_end : float = 0.2
@export var spike_chunk_chance_start : float = 0.3
@export var spike_chunk_chance_end : float = 0.8
@export var spike_guarantee_gap_start : int = 4
@export var spike_guarantee_gap_end : int = 1
@export var strawberry_chunk_chance_start : float = 0.7
@export var strawberry_chunk_chance_end : float = 0.3
@export var halfwall_spacing_start : int = 5
@export var halfwall_spacing_end : int = 2
@export var special_spacing_start : int = 6
@export var special_spacing_end : int = 14
@export var lava_rise_speed_start : float = 30.0
@export var lava_rise_speed_end : float = 80.0
@export var endless_difficulty_levels : int = 40
@export_group("尖刺")
@export var spike_texture : Texture2D
@export var spike_surface_chance : float = 0.35
@export var spike_size : float = 32.0
@export var spike_max_per_surface : int = 2
@export var spike_edge_margin : float = 50.0
@export var spike_y_offset : float = 0.0
@export_group("草莓")
@export var strawberry_texture : Texture2D
@export var strawberry_guarantee_gap : int = 2
@export var strawberry_surface_chance : float = 0.35
@export var strawberry_size : float = 28.0
@export var strawberry_max_per_surface : int = 2
@export var strawberry_edge_margin : float = 50.0
@export var strawberry_hover_height : float = 50.0
@export_group("半墙")
@export var halfwall_texture : Texture2D
@export var halfwall_width : float = 40.0
@export var halfwall_height : float = 300.0
@export var halfwall_top_y : float = -90.0
@export var halfwall_edge_margin : float = 80.0
@export_group("岩浆")
@export var lava_enabled : bool = true
@export var lava_textures : Array[Texture2D] = []
@export var lava_follow_distance : float = 700.0
@export var lava_width : float = 4000.0
@export var lava_layer_offset : float = 20.0
@export var lava_height : float = 3000.0
@export var lava_death_offset : float = 20.0
@export var lava_z_index : int = 100
@export_group("地图块池")
@export var ground_chunk : PackedScene
@export var summit_chunk : PackedScene
@export var normal_chunks : Array[PackedScene] = []
@export var danger_chunks : Array[PackedScene] = []
@export var save_chunks : Array[PackedScene] = []
@export var talent_shop_chunks : Array[PackedScene] = []
@export var item_shop_chunks : Array[PackedScene] = []
@export var reward_chunks : Array[PackedScene] = []
@export_group("生成节奏")
@export var save_interval : int = 3
@export var save_spacing : int = 6
@export var danger_rate : float = 0.35
@export var reward_rate : float = 0.25
@export var item_shop_rate : float = 0.20
@export var talent_shop_rate : float = 0.15
const STRAWBERRY_SCRIPT = preload("res://strawberry.gd")
var chunks : Dictionary = {}
var player : Node2D
var last_center : Vector2i = Vector2i(99999, 99999)
var max_level_reached : int = 0
var summit_col : int = 99999
var summit_locked : bool = false
var no_trim_paths : Array = []
var lava : Area2D
var lava_y : float = 0.0
var lava_initialized : bool = false
func _ready() -> void:
	if map_seed == 0:
		map_seed = randi()
	if GameState.endless_mode:
		max_level = 999999
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		LogManager.log("【严重错误】找不到 player 分组的节点！")
	GameState.respawn_point = Vector2(chunk_width / 2, -chunk_height + 100)
	GameState.player_respawned.connect(reset_lava)
	build_no_trim_list()
	create_lava()
	AudioManager.play_bgm("bgm_gameplay")
func d_t(level: int) -> float:
	if GameState.endless_mode:
		var t = float(level) / float(endless_difficulty_levels)
		if t <= 1.0:
			return pow(t, 2.0)
		return 1.0
	if max_level <= 1:
		return 0.0
	var t = clamp(float(level) / float(max_level - 1), 0.0, 1.0)
	return pow(t, 2.0)
func d_void_rate(level: int) -> float:
	return lerp(void_rate_start, void_rate_end, d_t(level))
func d_trim_ratio(level: int) -> float:
	return lerp(trim_ratio_start, trim_ratio_end, d_t(level))
func d_spike_chance(level: int) -> float:
	return lerp(spike_chunk_chance_start, spike_chunk_chance_end, d_t(level))
func d_spike_gap(level: int) -> int:
	return int(round(lerp(float(spike_guarantee_gap_start), float(spike_guarantee_gap_end), d_t(level))))
func d_strawberry_chance(level: int) -> float:
	return lerp(strawberry_chunk_chance_start, strawberry_chunk_chance_end, d_t(level))
func d_halfwall_spacing(level: int) -> int:
	return int(round(lerp(float(halfwall_spacing_start), float(halfwall_spacing_end), d_t(level))))
func d_special_spacing(level: int) -> int:
	return int(round(lerp(float(special_spacing_start), float(special_spacing_end), d_t(level))))
func d_lava_speed() -> float:
	if player == null:
		return lava_rise_speed_start
	var lvl = int(floor(-player.global_position.y / chunk_height))
	return lerp(lava_rise_speed_start, lava_rise_speed_end, d_t(lvl))
func build_no_trim_list() -> void:
	no_trim_paths.clear()
	_add_pool_paths(save_chunks)
	_add_pool_paths(talent_shop_chunks)
	_add_pool_paths(item_shop_chunks)
	_add_pool_paths(reward_chunks)
	_add_pool_paths(danger_chunks)
func _add_pool_paths(pool: Array) -> void:
	for s in pool:
		if s == null:
			continue
		var p = s.resource_path
		if p != "" and not no_trim_paths.has(p):
			no_trim_paths.append(p)
func create_lava() -> void:
	if not lava_enabled:
		return
	lava = Area2D.new()
	lava.name = "Lava"
	add_child(lava)
	lava.z_index = lava_z_index
	var layer_count = max(lava_textures.size(), 1)
	for i in range(layer_count):
		var sprite = Sprite2D.new()
		sprite.name = "LavaLayer" + str(i)
		var tex = lava_textures[i] if i < lava_textures.size() else null
		if tex != null:
			sprite.texture = tex
			sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			sprite.region_enabled = true
			sprite.region_rect = Rect2(0, 0, lava_width, lava_height)
		sprite.centered = false
		sprite.position = Vector2(-lava_width / 2.0, i * lava_layer_offset)
		sprite.modulate.a = max(1.0 - i * 0.25, 0.3)
		lava.add_child(sprite)
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(lava_width, lava_height)
	shape.shape = rect
	shape.position = Vector2(0, lava_height / 2.0)
	lava.add_child(shape)
	if player != null:
		lava_y = player.global_position.y + lava_follow_distance + 200.0
	else:
		lava_y = 800.0
	lava.global_position = Vector2(0, lava_y)
	lava_initialized = true
func reset_lava() -> void:
	if not lava_enabled or not lava_initialized or player == null:
		return
	lava_y = player.global_position.y + lava_follow_distance
	lava.global_position = Vector2(player.global_position.x, lava_y)
func _process(delta: float) -> void:
	if player == null:
		return
	if lava_enabled and lava_initialized:
		update_lava(delta)
		check_lava_death()
	check_fall_death()
	var col = int(floor(player.global_position.x / chunk_width))
	var level = int(floor(-player.global_position.y / chunk_height))
	if level > max_level_reached:
		max_level_reached = level
	if not summit_locked and not GameState.endless_mode and level >= max_level - 1:
		lock_summit(col)
	var center = Vector2i(col, level)
	if center == last_center:
		return
	last_center = center
	for dc in range(-view_radius, view_radius + 1):
		for dl in range(-view_radius, view_radius + 1):
			var c = col + dc
			var l = level + dl
			if l < 0 or l > max_level:
				continue
			if not should_generate(c, l):
				continue
			ensure_chunk(c, l)
	unload_far_chunks(col, level)
func lock_summit(player_col: int) -> void:
	if summit_locked:
		return
	summit_locked = true
	summit_col = player_col
	replace_chunk_with_summit(player_col, max_level)
func replace_chunk_with_summit(col: int, level: int) -> void:
	if summit_chunk == null:
		return
	var key = Vector2i(col, level)
	if chunks.has(key):
		var old = chunks[key]
		if old != null and is_instance_valid(old):
			old.queue_free()
		chunks.erase(key)
	var chunk = summit_chunk.instantiate()
	chunk.position = Vector2(col * chunk_width, -(level + 1) * chunk_height)
	clamp_sprites_to_width(chunk, chunk_width)
	add_child(chunk)
	chunks[key] = chunk
	last_center = Vector2i(99999, 99999)
func clamp_sprites_to_width(node: Node, max_width: float) -> void:
	for child in node.get_children():
		if child is Sprite2D and child.texture != null:
			var tex_w = child.texture.get_size().x * abs(child.scale.x)
			if tex_w > max_width:
				var ratio = max_width / tex_w
				child.scale = Vector2(child.scale.x * ratio, child.scale.y * ratio)
		clamp_sprites_to_width(child, max_width)
func update_lava(delta: float) -> void:
	lava_y -= d_lava_speed() * delta
	var follow_y = player.global_position.y + lava_follow_distance
	if follow_y < lava_y:
		lava_y = follow_y
	lava.global_position = Vector2(player.global_position.x, lava_y)
func check_lava_death() -> void:
	if player == null or not player.has_method("die"):
		return
	if player.global_position.y + lava_death_offset > lava_y:
		player.die()
func check_fall_death() -> void:
	var kill_y = chunk_height * kill_y_offset
	if player.global_position.y > kill_y:
		if player.has_method("die"):
			player.die()
func should_generate(col: int, level: int) -> bool:
	if level < 0:
		return false
	if level == 0:
		return true
	if level >= max_level:
		return true
	if level <= safe_start_levels and abs(col) <= safe_start_radius:
		return true
	var vr = d_void_rate(level)
	var rng = rng_for(col, level)
	if rng.randf() > vr:
		return true
	var streak = 0
	for dx in range(-1, -max_void_streak - 1, -1):
		var lrng = rng_for(col + dx, level)
		if lrng.randf() <= vr:
			streak += 1
		else:
			break
	if streak >= max_void_streak:
		return true
	return false
func resolve_base_type(col: int, level: int) -> int:
	if level <= 0 or level >= max_level:
		return 0
	if has_valid(save_chunks) and save_interval > 0 and save_spacing > 0 and level % save_interval == 0:
		var save_rng = RandomNumberGenerator.new()
		save_rng.seed = hash(str(map_seed) + "_save_lvl_" + str(level))
		var save_phase = save_rng.randi_range(0, save_spacing - 1)
		if posmod(col - save_phase, save_spacing) == 0:
			return 5
	var sp = d_special_spacing(level)
	if sp <= 1:
		return 0
	var spec_rng = RandomNumberGenerator.new()
	spec_rng.seed = hash(str(map_seed) + "_spec_lvl_" + str(level))
	var spec_phase = spec_rng.randi_range(0, sp - 1)
	if posmod(col - spec_phase, sp) != 0:
		return 0
	var candidates = []
	if has_valid(danger_chunks):
		candidates.append([1, danger_rate])
	if has_valid(reward_chunks):
		candidates.append([2, reward_rate])
	if has_valid(item_shop_chunks):
		candidates.append([3, item_shop_rate])
	if has_valid(talent_shop_chunks) and GameState.has_any_talent_available():
		candidates.append([4, talent_shop_rate])
	if candidates.is_empty():
		return 0
	var total = 0.0
	for c in candidates:
		total += c[1]
	if total <= 0.0:
		return candidates[0][0]
	var rng = rng_for(col, level)
	var roll = rng.randf() * total
	var acc = 0.0
	for c in candidates:
		acc += c[1]
		if roll < acc:
			return c[0]
	return candidates[candidates.size() - 1][0]
func ensure_chunk(col: int, level: int) -> void:
	var key = Vector2i(col, level)
	if chunks.has(key):
		return
	if level >= max_level:
		if not GameState.endless_mode and summit_locked and col == summit_col:
			replace_chunk_with_summit(col, level)
		return
	var scene = pick_chunk(col, level)
	if scene == null:
		chunks[key] = null
		return
	var chunk = scene.instantiate()
	chunk.position = Vector2(col * chunk_width, -(level + 1) * chunk_height)
	var is_special = is_no_trim(scene)
	chunk.set_meta("no_trim", is_special)
	add_child(chunk)
	chunks[key] = chunk
	if not is_special:
		trim_chunk(chunk, col, level)
	if not is_special:
		try_add_halfwall(chunk, col, level)
	if not is_special:
		var spiked_surfaces = try_add_spikes(chunk, col, level)
		try_add_strawberries(chunk, col, level, spiked_surfaces)
func is_no_trim(scene: PackedScene) -> bool:
	if scene == null:
		return false
	var path = scene.resource_path
	if path == "":
		return false
	return no_trim_paths.has(path)
func trim_chunk(chunk: Node, col: int, level: int) -> void:
	if chunk.has_meta("no_trim") and chunk.get_meta("no_trim"):
		return
	if level <= safe_start_levels and abs(col) <= safe_start_radius:
		return
	var floor_node = find_solid_floor(chunk)
	if floor_node == null:
		return
	floor_node.scale.x = 1.0
	floor_node.scale.y = 1.0
	floor_node.position.x = chunk_width / 2.0
	var shape_node = null
	for child in floor_node.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			shape_node = child
			break
	if shape_node == null:
		return
	var tr = d_trim_ratio(level)
	var orig_size = shape_node.shape.size
	var orig_pos = shape_node.position
	var full_width = orig_size.x
	var left_w = full_width * (1.0 - tr) / 2.0
	var center_w = full_width * tr
	var right_w = left_w
	var left_shape = CollisionShape2D.new()
	left_shape.name = "TrimLeft"
	var left_rect = RectangleShape2D.new()
	left_rect.size = Vector2(left_w, orig_size.y)
	left_shape.shape = left_rect
	left_shape.position = Vector2(-full_width / 2.0 + left_w / 2.0 + orig_pos.x, orig_pos.y)
	floor_node.add_child(left_shape)
	var right_shape = CollisionShape2D.new()
	right_shape.name = "TrimRight"
	var right_rect = RectangleShape2D.new()
	right_rect.size = Vector2(right_w, orig_size.y)
	right_shape.shape = right_rect
	right_shape.position = Vector2(full_width / 2.0 - right_w / 2.0 + orig_pos.x, orig_pos.y)
	floor_node.add_child(right_shape)
	var new_center_rect = RectangleShape2D.new()
	new_center_rect.size = Vector2(center_w, orig_size.y)
	shape_node.shape = new_center_rect
	shape_node.position = orig_pos
func has_halfwall(col: int, level: int) -> bool:
	if halfwall_texture == null:
		return false
	if level == 0:
		return false
	if level >= max_level:
		return false
	if level <= safe_start_levels and abs(col) <= safe_start_radius:
		return false
	var sp = d_halfwall_spacing(level)
	if sp <= 0:
		return false
	var spec_rng = RandomNumberGenerator.new()
	spec_rng.seed = hash(str(map_seed) + "_wall_lvl_" + str(level))
	var phase = spec_rng.randi_range(0, sp - 1)
	return posmod(col - phase, sp) == 0
func try_add_halfwall(chunk: Node, col: int, level: int) -> void:
	if not has_halfwall(col, level):
		return
	var wall_rng = RandomNumberGenerator.new()
	wall_rng.seed = hash(str(map_seed) + "_halfwall_pos_" + str(col) + "_" + str(level))
	var wall = StaticBody2D.new()
	wall.name = "HalfWall"
	var wall_x = wall_rng.randf_range(halfwall_edge_margin, chunk_width - halfwall_edge_margin)
	wall.position = Vector2(wall_x, 0)
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(halfwall_width, halfwall_height)
	shape.shape = rect
	shape.position = Vector2(0, halfwall_top_y + halfwall_height * 0.5)
	wall.add_child(shape)
	var sprite = Sprite2D.new()
	sprite.texture = halfwall_texture
	var tex_size = halfwall_texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		sprite.scale = Vector2(halfwall_width / tex_size.x, halfwall_height / tex_size.y)
	sprite.position = Vector2(0, halfwall_top_y + halfwall_height * 0.5)
	wall.add_child(sprite)
	chunk.add_child(wall)
func spike_intent(col: int, level: int) -> bool:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(str(map_seed) + "_spike_intent_" + str(col) + "_" + str(level))
	return rng.randf() < d_spike_chance(level)
func force_spike_here(col: int, level: int) -> bool:
	if spike_intent(col, level):
		return true
	var gap = d_spike_gap(level)
	var c = col - 1
	var count = 0
	while count < gap and not spike_intent(c, level):
		count += 1
		c -= 1
	return count >= gap
func strawberry_intent(col: int, level: int) -> bool:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(str(map_seed) + "_berry_intent_" + str(col) + "_" + str(level))
	return rng.randf() < d_strawberry_chance(level)
func force_strawberry_here(col: int, level: int) -> bool:
	if strawberry_intent(col, level):
		return true
	var c = col - 1
	var count = 0
	while count < strawberry_guarantee_gap and not strawberry_intent(c, level):
		count += 1
		c -= 1
	return count >= strawberry_guarantee_gap
func try_add_spikes(chunk: Node, col: int, level: int) -> Array:
	var used : Array = []
	if spike_texture == null:
		return used
	if level == 0:
		return used
	if level <= safe_start_levels and abs(col) <= safe_start_radius:
		return used
	var surfaces = find_flat_surfaces(chunk)
	if surfaces.is_empty():
		return used
	var rng = rng_for(col, level)
	var must_spawn = force_spike_here(col, level)
	var guaranteed_done = false
	for surface in surfaces:
		var should_place = rng.randf() < spike_surface_chance
		if must_spawn and not guaranteed_done:
			should_place = true
		if not should_place:
			continue
		if spawn_spikes_on_surface(chunk, surface, rng):
			used.append(surface)
			if must_spawn:
				guaranteed_done = true
	return used
func spawn_spikes_on_surface(chunk: Node, surface: Node, rng: RandomNumberGenerator) -> bool:
	var bounds = get_surface_bounds(surface)
	var left = bounds.x
	var right = bounds.y
	var top_y = bounds.z
	var width = right - left
	if width < spike_size * 2.0:
		return false
	var margin = min(spike_edge_margin, width * 0.15)
	var place_left = left + margin
	var place_right = right - margin
	var usable = place_right - place_left
	if usable < spike_size:
		return false
	var max_fit = int(usable / (spike_size * 1.4))
	if max_fit <= 0:
		return false
	var count = rng.randi_range(1, min(max_fit, spike_max_per_surface))
	var slice = usable / count
	for i in range(count):
		var x = place_left + slice * (i + 0.5) + rng.randf_range(-slice * 0.2, slice * 0.2)
		x = clamp(x, place_left, place_right)
		var spike = create_spike()
		spike.position = Vector2(x, top_y + spike_y_offset)
		chunk.add_child(spike)
	return true
func try_add_strawberries(chunk: Node, col: int, level: int, exclude_surfaces: Array) -> void:
	if strawberry_texture == null:
		return
	if level == 0:
		return
	if level <= safe_start_levels and abs(col) <= safe_start_radius:
		return
	var surfaces = find_flat_surfaces(chunk)
	if surfaces.is_empty():
		return
	var rng = rng_for(col, level)
	var must_spawn = force_strawberry_here(col, level)
	var guaranteed_done = false
	for surface in surfaces:
		if surface in exclude_surfaces:
			continue
		var should_place = rng.randf() < strawberry_surface_chance
		if must_spawn and not guaranteed_done:
			should_place = true
		if not should_place:
			continue
		if spawn_strawberries_on_surface(chunk, surface, rng, col, level):
			if must_spawn:
				guaranteed_done = true
func spawn_strawberries_on_surface(chunk: Node, surface: Node, rng: RandomNumberGenerator, col: int, level: int) -> bool:
	var bounds = get_surface_bounds(surface)
	var left = bounds.x
	var right = bounds.y
	var top_y = bounds.z
	var width = right - left
	if width < strawberry_size * 2.0:
		return false
	var margin = min(strawberry_edge_margin, width * 0.15)
	var place_left = left + margin
	var place_right = right - margin
	var usable = place_right - place_left
	if usable < strawberry_size:
		return false
	var max_fit = int(usable / (strawberry_size * 1.6))
	if max_fit <= 0:
		return false
	var count = rng.randi_range(1, min(max_fit, strawberry_max_per_surface))
	var slice = usable / count
	for i in range(count):
		var x = place_left + slice * (i + 0.5) + rng.randf_range(-slice * 0.2, slice * 0.2)
		x = clamp(x, place_left, place_right)
		var berry = create_strawberry(col, level)
		berry.position = Vector2(x, top_y - strawberry_hover_height)
		chunk.add_child(berry)
		berry.source_global_position = berry.global_position
	return true
func create_strawberry(col: int, level: int) -> Area2D:
	var area = Area2D.new()
	area.name = "Strawberry"
	area.set_script(STRAWBERRY_SCRIPT)
	area.source_col = col
	area.source_level = level
	var sprite = Sprite2D.new()
	sprite.texture = strawberry_texture
	var tex_size = strawberry_texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var s = strawberry_size / max(tex_size.x, tex_size.y)
		sprite.scale = Vector2(s, s)
	area.add_child(sprite)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = strawberry_size * 0.6
	shape.shape = circle
	area.add_child(shape)
	return area
func create_spike() -> Area2D:
	var area = Area2D.new()
	area.name = "Spike"
	var sprite = Sprite2D.new()
	sprite.texture = spike_texture
	var tex_size = spike_texture.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var s = spike_size / max(tex_size.x, tex_size.y)
		sprite.scale = Vector2(s, s)
	sprite.position = Vector2(0, -spike_size * 0.5)
	area.add_child(sprite)
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(spike_size * 0.6, spike_size * 0.6)
	shape.shape = rect
	shape.position = Vector2(0, -spike_size * 0.5)
	area.add_child(shape)
	area.body_entered.connect(_on_spike_enter.bind(area))
	return area
func _on_spike_enter(body: Node2D, area: Area2D) -> void:
	if body.has_method("die"):
		body.die()
func find_solid_floor(node: Node) -> Node:
	var best : Node = null
	var best_w : float = -1.0
	for child in node.get_children():
		if child is StaticBody2D and is_solid(child):
			var w = get_flat_width(child)
			if w > best_w:
				best_w = w
				best = child
		var sub = find_solid_floor(child)
		if sub != null:
			var w2 = get_flat_width(sub)
			if w2 > best_w:
				best_w = w2
				best = sub
	return best
func find_flat_surfaces(node: Node) -> Array:
	var result : Array = []
	_collect_flat_surfaces(node, result)
	return result
func _collect_flat_surfaces(node: Node, result: Array) -> void:
	for child in node.get_children():
		if child is StaticBody2D and get_flat_width(child) > 0.0:
			result.append(child)
		_collect_flat_surfaces(child, result)
func get_flat_width(node: Node) -> float:
	var best : float = 0.0
	for child in node.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var sz = child.shape.size
			if sz.x > sz.y:
				var w = sz.x * node.scale.x
				if w > best:
					best = w
	return best
func is_solid(node: Node) -> bool:
	for child in node.get_children():
		if child is CollisionShape2D and not child.one_way_collision:
			return true
	return false
func get_surface_bounds(surface_node: Node) -> Vector3:
	var best_w : float = 0.0
	var left : float = 0.0
	var right : float = 0.0
	var top : float = 0.0
	for child in surface_node.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			var sz = child.shape.size
			if sz.x <= sz.y:
				continue
			var sx = surface_node.scale.x
			var sy = surface_node.scale.y
			var w = sz.x * sx
			if w > best_w:
				best_w = w
				var cx = surface_node.position.x + child.position.x * sx
				var cy = surface_node.position.y + child.position.y * sy
				left = cx - w * 0.5
				right = cx + w * 0.5
				top = cy - sz.y * sy * 0.5
	return Vector3(left, right, top)
func unload_far_chunks(col: int, level: int) -> void:
	var to_remove = []
	for key in chunks:
		if summit_locked and key.x == summit_col and key.y == max_level:
			continue
		if abs(key.x - col) > unload_radius or abs(key.y - level) > unload_radius:
			to_remove.append(key)
	for key in to_remove:
		if chunks[key] != null and is_instance_valid(chunks[key]):
			chunks[key].queue_free()
		chunks.erase(key)
func pick_chunk(col: int, level: int) -> PackedScene:
	if level == 0:
		return ground_chunk
	if level >= max_level:
		if not GameState.endless_mode and col == summit_col:
			return summit_chunk
		return pick_normal(col, level)
	var base = resolve_base_type(col, level)
	match base:
		1:
			return pick_random(danger_chunks, rng_for(col, level))
		2:
			return pick_random(reward_chunks, rng_for(col, level))
		3:
			return pick_random(item_shop_chunks, rng_for(col, level))
		4:
			return pick_random(talent_shop_chunks, rng_for(col, level))
		5:
			return pick_random(save_chunks, rng_for(col, level))
	return pick_normal(col, level)
func pick_normal(col: int, level: int) -> PackedScene:
	var rng = rng_for(col, level)
	var result = pick_random(normal_chunks, rng)
	if result == null:
		result = ground_chunk
	return result
func rng_for(col: int, level: int) -> RandomNumberGenerator:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(str(map_seed) + "_" + str(col) + "_" + str(level))
	return rng
func has_valid(arr: Array) -> bool:
	for item in arr:
		if item != null:
			return true
	return false
func pick_random(arr: Array, rng: RandomNumberGenerator) -> PackedScene:
	var valid = []
	for item in arr:
		if item != null:
			valid.append(item)
	if valid.is_empty():
		return null
	return valid[rng.randi() % valid.size()]
