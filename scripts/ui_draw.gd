extends RefCounted
# Shared pixel-style UI drawing (dark plum panels, square corners, gold trim).

const BG := Color("2a1d36")
const BG2 := Color("3a2848")
const TRIM := Color("d4a24c")
const INK := Color("1e1520")

static func panel(ci: CanvasItem, r: Rect2, trim: Color = TRIM) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(0, 3), r.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(r.grow(2), INK)
	ci.draw_rect(r, BG)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), BG2.lightened(0.15))
	ci.draw_rect(r, trim, false, 2.0)
	for c in [r.position, Vector2(r.end.x - 4, r.position.y), Vector2(r.position.x, r.end.y - 4), r.end - Vector2(4, 4)]:
		ci.draw_rect(Rect2(c, Vector2(4, 4)), trim.lightened(0.25))

static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color, center := false) -> void:
	var font := ThemeDB.fallback_font
	var p := pos
	if center:
		p.x -= font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / 2.0
	ci.draw_string(font, p + Vector2(1, 1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.6 * col.a))
	ci.draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

static func coin(ci: CanvasItem, c: Vector2) -> void:
	ci.draw_circle(c, 6, INK)
	ci.draw_circle(c, 5, Color("e8b84a"))
	ci.draw_circle(c, 3, Color("f5d77a"))
	ci.draw_rect(Rect2(c + Vector2(-1, -2), Vector2(2, 4)), Color("b8862a"))

static func crown(ci: CanvasItem, c: Vector2) -> void:
	var pts := PackedVector2Array([c + Vector2(-6, 4), c + Vector2(-6, -3), c + Vector2(-3, 0), c + Vector2(0, -5), c + Vector2(3, 0), c + Vector2(6, -3), c + Vector2(6, 4)])
	ci.draw_colored_polygon(pts, Color("b48cff"))
	ci.draw_polyline(pts + PackedVector2Array([pts[0]]), INK, 1.0)
	ci.draw_rect(Rect2(c + Vector2(-1, 0), Vector2(2, 2)), Color("ffe08a"))

static func bag(ci: CanvasItem, c: Vector2) -> void:
	ci.draw_rect(Rect2(c + Vector2(-6, -3), Vector2(12, 9)), INK)
	ci.draw_rect(Rect2(c + Vector2(-5, -2), Vector2(10, 7)), Color("4f9fc4"))
	ci.draw_rect(Rect2(c + Vector2(-5, -2), Vector2(10, 2)), Color("8fd0e0"))
	ci.draw_rect(Rect2(c + Vector2(-3, -6), Vector2(6, 2)), INK)
