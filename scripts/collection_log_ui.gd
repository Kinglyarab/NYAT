extends Control
# Collection Log overlay. One tab per pond (only Sunlit Park Pond exists so far).
# Logged entries show their art and count; unlogged ones show a dark silhouette.

const UiDraw := preload("res://scripts/ui_draw.gd")

signal closed

var pond_id := "sunlit_park_pond"
var close_btn: Button
var _t := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	close_btn = Button.new()
	close_btn.text = "X"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.flat = true
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", Color("f2e6c8"))
	close_btn.pressed.connect(close)
	add_child(close_btn)

func open() -> void:
	visible = true
	_t = 0.0
	queue_redraw()

func close() -> void:
	if visible:
		visible = false
		closed.emit()

func _panel_rect() -> Rect2:
	var vs := get_viewport_rect().size
	var w := minf(vs.x - 24, 440)
	var h := minf(vs.y - 24, 270)
	return Rect2(vs / 2.0 - Vector2(w, h) / 2.0, Vector2(w, h))

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var r := _panel_rect()
	close_btn.position = Vector2(r.end.x - 34, r.position.y + 4)
	close_btn.size = Vector2(30, 26)
	if _t > 0.1 and (Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("log")):
		close()
	queue_redraw()

func _draw() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vs), Color(0.05, 0.03, 0.08, 0.6))
	var r := _panel_rect()
	UiDraw.panel(self, r)
	UiDraw.text(self, r.position + Vector2(14, 24), "Collection Log", 16, Color("f5d77a"))
	var pond: Dictionary = GameState.ponds.get(pond_id, {})
	var tier := int(pond.get("tier", 1))
	var rot: String = GameState.tiers.get(str(tier), {}).get("rotation", "")
	var ids: Array = pond.get("fish", [])
	var got := GameState.clog_count_for_pond(pond_id)
	# tab
	var tab := Rect2(r.position + Vector2(12, 34), Vector2(r.size.x - 24, 22))
	draw_rect(tab, Color("3a2848"))
	draw_rect(tab, Color("d4a24c"), false, 1.0)
	UiDraw.text(self, tab.position + Vector2(8, 15), "%s  ·  Tier %d  ·  rotates %s" % [pond.get("name", "?"), tier, rot], 11, Color("f2e6c8"))
	UiDraw.text(self, Vector2(tab.end.x - 8 - 40, tab.position.y + 15), "%d/%d" % [got, ids.size()], 11, Color("7fd36b") if got == ids.size() else Color("f2e6c8"))
	# grid
	var cols := 5
	var gap := 6.0
	var cw := (r.size.x - 24 - gap * (cols - 1)) / cols
	var ch := 62.0
	var top := tab.end.y + 8
	for i in ids.size():
		var id: String = ids[i]
		var cx := r.position.x + 12 + (i % cols) * (cw + gap)
		var cy := top + (i / cols) * (ch + gap)
		var cell := Rect2(cx, cy, cw, ch)
		var have := GameState.clog.has(id)
		draw_rect(cell, Color("231830"))
		draw_rect(cell, GameState.rarity_color(id) if have else Color("4a3a50"), false, 1.0)
		var icon := PixelArt.fish_icon(id)
		var isz := Vector2(icon.get_width(), icon.get_height()) * 1.5
		var ip := Vector2(cx + cw / 2.0 - isz.x / 2.0, cy + 8)
		if have:
			draw_texture_rect(icon, Rect2(ip, isz), false)
			UiDraw.text(self, Vector2(cx + cw / 2.0, cy + ch - 16), GameState.fish(id).get("name", "?"), 9, GameState.rarity_color(id), true)
			UiDraw.text(self, Vector2(cx + cw / 2.0, cy + ch - 5), "x%d" % int(GameState.clog[id]), 9, Color(1, 1, 1, 0.7), true)
		else:
			draw_texture_rect(icon, Rect2(ip, isz), false, Color(0, 0, 0, 0.55))
			UiDraw.text(self, Vector2(cx + cw / 2.0, cy + ch - 16), "???", 9, Color(1, 1, 1, 0.4), true)
			UiDraw.text(self, Vector2(cx + cw / 2.0, cy + ch - 5), GameState.odds_text(id), 9, Color(1, 1, 1, 0.3), true)
	# footer
	var t2 = GameState.tiers.get("2", {}).get("clog_required", null)
	var t2s := "TBD" if t2 == null else str(t2)
	UiDraw.text(self, Vector2(r.position.x + 14, r.end.y - 12), "Total log entries: %d   ·   Tier 2 portal unlocks at: %s entries" % [GameState.clog_total(), t2s], 10, Color(1, 1, 1, 0.65))
