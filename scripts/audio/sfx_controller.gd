class_name BubbleSfxController
extends Node

const POP_PLAYER_COUNT := 5
const BOUNCE_COOLDOWN_MS := 40
const POP_COOLDOWN_MS := 28
const FLOATING_COOLDOWN_MS := 36

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var shoot_player: AudioStreamPlayer
var bounce_player: AudioStreamPlayer
var event_player: AudioStreamPlayer
var floating_player: AudioStreamPlayer
var pop_players: Array[AudioStreamPlayer] = []
var shoot_stream: AudioStream
var wall_bounce_stream: AudioStream
var floating_drop_stream: AudioStream
var row_drop_stream: AudioStream
var board_clear_stream: AudioStream
var game_over_stream: AudioStream
var match_pop_streams: Array[AudioStream] = []

var last_bounce_ms: int = -1000
var last_pop_ms: int = -1000
var last_floating_ms: int = -1000
var next_pop_player_index: int = 0
var next_pop_stream_index: int = 0
var sfx_enabled: bool = true
var volume_offset_db: float = 0.0


func _ready() -> void:
	rng.randomize()
	shoot_player = _make_player("ShootPlayer", -10.0)
	shoot_stream = load("res://assets/sfx/procedural/shoot_whoosh.wav") as AudioStream
	wall_bounce_stream = load("res://assets/sfx/procedural/wall_bounce.wav") as AudioStream
	floating_drop_stream = load("res://assets/sfx/procedural/floating_fall.wav") as AudioStream
	row_drop_stream = load("res://assets/sfx/procedural/row_drop.wav") as AudioStream
	board_clear_stream = load("res://assets/sfx/procedural/board_cleared.wav") as AudioStream
	game_over_stream = load("res://assets/sfx/procedural/game_over.wav") as AudioStream
	match_pop_streams = [
		load("res://assets/sfx/procedural/bubble_pop_juicy.wav") as AudioStream,
		load("res://assets/sfx/procedural/bubble_pop.wav") as AudioStream,
		load("res://assets/sfx/procedural/bubble_pop_chunky.wav") as AudioStream
	]
	bounce_player = _make_player("BouncePlayer", -12.0)
	event_player = _make_player("EventPlayer", -10.5)
	floating_player = _make_player("FloatingPlayer", -13.0)
	for index in range(POP_PLAYER_COUNT):
		pop_players.append(_make_player("PopPlayer%d" % index, -13.5))


func play_shoot() -> void:
	if shoot_stream == null:
		return
	_play(shoot_player, shoot_stream, -10.5, rng.randf_range(0.98, 1.02))


func play_wall_bounce() -> void:
	if wall_bounce_stream == null:
		return
	var now: int = Time.get_ticks_msec()
	if now - last_bounce_ms < BOUNCE_COOLDOWN_MS:
		return
	last_bounce_ms = now
	_play(bounce_player, wall_bounce_stream, -13.0, rng.randf_range(0.95, 1.04))


func play_match_pop() -> void:
	if match_pop_streams.is_empty():
		return
	var now: int = Time.get_ticks_msec()
	if now - last_pop_ms < POP_COOLDOWN_MS:
		return
	last_pop_ms = now
	_play(_next_pop_player(), _next_pop_stream(), -11.8, rng.randf_range(0.96, 1.06))


func play_floating_drop() -> void:
	if floating_drop_stream == null:
		return
	var now: int = Time.get_ticks_msec()
	if now - last_floating_ms < FLOATING_COOLDOWN_MS:
		return
	last_floating_ms = now
	_play(floating_player, floating_drop_stream, -13.5, rng.randf_range(0.96, 1.03))


func play_row_drop() -> void:
	if row_drop_stream == null:
		return
	_play(event_player, row_drop_stream, -10.5, rng.randf_range(0.98, 1.02))


func play_board_clear() -> void:
	if board_clear_stream == null:
		return
	_play(event_player, board_clear_stream, -10.0, rng.randf_range(0.98, 1.02))


func play_game_over() -> void:
	if game_over_stream == null:
		return
	_play(event_player, game_over_stream, -10.5, 1.0)


func apply_settings(settings: Dictionary) -> void:
	sfx_enabled = bool(settings.get("sfx_enabled", true))
	var linear_volume: float = clampf(float(settings.get("sfx_volume", 1.0)), 0.0, 1.0)
	if linear_volume <= 0.001:
		volume_offset_db = -80.0
	else:
		volume_offset_db = linear_to_db(linear_volume)


func _next_pop_player() -> AudioStreamPlayer:
	var player: AudioStreamPlayer = pop_players[next_pop_player_index]
	next_pop_player_index = (next_pop_player_index + 1) % pop_players.size()
	return player


func _next_pop_stream() -> AudioStream:
	var stream: AudioStream = match_pop_streams[next_pop_stream_index]
	next_pop_stream_index = (next_pop_stream_index + 1) % match_pop_streams.size()
	return stream


func _play(player: AudioStreamPlayer, stream: AudioStream, volume_db: float, pitch_scale: float) -> void:
	if not sfx_enabled:
		return
	player.stream = stream
	player.volume_db = volume_db + volume_offset_db
	player.pitch_scale = pitch_scale
	player.play()


func _make_player(name: String, volume_db: float) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = name
	player.bus = &"Master"
	player.volume_db = volume_db
	add_child(player)
	return player
