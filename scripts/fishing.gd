extends Node2D
# Cosmic Fishing: cast -> wait -> bite -> 3-pulse -> catch.
# The big pulsing button (FishingUI) is the main control; Space / A / tap all work.
# Missing a beat only restarts the 3-pulse count on the same fish: a rare is never lost.
# Lives inside the pond world (draws rod, line and bobber); talks to FishingUI on the HUD.

signal finished

enum S { IDLE, CASTING, WAITING, HOOKED, CAUGHT }

const TEMPOS := {"slow": 0.95, "medium": 0.72, "fast": 0.55}

var state: int = S.IDLE
var player: Node2D
var world: Node2D
var ui: Control

var bobber_target := Vector2.ZERO
var bobber_pos := Vector2.ZERO
var _t := 0.0                 # time in current state
var _wait := 0.0
var fish_id := ""
var is_new := false
var tempo_name := "medium"
var interval := 0.72
var window := 0.18
var hook_time := 0.0          # clock value when hooked
var clock := 0.0
var hits := 0                 # consecutive good beats (need 3)
var scored := {}              # beat index -> true
var next_beat := 0
var miss_flash := 0.0
var hit_flash := 0.0
var beat_flash := 0.0
var splash_t := -1.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	z_index = 2

func active() -> bool:
	return state != S.IDLE

func start(p: Node2D, w: Node2D, target: Vector2) -> void:
	player = p
	world = w
	player.frozen = true
	bobber_target = target
	bobber_pos = rod_tip()
	state = S.CASTING
	_t = 0.0
	ui.show_state()

func rod_tip() -> Vector2:
	var f: Vector2 = player.facing
	var tip := player.global_position + Vector2(0, -26)
	if f == Vector2.UP:
		tip += Vector2(8, -16)
	elif f == Vector2.DOWN:
		tip += Vector2(-10, 10)
	else:
		tip += Vector2(f.x * 22, -10)
	return tip

func cancel(msg := "Reeled in") -> void:
	if state == S.IDLE:
		return
	state = S.IDLE
	player.frozen = false
	ui.show_state()
	if msg != "":
		ui.toast(msg)
	queue_redraw()
	finished.emit()

func _process(delta: float) -> void:
	if state == S.IDLE:
		return
	clock += delta
	_t += delta
	miss_flash = maxf(0.0, miss_flash - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	beat_flash = maxf(0.0, beat_flash - delta)
	var pressed: bool = Input.is_action_just_pressed("action") or ui.consume_click()
	if Input.is_action_just_pressed("cancel") and state != S.CAUGHT:
		cancel()
		return
	match state:
		S.CASTING:
			var k := clampf(_t / 0.45, 0.0, 1.0)
			var a := rod_tip()
			bobber_pos = a.lerp(bobber_target, k) + Vector2(0, -sin(k * PI) * 36.0)
			if k >= 1.0:
				state = S.WAITING
				_t = 0.0
				_wait = _rng.randf_range(2.2, 5.5)
				splash_t = 0.0
				ui.show_state()
		S.WAITING:
			bobber_pos = bobber_target + Vector2(0, sin(_t * 3.0) * 1.0)
			if pressed:
				ui.toast("Not yet... wait for a bite")
			if _t >= _wait:
				_hook()
		S.HOOKED:
			_update_hooked(pressed)
		S.CAUGHT:
			var k := clampf(_t / 0.35, 0.0, 1.0)
			bobber_pos = bobber_target.lerp(rod_tip(), k)
			if pressed and _t > 0.3:
				state = S.IDLE
				player.frozen = false
				ui.show_state()
				finished.emit()
	if splash_t >= 0.0:
		splash_t += delta
		if splash_t > 0.6:
			splash_t = -1.0
	queue_redraw()

func _hook() -> void:
	fish_id = GameState.roll_fish(world.pond_id())
	var names := TEMPOS.keys()
	tempo_name = names[_rng.randi_range(0, names.size() - 1)]
	interval = TEMPOS[tempo_name]
	window = clampf(interval * 0.27, 0.15, 0.22)
	hook_time = clock
	hits = 0
	scored = {}
	next_beat = 0
	state = S.HOOKED
	_t = 0.0
	splash_t = 0.0
	InputMgr.vibrate(80)
	ui.show_state()

func beat_time(k: int) -> float:
	return hook_time + interval * 1.6 + k * interval

# 0..1 progress toward the next beat (1 = beat now). Used to shrink the ring.
func beat_progress() -> float:
	var bt := beat_time(next_beat)
	return clampf(1.0 - (bt - clock) / interval, 0.0, 1.0)

func _update_hooked(pressed: bool) -> void:
	bobber_pos = bobber_target + Vector2(sin(clock * 22.0) * 1.5, 3.0)
	# a beat arriving
	var bt := beat_time(next_beat)
	if clock >= bt and not scored.has(-next_beat - 1):
		scored[-next_beat - 1] = true    # marks "beat ticked" so it fires once
		beat_flash = 0.12
		InputMgr.vibrate(35)
	# a beat that passed without a hit
	if clock > bt + window:
		if not scored.has(next_beat) and hits > 0:
			_miss()
		next_beat += 1
	if pressed:
		var k := int(roundf((clock - beat_time(0)) / interval))
		if k >= 0 and absf(clock - beat_time(k)) <= window and not scored.has(k):
			scored[k] = true
			hits += 1
			hit_flash = 0.18
			InputMgr.vibrate(20)
			if hits >= 3:
				_catch()
		else:
			_miss()

func _miss() -> void:
	if hits > 0 or miss_flash <= 0.0:
		ui.toast("Steady... the fish is still on")
	hits = 0
	miss_flash = 0.3

func _catch() -> void:
	is_new = GameState.record_catch(fish_id)
	state = S.CAUGHT
	_t = 0.0
	splash_t = 0.0
	InputMgr.vibrate(60)
	ui.show_catch(fish_id, is_new)

func _draw() -> void:
	if state == S.IDLE or player == null:
		return
	var tip := rod_tip()
	var hand := player.global_position + Vector2(player.facing.x * 8, -24)
	draw_line(hand, tip, Color("6b4428"), 2.0)
	draw_line(hand, hand.lerp(tip, 0.3), Color("3a2416"), 2.0)
	# line with a little sag
	var mid := tip.lerp(bobber_pos, 0.5) + Vector2(0, 6 if state == S.WAITING else 2)
	var pts := PackedVector2Array()
	for i in 9:
		var k := i / 8.0
		pts.append(tip.lerp(mid, k).lerp(mid.lerp(bobber_pos, k), k))
	draw_polyline(pts, Color(0.95, 0.95, 0.9, 0.85), 1.0)
	if splash_t >= 0.0:
		var r := 4.0 + splash_t * 22.0
		draw_arc(bobber_target + Vector2(0, 2), r, 0, TAU, 20, Color(1, 1, 1, 0.7 * (1.0 - splash_t / 0.6)), 1.0)
	if state == S.WAITING or state == S.HOOKED:
		var rr := 6.0 + fmod(clock * 6.0, 8.0)
		draw_arc(bobber_target + Vector2(0, 3), rr, 0, TAU, 16, Color(1, 1, 1, 0.25), 1.0)
	var tex := PixelArt.bobber_tex()
	draw_texture(tex, bobber_pos - Vector2(4, 6))
	if state == S.HOOKED:
		var bounce := absf(sin(clock * 10.0)) * 3.0
		var ep := player.global_position + Vector2(10, -58 - bounce)
		draw_rect(Rect2(ep, Vector2(5, 12)), Color("1e1520"))
		draw_rect(Rect2(ep + Vector2(1, 1), Vector2(3, 7)), Color("ffd84a"))
		draw_rect(Rect2(ep + Vector2(1, 9), Vector2(3, 2)), Color("ffd84a"))
