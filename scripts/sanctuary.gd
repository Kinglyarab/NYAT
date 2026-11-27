extends "res://scripts/world_base.gd"
# The starter sanctuary: one cozy room at night, warm lamp light, a Rickety Wooden
# Chair to sit in and the Pond Portal. Stations and gardens arrive in later builds.

var main: Node

func build() -> void:
	size_tiles = Vector2i(16, 11)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var picks := {}
	for y in size_tiles.y:
		for x in size_tiles.x:
			picks[Vector2i(x, y)] = rng.randi_range(0, 3)
	set_floor(PixelArt.compose_tiles("sanctuary_floor", size_tiles.x, size_tiles.y,
		func(tx, ty): return PixelArt.wood_floor_img(picks[Vector2i(tx, ty)])))
	set_floor(PixelArt.back_wall(size_tiles.x))
	add_decal(PixelArt.window_tex(), t(4, 1.05))
	add_decal(PixelArt.window_tex(), t(12, 1.05))
	add_decal(PixelArt.sconce_tex(), t(6.5, 1.0))
	add_decal(PixelArt.sconce_tex(), t(9.5, 1.0))
	add_decal(PixelArt.rug_tex(160, 96), t(8, 6.4))

	add_bounds(Rect2(0, 70, world_size().x, world_size().y - 70))

	add_prop(PixelArt.bookshelf_tex(), t(1.5, 2.4), Vector2(44, 14))
	add_prop(PixelArt.sofa_tex(), t(8, 3.6), Vector2(72, 24))
	add_prop(PixelArt.lamp_tex(), t(10.9, 3.1), Vector2(10, 6))
	add_prop(PixelArt.plant_tex(), t(14.6, 2.6), Vector2(20, 8))
	add_prop(PixelArt.plant_tex(), t(0.8, 10.7), Vector2(20, 8))
	add_prop(PixelArt.plant_tex(), t(15.2, 10.7), Vector2(20, 8))

	var chair_base := t(3.2, 6.6)
	add_prop(PixelArt.chair_tex(), chair_base, Vector2(20, 8))
	add_interactable(Rect2(chair_base - Vector2(16, 30), Vector2(32, 44)), "Sit on the Rickety Wooden Chair",
		func(): main.player.sit_on(chair_base + Vector2(0, 2)))

	var portal_base := t(13.2, 8.7)
	var portal := add_prop(PixelArt.portal_frame(0), portal_base, Vector2(40, 10))
	var frames := []
	for i in 6:
		frames.append(PixelArt.portal_frame(i))
	animate(portal, frames, 8.0)
	add_interactable(Rect2(portal_base - Vector2(24, 40), Vector2(48, 56)), "Enter the Pond Portal",
		func(): main.go_to("pond", "portal"))

	spawns["default"] = t(6, 5.6)
	spawns["portal"] = portal_base + Vector2(0, 28)

	set_ambient(Color(0.5, 0.44, 0.6))
	add_light(t(10.9, 3.1) + Vector2(0, -48), Color(1.0, 0.76, 0.45), 1.25, 1.7)
	add_light(t(6.5, 1.0), Color(1.0, 0.8, 0.5), 0.7, 0.75)
	add_light(t(9.5, 1.0), Color(1.0, 0.8, 0.5), 0.7, 0.75)
	add_light(t(4, 1.2), Color(0.55, 0.65, 1.0), 0.35, 0.6)
	add_light(t(12, 1.2), Color(0.55, 0.65, 1.0), 0.35, 0.6)
	add_light(portal_base + Vector2(0, -30), Color(0.6, 0.45, 1.0), 0.95, 0.9)
