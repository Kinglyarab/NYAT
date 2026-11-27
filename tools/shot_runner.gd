extends Node
# Dev tool: drives the game through the slice and saves screenshots to user://shots.
# Run: godot --path . res://tools/shot.tscn   (needs a display; xvfb-run works)

var main: Node
var out := "/tmp/nyat_shots/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	SaveSystem.wipe()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await _wait(1.6)
	await _shot("01_sanctuary")
	main.player.global_position = Vector2(3.2 * 32, 7.6 * 32)
	main.player.face(Vector2.UP)
	await _wait(0.6)
	await _shot("02_chair_prompt")
	main.player.sit_on(Vector2(3.2 * 32, 6.6 * 32 + 2))
	InputMgr._set_mode(InputMgr.Mode.TOUCH)
	await _wait(0.4)
	await _shot("03_sitting_touch")
	main.player.stand_up()
	InputMgr._set_mode(InputMgr.Mode.KEYBOARD)
	main.go_to("pond", "portal")
	await _wait(1.8)
	await _shot("04_pond")
	var w = main.world
	main.player.global_position = Vector2(w.pond_center.x, w.pier_rect.position.y + 14)
	main.player.face(Vector2.UP)
	await _wait(0.8)
	await _shot("05_pier_prompt")
	main.touch.fishing_mode = true
	main.fishing.start(main.player, w, main.player.front_point(64))
	await _wait(1.0)
	await _shot("06_waiting")
	main.fishing._wait = 0.0
	await _wait(0.9)
	main.fishing.hits = 2
	await _shot("07_hooked")
	main.fishing.fish_id = "lily_koi"
	main.fishing._catch()
	await _wait(0.5)
	await _shot("08_catch")
	main.fishing.state = 0
	main.player.frozen = false
	GameState.record_catch("bluegill")
	GameState.record_catch("sunbeam_pike")
	main.toggle_log()
	await _wait(0.4)
	await _shot("09_log")
	get_tree().quit()

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out + name + ".png")
	print("shot ", name)
