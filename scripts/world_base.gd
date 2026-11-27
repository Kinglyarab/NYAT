extends Node2D
# Shared room plumbing: floor, y-sorted props with collision, interactables, lights.
# Sanctuary and Pond extend this.

const TILE := 32

var size_tiles := Vector2i(16, 11)
var objects: Node2D            # y-sorted layer (props + player)
var floor_layer: Node2D
var interactables: Array = []  # [{rect: Rect2, prompt: String, call: Callable}]
var spawns: Dictionary = {}    # name -> Vector2
var modulate_node: CanvasModulate
var _animated: Array = []      # [{sprite, frames: Array, fps}]
var _anim_t := 0.0

func _init() -> void:
	floor_layer = Node2D.new()
	floor_layer.name = "Floor"
	add_child(floor_layer)
	objects = Node2D.new()
	objects.name = "Objects"
	objects.y_sort_enabled = true
	add_child(objects)

func world_size() -> Vector2:
	return Vector2(size_tiles) * TILE

func t(x: float, y: float) -> Vector2:
	return Vector2(x * TILE, y * TILE)

func set_floor(tex: Texture2D, pos := Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.position = pos
	floor_layer.add_child(s)
	return s

func add_decal(tex: Texture2D, center: Vector2) -> Sprite2D:
	# flat on the floor, never sorted above anyone
	var s := Sprite2D.new()
	s.texture = tex
	s.position = center
	floor_layer.add_child(s)
	return s

# Adds a sorted prop whose bottom-centre sits at `base`. `solid` is a collision box
# size centred on the base (Vector2.ZERO = walk-through).
func add_prop(tex: Texture2D, base: Vector2, solid := Vector2.ZERO, solid_offset := Vector2.ZERO) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.offset = Vector2(-tex.get_width() / 2.0, -tex.get_height())
	s.position = base
	objects.add_child(s)
	if solid != Vector2.ZERO:
		add_solid(Rect2(base + solid_offset - Vector2(solid.x / 2.0, solid.y), solid))
	return s

func add_solid(r: Rect2) -> void:
	var body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	cs.position = r.position + r.size / 2.0
	body.add_child(cs)
	add_child(body)

func add_bounds(r: Rect2) -> void:
	var th := 64.0
	add_solid(Rect2(r.position.x - th, r.position.y - th, r.size.x + th * 2, th))
	add_solid(Rect2(r.position.x - th, r.end.y, r.size.x + th * 2, th))
	add_solid(Rect2(r.position.x - th, r.position.y, th, r.size.y))
	add_solid(Rect2(r.end.x, r.position.y, th, r.size.y))

func add_interactable(r: Rect2, prompt: String, cb: Callable) -> void:
	interactables.append({"rect": r, "prompt": prompt, "call": cb})

func add_light(pos: Vector2, color: Color, energy: float, scale_: float) -> PointLight2D:
	var l := PointLight2D.new()
	l.texture = PixelArt.light_tex()
	l.position = pos
	l.color = color
	l.energy = energy
	l.texture_scale = scale_
	add_child(l)
	return l

func set_ambient(c: Color) -> void:
	modulate_node = CanvasModulate.new()
	modulate_node.color = c
	add_child(modulate_node)

func animate(sprite: Sprite2D, frames: Array, fps: float) -> void:
	_animated.append({"sprite": sprite, "frames": frames, "fps": fps})

func _process(delta: float) -> void:
	_anim_t += delta
	for a in _animated:
		var frames: Array = a["frames"]
		a["sprite"].texture = frames[int(_anim_t * a["fps"]) % frames.size()]

# Closest interactable whose rect contains the point in front of the player.
func find_interactable(p: Vector2) -> Variant:
	var best = null
	var best_d := INF
	for it in interactables:
		var r: Rect2 = it["rect"]
		if r.grow(6).has_point(p):
			var d := r.get_center().distance_to(p)
			if d < best_d:
				best_d = d
				best = it
	return best

# Override in rooms that have water.
func is_water(_p: Vector2) -> bool:
	return false

func pond_id() -> String:
	return ""
