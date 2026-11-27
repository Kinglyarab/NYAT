extends Node2D
# Root: loads rooms, owns the player, camera and UI layers, routes the ACTION button
# to whatever is in front of the player (interactable, or water -> cast).

const SanctuaryScript := preload("res://scripts/sanctuary.gd")
const PondScript := preload("res://scripts/pond.gd")
const PlayerScript := preload("res://scripts/player.gd")
const FishingScript := preload("res://scripts/fishing.gd")
const HudScript := preload("res://scripts/hud.gd")
const TouchScript := preload("res://scripts/touch_controls.gd")
const FishingUiScript := preload("res://scripts/fishing_ui.gd")
const LogScript := preload("res://scripts/collection_log_ui.gd")

var world: Node2D
var player: CharacterBody2D
var fishing: Node2D
var camera: Camera2D
var hud: Control
var touch: Control
var fishing_ui: Control
var log_ui: Control
var fade: ColorRect
var busy := false
var _cam_pos := Vector2.ZERO

func _ready() -> void:
	SaveSystem.load_game()
	camera = Camera2D.new()
	add_child(camera)
	camera.make_current()

	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	hud = HudScript.new()
	ui.add_child(hud)
	touch = TouchScript.new()
	ui.add_child(touch)
	fishing_ui = FishingUiScript.new()
	fishing_ui.hud = hud
	ui.add_child(fishing_ui)
	log_ui = LogScript.new()
	ui.add_child(log_ui)
	fade = ColorRect.new()
	fade.color = Color(0.05, 0.03, 0.08, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(fade)

	hud.log_pressed.connect(toggle_log)
	log_ui.closed.connect(_on_log_closed)
	GameState.caught.connect(_on_caught)

	var loc := GameState.location if GameState.location in ["sanctuary", "pond"] else "sanctuary"
	go_to(loc, "default", true)

func go_to(loc: String, spawn: String, instant := false) -> void:
	if busy:
		return
	busy = true
	if not instant:
		var tw := create_tween()
		tw.tween_property(fade, "modulate:a", 1.0, 0.25)
		await tw.finished
	if world != null:
		world.queue_free()
		world = null
	world = (PondScript if loc == "pond" else SanctuaryScript).new()
	world.main = self
	add_child(world)
	move_child(world, 0)
	world.build()
	player = PlayerScript.new()
	world.objects.add_child(player)
	player.global_position = world.spawns.get(spawn, world.spawns.get("default", Vector2(100, 100)))
	player.face(Vector2.DOWN)
	fishing = FishingScript.new()
	fishing.ui = fishing_ui
	world.add_child(fishing)
	fishing.finished.connect(func(): touch.fishing_mode = false)
	fishing_ui.fishing = fishing
	_cam_pos = _cam_target()
	camera.global_position = _cam_pos
	GameState.set_location(loc)
	if loc == "pond":
		hud.banner("Sunlit Park Pond", "Tier 1  ·  Basic fish  ·  rotates weekly")
	else:
		hud.banner("Your Sanctuary", "A cozy start. Stations arrive in the next build.")
	var tw2 := create_tween()
	tw2.tween_property(fade, "modulate:a", 0.0, 0.35)
	await tw2.finished
	busy = false

func _cam_target() -> Vector2:
	var vs := get_viewport_rect().size
	var ws: Vector2 = world.world_size()
	var p: Vector2 = player.global_position + Vector2(0, -20) + player.facing * 18.0
	var out := Vector2.ZERO
	for i in 2:
		if ws[i] <= vs[i]:
			out[i] = ws[i] / 2.0
		else:
			out[i] = clampf(p[i], vs[i] / 2.0, ws[i] - vs[i] / 2.0)
	return out

func _process(delta: float) -> void:
	if world == null or player == null:
		return
	_cam_pos = _cam_pos.lerp(_cam_target(), 1.0 - exp(-delta * 6.0))
	camera.global_position = _cam_pos.round()
	if busy or log_ui.visible or fishing.active():
		hud.set_prompt("")
		touch.prompt_active = false
		return
	var target = _current_target()
	var label := InputMgr.action_label()
	var text := ""
	if target is Dictionary:
		text = target["prompt"]
	elif target is Vector2:
		text = "Cast your line"
	if text != "" and label != "":
		text = "[%s] %s" % [label, text]
	hud.set_prompt(text)
	touch.prompt_active = target != null
	if Input.is_action_just_pressed("log"):
		toggle_log()
		return
	if Input.is_action_just_pressed("action") and target != null:
		if target is Dictionary:
			target["call"].call()
		elif target is Vector2:
			touch.fishing_mode = true
			fishing.start(player, world, target)

# Returns an interactable Dictionary, a Vector2 bobber target (water ahead), or null.
func _current_target() -> Variant:
	if player.sitting:
		return null
	var it = world.find_interactable(player.front_point(22.0))
	if it != null:
		return it
	if world.is_water(player.front_point(26.0)):
		var far: Vector2 = player.front_point(64.0)
		if world.is_water(far):
			return far
		return player.front_point(40.0) if world.is_water(player.front_point(40.0)) else player.front_point(26.0)
	return null

func toggle_log() -> void:
	if fishing != null and fishing.active():
		return
	if log_ui.visible:
		log_ui.close()
		return
	log_ui.open()
	player.frozen = true
	touch.enabled = false

func _on_log_closed() -> void:
	player.frozen = false
	touch.enabled = true

func _on_caught(_id: String, is_new: bool) -> void:
	if is_new:
		var n := GameState.clog_total()
		hud.toast("Collection Log: %d %s" % [n, "entry" if n == 1 else "entries"])
