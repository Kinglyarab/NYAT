extends Control
# The big pulsing fishing button and the catch card.
# Same spot as the touch ACTION button so the thumb never moves. Keyboard/controller
# players see it too, as the visual beat indicator.

const UiDraw := preload("res://scripts/ui_draw.gd")

var fishing: Node   # fishing.gd
var hud: Control
var _click := false
var _card_id := ""
var _card_new := false
var _card_t := 0.0

const BTN_R := 46.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func btn_center() -> Vector2:
	return get_viewport_rect().size + Vector2(-78, -78)

func cancel_center() -> Vector2:
	return btn_center() + Vector2(-82, 22)

func consume_click() -> bool:
	var c := _click
	_click = false
	return c

func toast(msg: String) -> void:
	hud.toast(msg)

func show_state() -> void:
	queue_redraw()

func show_catch(id: String, is_new: bool) -> void:
	_card_id = id
	_card_new = is_new
	_card_t = 0.0

func _fishing_state() -> int:
	return fishing.state if fishing != null else 0

func _input(event: InputEvent) -> void:
	var st := _fishing_state()
	if st == 0:
		return
	var pos := Vector2.INF
	if event is InputEventScreenTouch and event.pressed:
		pos = event.position
		if st == fishing.S.CAUGHT:
			_click = true
			return
		if pos.distance_to(cancel_center()) <= 22.0:
			fishing.cancel()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return
		pos = event.position
		if st == fishing.S.CAUGHT:
			_click = true
		elif pos.distance_to(btn_center()) <= BTN_R + 8:
			_click = true
		elif pos.distance_to(cancel_center()) <= 20.0:
			fishing.cancel()

func _process(delta: float) -> void:
	if _fishing_state() != 0:
		_card_t += delta
		queue_redraw()
	elif visible:
		queue_redraw()

func _draw() -> void:
	var st := _fishing_state()
	if st == 0:
		return
	var font := ThemeDB.fallback_font
	if st == fishing.S.CAUGHT:
		_draw_card(font)
		return
	var c := btn_center()
	var t: float = fishing.clock
	if fishing.miss_flash > 0.0:
		c.x += sin(t * 60.0) * 3.0
	var label := InputMgr.action_label()
	if label == "":
		label = "TAP"
	match st:
		fishing.S.CASTING, fishing.S.WAITING:
			var r := BTN_R + sin(t * 2.5) * 1.5
			draw_circle(c + Vector2(0, 3), r, Color(0, 0, 0, 0.35))
			draw_circle(c, r, Color("2c3550"))
			draw_circle(c, r - 4, Color("3e4c72"))
			draw_arc(c, r, 0, TAU, 48, Color("8fa3d0"), 2.0)
			_text(font, c + Vector2(0, 5), "WAIT", 16, Color("c8d4f0"))
			_text(font, c + Vector2(0, -BTN_R - 14), "Watch the bobber...", 11, Color(1, 1, 1, 0.9))
		fishing.S.HOOKED:
			var prog: float = fishing.beat_progress()
			var ring_r := BTN_R + 4 + (1.0 - prog) * 46.0
			draw_arc(c, ring_r, 0, TAU, 56, Color(1, 0.95, 0.8, 0.35 + prog * 0.6), 3.0)
			var base := Color("b8322a")
			if fishing.beat_flash > 0.0:
				base = Color("ff5a44")
			draw_circle(c + Vector2(0, 3), BTN_R, Color(0, 0, 0, 0.35))
			draw_circle(c, BTN_R, base.darkened(0.25))
			draw_circle(c, BTN_R - 4, base)
			draw_circle(c + Vector2(-10, -12), 10, Color(1, 1, 1, 0.12))
			var border := Color("ffd8a0")
			if fishing.hit_flash > 0.0:
				border = Color("7dff8a")
			elif fishing.miss_flash > 0.0:
				border = Color("ffffff")
			draw_arc(c, BTN_R, 0, TAU, 56, border, 3.0)
			_text(font, c + Vector2(0, 6), label, 18 if label.length() <= 3 else 14, Color.WHITE)
			for i in 3:
				var pc := c + Vector2((i - 1) * 22, -BTN_R - 16)
				draw_circle(pc, 7, Color("1e1520"))
				draw_circle(pc, 5, Color("ffd84a") if i < fishing.hits else Color("4a3a50"))
			_text(font, c + Vector2(0, -BTN_R - 32), "Tap on the beat  (%s)" % fishing.tempo_name, 11, Color(1, 1, 1, 0.95))
	# cancel
	var cc := cancel_center()
	draw_circle(cc, 15, Color(0, 0, 0, 0.45))
	draw_arc(cc, 15, 0, TAU, 24, Color(1, 1, 1, 0.6), 1.5)
	_text(font, cc + Vector2(0, 5), "X", 13, Color(1, 1, 1, 0.85))
	var cl := InputMgr.cancel_label()
	if cl != "":
		_text(font, cc + Vector2(0, 28), cl, 9, Color(1, 1, 1, 0.7))

func _draw_card(font: Font) -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0, 0, 0, 0.35))
	var k := clampf(_card_t / 0.18, 0.0, 1.0)
	var sz := Vector2(240, 150) * (0.85 + 0.15 * k)
	var r := Rect2(vs / 2.0 - sz / 2.0, sz)
	var col := GameState.rarity_color(_card_id)
	var rar: String = GameState.fish(_card_id).get("rarity", "common")
	if rar != "common":
		for i in 12:
			var a := _card_t * 0.6 + i * TAU / 12.0
			var p1 := vs / 2.0 + Vector2(cos(a), sin(a)) * 60.0
			var p2 := vs / 2.0 + Vector2(cos(a), sin(a)) * 170.0
			draw_line(p1, p2, Color(col.r, col.g, col.b, 0.18), 10.0)
	UiDraw.panel(self, r, col)
	var icon := PixelArt.fish_icon(_card_id)
	var isz := Vector2(icon.get_width(), icon.get_height()) * 3.0
	draw_texture_rect(icon, Rect2(Vector2(vs.x / 2.0 - isz.x / 2.0, r.position.y + 14), isz), false)
	var y := r.position.y + 14 + isz.y + 18
	_text(font, Vector2(vs.x / 2.0, y), GameState.fish(_card_id).get("name", "?"), 16, col)
	_text(font, Vector2(vs.x / 2.0, y + 16), "%s  ·  %s" % [GameState.rarity_label(_card_id), GameState.odds_text(_card_id)], 11, Color(1, 1, 1, 0.85))
	if _card_new:
		var pulse := 0.75 + 0.25 * sin(_card_t * 6.0)
		_text(font, Vector2(vs.x / 2.0, y + 32), "NEW COLLECTION LOG ENTRY!", 11, Color(1.0, 0.85, 0.3, pulse))
	else:
		_text(font, Vector2(vs.x / 2.0, y + 32), "Caught x%d" % int(GameState.clog.get(_card_id, 0)), 11, Color(1, 1, 1, 0.7))
	var cont := "Tap to continue" if InputMgr.is_touch() else "%s to continue" % InputMgr.action_label()
	if _card_t > 0.3:
		_text(font, Vector2(vs.x / 2.0, r.end.y + 16), cont, 10, Color(1, 1, 1, 0.75))

func _text(font: Font, center_baseline: Vector2, s: String, size: int, col: Color) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, center_baseline + Vector2(-w / 2.0 + 1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.6 * col.a))
	draw_string(font, center_baseline - Vector2(w / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
