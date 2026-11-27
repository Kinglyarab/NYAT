extends Node
var _failed := false
# Headless flow test: cast, wait for a bite, miss a beat, then hit 3 beats -> catch.
var main: Node
func _ready() -> void:
	SaveSystem.wipe()
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	await get_tree().create_timer(0.5).timeout
	main.go_to("pond", "portal")
	await get_tree().create_timer(1.0).timeout
	var w = main.world
	main.player.global_position = Vector2(w.pond_center.x, w.pier_rect.position.y + 14)
	main.player.face(Vector2.UP)
	await get_tree().process_frame
	_check(main._current_target() is Vector2, "should be able to cast from the pier")
	await _press()
	var f = main.fishing
	_check(f.state != 0, "cast should start fishing")
	while f.state != f.S.HOOKED:
		await get_tree().process_frame
	print("hooked fish=", f.fish_id, " tempo=", f.tempo_name)
	# deliberately off-beat tap: should reset, not lose the fish
	while f.clock < f.beat_time(0) - f.interval * 0.5:
		await get_tree().process_frame
	await _press()
	_check(f.state == f.S.HOOKED and f.hits == 0, "miss keeps the fish hooked")
	# now hit three beats
	for k in range(1, 4):
		while f.clock < f.beat_time(k) - 0.02:
			await get_tree().process_frame
		await _press()
		print("beat ", k, " hits=", f.hits, " state=", f.state)
	_check(f.state == f.S.CAUGHT, "three good beats should catch")
	_check(GameState.clog.has(f.fish_id), "catch is logged")
	await get_tree().create_timer(0.4).timeout
	await _press()
	print("state after dismiss=", f.state, " t=", f._t)
	_check(f.state == f.S.IDLE, "card dismiss returns to idle")
	# save round-trip
	var id: String = f.fish_id
	GameState.clog = {}
	SaveSystem.load_game()
	_check(GameState.clog.has(id), "save/load keeps the log")
	if not _failed:
		print("FLOW TEST PASSED")
	get_tree().quit(1 if _failed else 0)

func _press() -> void:
	await get_tree().process_frame
	Input.action_press("action")
	await get_tree().process_frame
	await get_tree().process_frame
	Input.action_release("action")
	await get_tree().process_frame

func _check(ok: bool, what: String) -> void:
	if ok:
		print("ok: ", what)
	else:
		print("FAIL: ", what)
		_failed = true
