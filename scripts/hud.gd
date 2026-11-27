extends Control
# HUD: Coins / Crowns / Tackle Bag (top-left), LOG button (top-right),
# interaction prompt (bottom-centre), toasts and the location banner.

const UiDraw := preload("res://scripts/ui_draw.gd")

signal log_pressed

var prompt := ""
var _toasts: Array = []          # [{text, t}]
var _banner := ""
var _banner_sub := ""
var _banner_t := 99.0
var log_btn: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameState.changed.connect(queue_redraw)
	log_btn = Button.new()
	log_btn.text = "LOG"
	log_btn.focus_mode = Control.FOCUS_NONE
	log_btn.add_theme_font_size_override("font_size", 12)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiDraw.BG
	sb.border_color = UiDraw.TRIM
	sb.set_border_width_all(2)
	sb.set_content_margin_all(4)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = UiDraw.BG2
	log_btn.add_theme_stylebox_override("normal", sb)
	log_btn.add_theme_stylebox_override("hover", sbh)
	log_btn.add_theme_stylebox_override("pressed", sbh)
	log_btn.add_theme_color_override("font_color", Color("f2e6c8"))
	log_btn.anchor_left = 1.0
	log_btn.anchor_right = 1.0
	log_btn.offset_left = -62
	log_btn.offset_right = -8
	log_btn.offset_top = 8
	log_btn.offset_bottom = 34
	log_btn.pressed.connect(func(): log_pressed.emit())
	add_child(log_btn)

func set_prompt(p: String) -> void:
	if p != prompt:
		prompt = p
		queue_redraw()

func toast(msg: String) -> void:
	for t in _toasts:
		if t["text"] == msg:
			t["t"] = 0.0
			return
	_toasts.append({"text": msg, "t": 0.0})
	if _toasts.size() > 3:
		_toasts.pop_front()

func banner(title: String, sub: String) -> void:
	_banner = title
	_banner_sub = sub
	_banner_t = 0.0

func _process(delta: float) -> void:
	_banner_t += delta
	for t in _toasts:
		t["t"] += delta
	_toasts = _toasts.filter(func(t): return t["t"] < 2.4)
	queue_redraw()

func _draw() -> void:
	# currencies
	var r := Rect2(8, 8, 176, 26)
	UiDraw.panel(self, r)
	UiDraw.coin(self, Vector2(22, 21))
	UiDraw.text(self, Vector2(32, 26), str(GameState.coins), 12, Color("f5d77a"))
	UiDraw.crown(self, Vector2(80, 21))
	UiDraw.text(self, Vector2(90, 26), str(GameState.crowns), 12, Color("d8c4ff"))
	UiDraw.bag(self, Vector2(134, 22))
	UiDraw.text(self, Vector2(144, 26), str(GameState.bag.size()), 12, Color("bfe8f2"))
	var vs := get_viewport_rect().size
	var ll := InputMgr.log_label()
	if ll != "":
		UiDraw.text(self, Vector2(vs.x - 35, 46), ll, 9, Color(1, 1, 1, 0.6), true)
	# prompt
	if prompt != "":
		var font := ThemeDB.fallback_font
		var w := font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 20
		var pr := Rect2(vs.x / 2.0 - w / 2.0, vs.y - 44, w, 24)
		UiDraw.panel(self, pr)
		UiDraw.text(self, Vector2(vs.x / 2.0, vs.y - 27), prompt, 12, Color("f2e6c8"), true)
	# toasts
	var y := 58.0
	for t in _toasts:
		var a := clampf(2.4 - t["t"], 0.0, 0.4) / 0.4
		UiDraw.text(self, Vector2(vs.x / 2.0, y), t["text"], 12, Color(1, 0.95, 0.8, a), true)
		y += 16
	# banner
	if _banner_t < 3.0:
		var a := clampf(minf(_banner_t * 3.0, (3.0 - _banner_t) * 2.0), 0.0, 1.0)
		var by := vs.y * 0.28
		draw_rect(Rect2(0, by - 22, vs.x, 40), Color(0.1, 0.06, 0.12, 0.55 * a))
		UiDraw.text(self, Vector2(vs.x / 2.0, by), _banner, 18, Color(1, 0.9, 0.65, a), true)
		UiDraw.text(self, Vector2(vs.x / 2.0, by + 14), _banner_sub, 10, Color(1, 1, 1, 0.8 * a), true)
