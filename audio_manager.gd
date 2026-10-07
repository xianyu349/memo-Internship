extends Node
const AUDIO_PATHS = {
	"bgm_menu": "res://Audio/Music/menu_loop.ogg",
	"bgm_gameplay": "res://Audio/Music/gameplay_loop.ogg",
	"bgm_victory": "res://Audio/Music/victory.ogg",
	"amb_campfire": "res://Audio/Ambience/campfire_loop.ogg",
	"item_feather": "res://Audio/Items/golden_feather.ogg",
	"item_feather_loop": "res://Audio/Items/golden_feather_flight_loop.ogg",
	"item_pinball": "res://Audio/Items/pinball_bounce.ogg",
	"item_wind_loop": "res://Audio/Items/wind_loop.ogg",
	"sfx_checkpoint": "res://Audio/SFX/checkpoint.ogg",
	"sfx_climb_ledge": "res://Audio/SFX/climb_ledge.ogg",
	"sfx_dash": "res://Audio/SFX/dash.ogg",
	"sfx_death": "res://Audio/SFX/death.ogg",
	"sfx_jump": "res://Audio/SFX/jump.ogg",
	"sfx_land": "res://Audio/SFX/land.ogg",
	"sfx_shop": "res://Audio/SFX/shop_purchase.ogg",
	"sfx_strawberry": "res://Audio/SFX/strawberry_collect.ogg",
	"sfx_strawberry_touch": "res://Audio/SFX/strawberry_touch.ogg",
	"sfx_talent": "res://Audio/SFX/talent_upgrade.ogg",
	"sfx_wall_jump": "res://Audio/SFX/wall_jump.ogg",
	"sfx_wall_release": "res://Audio/SFX/wall_release.ogg",
	"ui_click": "res://Audio/UI/click.ogg",
	"ui_back": "res://Audio/UI/back.ogg",
	"ui_pause": "res://Audio/UI/pause.ogg",
	"ui_resume": "res://Audio/UI/resume.ogg",
}
const SFX_POOL_SIZE = 8
var sounds : Dictionary = {}
var bgm_player : AudioStreamPlayer
var loop_player : AudioStreamPlayer
var sfx_pool : Array = []
var sfx_index : int = 0
func _ready() -> void:
	for key in AUDIO_PATHS:
		var path = AUDIO_PATHS[key]
		if ResourceLoader.exists(path):
			sounds[key] = load(path)
		else:
			print("【音频缺失】", path)
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -10.0
	add_child(bgm_player)
	loop_player = AudioStreamPlayer.new()
	loop_player.volume_db = -12.0
	add_child(loop_player)
	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		add_child(p)
		sfx_pool.append(p)
func play_sfx(key: String, volume_db: float = 0.0) -> void:
	if not sounds.has(key):
		return
	var p = sfx_pool[sfx_index]
	sfx_index = (sfx_index + 1) % SFX_POOL_SIZE
	p.stream = sounds[key]
	p.volume_db = volume_db
	p.play()
func play_bgm(key: String) -> void:
	if not sounds.has(key):
		return
	if bgm_player.playing and bgm_player.stream == sounds[key]:
		return
	bgm_player.stream = sounds[key]
	bgm_player.play()
func stop_bgm() -> void:
	bgm_player.stop()
func play_loop(key: String) -> void:
	if not sounds.has(key):
		return
	if loop_player.playing and loop_player.stream == sounds[key]:
		return
	loop_player.stream = sounds[key]
	loop_player.play()
func stop_loop() -> void:
	loop_player.stop()
