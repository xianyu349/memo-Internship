extends CharacterBody2D
@export var movespeed : float = 300.0
@export var jump_velocity : float = -400.0
@export var jump_velocity_short : float = -220.0
@export var max_fall_speed : float = 500.0
@export var fast_fall_speed : float = 900.0
@export var dash_speed : float = 1000
@export var dash_speed_up : float = 900
@export var dash_duration : float = 0.25
@export var max_dash_count : int = 1
@export var wall_slide_speed : float = 150.0
@export var wall_jump_push : float = 400.0
@export var max_stamina : float = 100.0
@export var climb_stamina_drain : float = 10.0
@export var climb_move_stamina_drain : float = 30.0
@export var climb_jump_stamina_cost : float = 30.0
@export var climb_speed : float = 120.0
@export var jump_fall_threshold : float = 30.0
@export var fly_duration : float = 5.0
@export var wind_duration : float = 10.0
@export var wind_gravity_scale : float = 0.5
@export var pinball_power : float = 900.0
@export var invincible_time : float = 1.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var animator = $AnimatedSprite2D
var is_dead : bool = false
var invincible_timer : float = 0.0
var is_fast_falling : bool = false
var is_landing : bool = false
var was_on_floor : bool = true
var is_dashing : bool = false
var current_dash_count : int = 1
var dash_timer : float = 0.0
var dash_direction : Vector2 = Vector2.RIGHT
var is_wall_sliding : bool = false
var is_climbing : bool = false
var stamina : float = 100.0
var current_anim : String = ""
var gravity_scale : float = 1.0
var wind_timer : float = 0.0
var is_flying : bool = false
var fly_timer : float = 0.0
var is_jump_holding : bool = false
func _ready() -> void:
	apply_talents()
	current_dash_count = max_dash_count
	stamina = max_stamina
	invincible_timer = invincible_time
	if not GameState.talents_changed.is_connected(apply_talents):
		GameState.talents_changed.connect(apply_talents)
func apply_talents() -> void:
	max_stamina = 100.0 + GameState.get_toughness_bonus()
	movespeed = 300.0 + GameState.get_speed_bonus()
	max_dash_count = 1 + GameState.get_dash_bonus()
	if stamina > max_stamina:
		stamina = max_stamina
	current_dash_count = max_dash_count
func play_anim(anim_name: String) -> void:
	if current_anim != anim_name:
		current_anim = anim_name
		animator.play(anim_name)
func get_item_display_name(key: String) -> String:
	if GameState.ITEMS.has(key):
		var info = GameState.ITEMS[key]
		if info is Dictionary and info.has("name"):
			return str(info["name"])
	return key
func use_item_at(slot_index: int) -> void:
	var key = GameState.consume_item(slot_index)
	if key == "":
		return
	LogManager.log("使用道具：" + get_item_display_name(key))
	match key:
		"golden_feather":
			start_flying()
		"wind":
			start_wind()
		"pinball":
			spawn_pinball()
func start_flying() -> void:
	is_flying = true
	fly_timer = fly_duration
	is_dashing = false
	is_climbing = false
	is_wall_sliding = false
	is_jump_holding = false
	AudioManager.play_sfx("item_feather")
	AudioManager.play_loop("item_feather_loop")
func start_wind() -> void:
	gravity_scale = wind_gravity_scale
	wind_timer = wind_duration
	AudioManager.play_loop("item_wind_loop")
func spawn_pinball() -> void:
	var area = Area2D.new()
	area.name = "Pinball"
	area.position = global_position
	var sprite = Sprite2D.new()
	if GameState.ITEM_TEXTURES.has("pinball"):
		var tex = GameState.ITEM_TEXTURES["pinball"]
		sprite.texture = tex
		var ts = tex.get_size()
		if ts.x > 0 and ts.y > 0:
			var s = 32.0 / max(ts.x, ts.y)
			sprite.scale = Vector2(s, s)
	area.add_child(sprite)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 24.0
	shape.shape = circle
	area.add_child(shape)
	get_parent().add_child(area)
	area.body_entered.connect(_on_pinball_hit.bind(area))
func _on_pinball_hit(body: Node2D, area: Area2D) -> void:
	if not body.is_in_group("player"):
		return
	if not is_instance_valid(area):
		return
	var dir = (body.global_position - area.global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	body.velocity = dir * pinball_power
	AudioManager.play_sfx("item_pinball")
func update_item_timers(delta: float) -> void:
	if wind_timer > 0:
		wind_timer -= delta
		if wind_timer <= 0:
			gravity_scale = 1.0
			AudioManager.stop_loop()
func update_jump_hold() -> void:
	if not is_jump_holding:
		return
	if not Input.is_action_pressed("ui_accept"):
		is_jump_holding = false
		if velocity.y < jump_velocity_short:
			velocity.y = jump_velocity_short
	elif velocity.y >= 0:
		is_jump_holding = false
func check_collect_strawberries() -> void:
	var world = get_parent()
	if world == null:
		return
	var cw = world.get("chunk_width")
	var ch = world.get("chunk_height")
	if cw == null or ch == null:
		return
	var my_col = int(floor(global_position.x / float(cw)))
	var my_level = int(floor(-global_position.y / float(ch)))
	for berry in GameState.following_strawberries.duplicate():
		if not is_instance_valid(berry):
			continue
		if not berry.is_following:
			continue
		if berry.source_col != my_col or berry.source_level != my_level:
			berry.collect()
func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if invincible_timer > 0:
		invincible_timer -= delta
	if has_node("Camera2D"):
		var cam = $Camera2D
		var bottom_y = cam.global_position.y + get_viewport_rect().size.y * 0.5 + 100.0
		if global_position.y > bottom_y:
			die()
			return
	update_item_timers(delta)
	if Input.is_action_just_pressed("use_item_1"):
		use_item_at(0)
	if Input.is_action_just_pressed("use_item_2"):
		use_item_at(1)
	if Input.is_action_just_pressed("use_item_3"):
		use_item_at(2)
	if Input.is_action_just_pressed("interact") and GameState.nearby_save_point != null:
		var sp = GameState.nearby_save_point
		if sp.has_method("get_respawn_position"):
			GameState.respawn_point = sp.get_respawn_position()
		else:
			GameState.respawn_point = global_position
		LogManager.log("已存档！")
		AudioManager.play_sfx("sfx_checkpoint")
		if has_node("Camera2D"):
			$Camera2D.set_follow_limit()
	if Input.is_action_just_pressed("interact") and GameState.nearby_item_drop != null:
		var drop = GameState.nearby_item_drop
		GameState.nearby_item_drop = null
		if is_instance_valid(drop):
			var key = ""
			if drop.has_meta("item_key"):
				key = str(drop.get_meta("item_key"))
			if key != "":
				var item_name = get_item_display_name(key)
				var placed = false
				for i in range(GameState.item_slots.size()):
					if GameState.item_slots[i] == null:
						GameState.item_slots[i] = key
						LogManager.log("放入栏位 " + str(i + 1) + "：" + item_name)
						placed = true
						break
				if placed:
					GameState.backpack_changed.emit()
				else:
					LogManager.log("背包满了")
			drop.queue_free()
	if Input.is_action_just_pressed("interact") and GameState.nearby_shop_bubble != null:
		var bubble = GameState.nearby_shop_bubble
		GameState.nearby_shop_bubble = null
		if is_instance_valid(bubble):
			if GameState.strawberries >= 1:
				GameState.strawberries -= 1
				var key = ""
				if bubble.has_meta("item_key"):
					key = str(bubble.get_meta("item_key"))
				if key != "":
					GameState.spawn_item_drop(get_parent(), bubble.global_position + Vector2(0, 50), key)
				bubble.queue_free()
				AudioManager.play_sfx("sfx_shop")
			else:
				LogManager.log("草莓不够")
	if Input.is_action_just_pressed("interact") and GameState.nearby_talent_bubble != null:
		var tbubble = GameState.nearby_talent_bubble
		GameState.nearby_talent_bubble = null
		if is_instance_valid(tbubble) and tbubble.has_meta("talent_key"):
			var tkey = str(tbubble.get_meta("talent_key"))
			if GameState.TALENTS.has(tkey):
				var info = GameState.TALENTS[tkey]
				var price = int(info["price"])
				if GameState.strawberries >= price:
					GameState.strawberries -= price
					GameState.upgrade_talent(tkey)
					LogManager.log("获得天赋：" + str(info["name"]) + " Lv." + str(GameState.get_talent_level(tkey)))
					AudioManager.play_sfx("sfx_talent")
					var parent = tbubble.get_parent()
					if parent != null and parent.has_method("pop_bubble"):
						parent.pop_bubble(tbubble)
					tbubble.queue_free()
				else:
					LogManager.log("草莓不够，需要 " + str(price))
	if is_on_floor() and not was_on_floor:
		if is_fast_falling:
			is_landing = true
			play_anim("fastfall_land")
			velocity.x = 0
			await animator.animation_finished
			is_landing = false
		is_fast_falling = false
		check_collect_strawberries()
		AudioManager.play_sfx("sfx_land")
	was_on_floor = is_on_floor()
	if is_on_floor():
		stamina = max_stamina
		if not is_dashing:
			current_dash_count = max_dash_count
	if is_landing:
		move_and_slide()
		return
	if is_flying:
		fly_timer -= delta
		if fly_timer <= 0:
			is_flying = false
			AudioManager.stop_loop()
		var fly_input = Input.get_vector("left", "right", "up", "down")
		velocity = fly_input * movespeed
		if fly_input.x < 0:
			animator.flip_h = true
		elif fly_input.x > 0:
			animator.flip_h = false
		if fly_input != Vector2.ZERO:
			play_anim("run")
		else:
			play_anim("idle")
		move_and_slide()
		return
	if Input.is_action_just_pressed("dash") and current_dash_count > 0 and not is_dashing:
		is_dashing = true
		is_jump_holding = false
		current_dash_count -= 1
		dash_timer = dash_duration
		var input_dir = Input.get_vector("left", "right", "up", "down")
		if input_dir != Vector2.ZERO:
			dash_direction = input_dir.normalized()
		else:
			dash_direction = Vector2.LEFT if animator.flip_h else Vector2.RIGHT
		play_anim("dash")
		AudioManager.play_sfx("sfx_dash")
	if is_dashing:
		var current_dash_speed = dash_speed_up if dash_direction.y < 0 else dash_speed
		velocity = dash_direction * current_dash_speed
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity.y = 0
		move_and_slide()
		return
	update_jump_hold()
	var touching_wall = is_on_wall() and not is_on_floor()
	var wall_normal = get_wall_normal()
	var dir_input = Input.get_axis("left", "right")
	var moving_away = (wall_normal.x > 0 and dir_input > 0) or (wall_normal.x < 0 and dir_input < 0)
	var pressing_down = Input.is_action_pressed("down")
	if is_climbing:
		if not Input.is_action_pressed("climb") or not touching_wall or stamina <= 0 or is_on_floor() or moving_away:
			is_climbing = false
	elif touching_wall and Input.is_action_pressed("climb") and stamina > 0:
		is_climbing = true
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor() and not Input.is_action_pressed("down"):
			velocity.y = jump_velocity
			is_jump_holding = true
			is_fast_falling = false
			AudioManager.play_sfx("sfx_jump")
		elif touching_wall:
			if moving_away:
				velocity.y = jump_velocity
				velocity.x = wall_normal.x * wall_jump_push
				is_jump_holding = true
				is_climbing = false
				is_fast_falling = false
				AudioManager.play_sfx("sfx_wall_jump")
			elif is_climbing:
				velocity.y = jump_velocity
				stamina -= climb_jump_stamina_cost
				is_jump_holding = true
				is_climbing = false
				is_fast_falling = false
				AudioManager.play_sfx("sfx_jump")
	if is_climbing:
		var climb_dir = Input.get_axis("up", "down")
		if climb_dir != 0:
			velocity.y = climb_dir * climb_speed
			stamina -= climb_move_stamina_drain * delta
		else:
			velocity.y = 0
			stamina -= climb_stamina_drain * delta
		velocity.x = 0
		if wall_normal.x > 0:
			animator.flip_h = true
		elif wall_normal.x < 0:
			animator.flip_h = false
		play_anim("wall_slide")
		move_and_slide()
		return
	is_wall_sliding = false
	if not is_on_floor():
		if touching_wall and velocity.y > 0 and not pressing_down and not moving_away:
			is_wall_sliding = true
			if wall_normal.x > 0:
				animator.flip_h = true
			elif wall_normal.x < 0:
				animator.flip_h = false
		if is_wall_sliding:
			velocity.y += gravity * gravity_scale * delta
			velocity.y = min(velocity.y, wall_slide_speed)
		else:
			velocity.y += gravity * gravity_scale * delta
			if pressing_down:
				velocity.y += gravity * gravity_scale * 2.5 * delta
			var current_max_speed = fast_fall_speed if pressing_down else max_fall_speed
			velocity.y = min(velocity.y, current_max_speed)
			if pressing_down and velocity.y > 0:
				is_fast_falling = true
	if is_on_floor() and pressing_down:
		velocity.x = 0
	elif dir_input:
		if is_wall_sliding and moving_away:
			is_wall_sliding = false
		if not is_wall_sliding:
			velocity.x = dir_input * movespeed
		if dir_input < 0:
			animator.flip_h = true
		elif dir_input > 0:
			animator.flip_h = false
	else:
		velocity.x = move_toward(velocity.x, 0, movespeed)
	if not is_on_floor():
		if is_wall_sliding:
			play_anim("wall_slide")
		elif velocity.y < -jump_fall_threshold:
			play_anim("jump")
		elif velocity.y > jump_fall_threshold:
			if pressing_down:
				play_anim("fastfall")
			else:
				play_anim("fall")
	else:
		if pressing_down:
			play_anim("duck")
		elif velocity.x == 0:
			play_anim("idle")
		else:
			play_anim("run")
	move_and_slide()
func die() -> void:
	if is_dead:
		return
	if invincible_timer > 0:
		return
	is_dead = true
	GameState.death_count += 1
	velocity = Vector2.ZERO
	is_flying = false
	wind_timer = 0.0
	gravity_scale = 1.0
	is_jump_holding = false
	AudioManager.stop_loop()
	AudioManager.play_sfx("sfx_death")
	for berry in GameState.following_strawberries.duplicate():
		if is_instance_valid(berry):
			berry.return_to_source()
	GameState.following_strawberries.clear()
	play_anim("death")
	$CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(1.0).timeout
	global_position = GameState.respawn_point
	velocity = Vector2.ZERO
	is_dead = false
	invincible_timer = invincible_time
	apply_talents()
	stamina = max_stamina
	current_dash_count = max_dash_count
	$CollisionShape2D.set_deferred("disabled", false)
	current_anim = ""
	play_anim("idle")
	GameState.player_respawned.emit()
