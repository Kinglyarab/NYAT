extends "res://scripts/world_base.gd"
# Tier 1 pond: Sunlit Park Pond at golden hour. A rounded pond with a pier, benches,
# lanterns and the portal home. Face the water and press the action button to cast.

var main: Node

const POND_ID := "sunlit_park_pond"
var pond_center := Vector2(13 * 32, 7.2 * 32)
var pond_half := Vector2(7 * 32, 4 * 32)
var pond_origin := Vector2.ZERO   # top-left of the pond image in world space
var pier_rect := Rect2()

func pond_id() -> String:
	return POND_ID

# Distance (px, approx) from the pond edge: positive inside the water.
func pond_d(p: Vector2) -> float:
	var dx := absf(p.x - pond_center.x) / pond_half.x
	var dy := absf(p.y - pond_center.y) / pond_half.y
	var s := pow(pow(dx, 4.0) + pow(dy, 4.0), 0.25)
	return (1.0 - s) * pond_half.y

func is_water(p: Vector2) -> bool:
	return pond_d(p) > 5.0 and not pier_rect.grow(-2).has_point(p)

func build() -> void:
	size_tiles = Vector2i(26, 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var picks := {}
	for y in size_tiles.y:
		for x in size_tiles.x:
			var r := rng.randf()
			picks[Vector2i(x, y)] = 3 if r < 0.08 else rng.randi_range(0, 2)
	var path_cells := {}
	for x in range(3, 14):
		path_cells[Vector2i(x, 13)] = true
	for y in range(12, 14):
		path_cells[Vector2i(12, y)] = true
		path_cells[Vector2i(13, y)] = true
	for y in range(13, 16):
		path_cells[Vector2i(3, y)] = true
	set_floor(PixelArt.compose_tiles("pond_floor", size_tiles.x, size_tiles.y,
		func(tx, ty):
			if path_cells.has(Vector2i(tx, ty)):
				return PixelArt.path_img((tx + ty) % 4)
			return PixelArt.grass_img(picks[Vector2i(tx, ty)])))

	# pond
	pond_origin = pond_center - pond_half - Vector2(8, 8)
	var pw := int(pond_half.x * 2 + 16)
	var ph := int(pond_half.y * 2 + 16)
	var inside := func(x: float, y: float) -> float: return pond_d(pond_origin + Vector2(x, y))
	var frames := []
	for i in 3:
		frames.append(PixelArt.pond_frame("pond_t1", pw, ph, inside, i))
	var pond_sprite := set_floor(frames[0], pond_origin)
	animate(pond_sprite, frames, 2.5)

	# pier: from the south shore up into the water
	var pier_w := 48
	var pier_top := pond_center.y + 20
	var pier_bottom := pond_center.y + pond_half.y + 6
	pier_rect = Rect2(pond_center.x - pier_w / 2.0, pier_top, pier_w, pier_bottom - pier_top)
	set_floor(PixelArt.pier_tex(pier_w, int(pier_rect.size.y)), pier_rect.position)

	_build_water_collision()
	add_bounds(Rect2(Vector2.ZERO, world_size()))

	# scenery
	for p in [[2, 3.2], [5.2, 2.6], [8.8, 2.3], [17.5, 2.4], [21, 2.7], [24.3, 3.3], [1.4, 8.5], [24.8, 9.2], [23.5, 15.6], [7.5, 15.8]]:
		add_prop(PixelArt.tree_tex(int(p[0] * 7) % 4), t(p[0], p[1]), Vector2(22, 10))
	add_prop(PixelArt.bench_tex(), t(9.3, 13.0), Vector2(50, 10))
	add_prop(PixelArt.bench_tex(), t(16.7, 13.0), Vector2(50, 10))
	var lantern_spots := [t(11.9, 12.2), t(14.1, 12.2), t(5.5, 11.8), t(20.5, 11.8)]
	for lp in lantern_spots:
		add_prop(PixelArt.lantern_tex(), lp, Vector2(8, 6))
	for rp in [t(6.4, 9.6), t(19.8, 4.6), t(19.4, 10.2), t(6.8, 4.4)]:
		add_prop(PixelArt.reeds_tex(), rp)

	var portal_base := t(3.5, 13.0)
	var portal := add_prop(PixelArt.portal_frame(0), portal_base, Vector2(40, 10))
	var pf := []
	for i in 6:
		pf.append(PixelArt.portal_frame(i))
	animate(portal, pf, 8.0)
	add_interactable(Rect2(portal_base - Vector2(24, 40), Vector2(48, 56)), "Return to your Sanctuary",
		func(): main.go_to("sanctuary", "portal"))

	spawns["default"] = portal_base + Vector2(0, 30)
	spawns["portal"] = portal_base + Vector2(0, 30)

	set_ambient(Color(1.0, 0.9, 0.78))
	for lp in lantern_spots:
		add_light(lp + Vector2(0, -44), Color(1.0, 0.78, 0.45), 0.55, 0.55)
	add_light(portal_base + Vector2(0, -30), Color(0.6, 0.45, 1.0), 0.6, 0.7)

# Water collision built from 16px cells, merged into horizontal runs.
func _build_water_collision() -> void:
	var cell := 16
	var x0 := int(pond_origin.x)
	var y0 := int(pond_origin.y)
	var w := int(pond_half.x * 2 + 16)
	var h := int(pond_half.y * 2 + 16)
	for cy in range(0, h, cell):
		var run_start := -1
		for cx in range(0, w + cell, cell):
			var c := Vector2(x0 + cx + cell / 2.0, y0 + cy + cell / 2.0)
			var solid := cx < w and pond_d(c) > -1.0 and not pier_rect.has_point(c)
			if solid and run_start < 0:
				run_start = cx
			elif not solid and run_start >= 0:
				add_solid(Rect2(x0 + run_start, y0 + cy, cx - run_start, cell))
				run_start = -1
