extends Node
# Central game state (autoload "GameState").
# Every gameplay change goes through a method here so the same actions can later be
# sent to a server (Phase 2-3). All time goes through now_unix(), which will switch to
# server UTC time in the live game.

signal changed
signal caught(fish_id: String, is_new: bool)

var coins: int = 0
var crowns: int = 0
var clog: Dictionary = {}       # fish_id -> times caught (the Collection Log)
var bag: Array = []             # Tackle Bag: fresh catches not yet banked/sold
var location: String = "sanctuary"
var created_at: int = 0

var fish_db: Dictionary = {}
var ponds: Dictionary = {}
var tiers: Dictionary = {}
var rarities: Dictionary = {}

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	_load_data()
	created_at = now_unix()

func now_unix() -> int:
	# Phase 1 stand-in for server UTC time. Swap this one function for server time later.
	return int(Time.get_unix_time_from_system())

func _load_data() -> void:
	var f := FileAccess.open("res://data/fishing_drops.json", FileAccess.READ)
	if f == null:
		push_error("Missing data/fishing_drops.json")
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("fishing_drops.json did not parse")
		return
	fish_db = data.get("fish", {})
	ponds = data.get("ponds", {})
	tiers = data.get("tiers", {})
	rarities = data.get("rarities", {})

func fish(id: String) -> Dictionary:
	return fish_db.get(id, {})

func rarity_color(id: String) -> Color:
	var r: String = fish(id).get("rarity", "common")
	return Color(rarities.get(r, {}).get("color", "#ffffff"))

func rarity_label(id: String) -> String:
	var r: String = fish(id).get("rarity", "common")
	return rarities.get(r, {}).get("label", r)

func odds_text(id: String) -> String:
	var f := fish(id)
	if f.has("one_in"):
		return "1 in %d" % int(f["one_in"])
	return "Common"

# Rolls one catch. Rarest entries roll first ("1 in N" each); if none hit,
# a common is picked by weight.
func roll_fish(pond_id: String) -> String:
	var ids: Array = ponds.get(pond_id, {}).get("fish", [])
	var rares: Array = []
	var commons: Array = []
	for id in ids:
		if fish(id).has("one_in"):
			rares.append(id)
		else:
			commons.append(id)
	rares.sort_custom(func(a, b): return int(fish(a)["one_in"]) > int(fish(b)["one_in"]))
	for id in rares:
		if _rng.randf() * float(fish(id)["one_in"]) < 1.0:
			return id
	var total := 0.0
	for id in commons:
		total += float(fish(id).get("weight", 1))
	var pick := _rng.randf() * total
	for id in commons:
		pick -= float(fish(id).get("weight", 1))
		if pick <= 0.0:
			return id
	return commons.back() if not commons.is_empty() else ""

func record_catch(id: String) -> bool:
	var is_new := not clog.has(id)
	clog[id] = int(clog.get(id, 0)) + 1
	bag.append(id)
	caught.emit(id, is_new)
	changed.emit()
	SaveSystem.save_game()
	return is_new

func clog_total() -> int:
	return clog.size()

func clog_count_for_pond(pond_id: String) -> int:
	var n := 0
	for id in ponds.get(pond_id, {}).get("fish", []):
		if clog.has(id):
			n += 1
	return n

func set_location(loc: String) -> void:
	location = loc
	SaveSystem.save_game()
