extends Node
# Local JSON save (autoload "SaveSystem") with a versioned schema.
# To change the save format: bump VERSION and add a step in _migrate().

const PATH := "user://nyat_save.json"
const VERSION := 1

var loaded := false

func save_game() -> void:
	var data := {
		"version": VERSION,
		"saved_at": GameState.now_unix(),
		"created_at": GameState.created_at,
		"coins": GameState.coins,
		"crowns": GameState.crowns,
		"clog": GameState.clog,
		"bag": GameState.bag,
		"location": GameState.location,
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write save file")
		return
	f.store_string(JSON.stringify(data))

func load_game() -> bool:
	if not FileAccess.file_exists(PATH):
		return false
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("Save file unreadable; starting fresh")
		return false
	data = _migrate(data)
	GameState.coins = int(data.get("coins", 0))
	GameState.crowns = int(data.get("crowns", 0))
	GameState.created_at = int(data.get("created_at", GameState.now_unix()))
	GameState.location = str(data.get("location", "sanctuary"))
	var clog := {}
	for k in data.get("clog", {}):
		if GameState.fish_db.has(k):
			clog[k] = int(data["clog"][k])
	GameState.clog = clog
	var bag := []
	for id in data.get("bag", []):
		if GameState.fish_db.has(id):
			bag.append(id)
	GameState.bag = bag
	loaded = true
	GameState.changed.emit()
	return true

func _migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 1))
	# Example for later:
	# if v == 1:
	#     data["new_field"] = default
	#     v = 2
	data["version"] = v
	return data

func wipe() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
