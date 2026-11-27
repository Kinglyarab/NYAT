extends CharacterBody2D
# The avatar: 4-way facing, walk cycle, sitting. Origin is at the feet (for y-sorting).

const SPEED := 112.0
const ACCEL := 900.0
const FRICTION := 1100.0

var facing := Vector2.DOWN
var frozen := false          # set while fishing or a menu is open
var sitting := false
var _anim_t := 0.0
var _frame := 0

var sprite: Sprite2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.offset = Vector2(-16, -46)
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 8)
	shape.shape = rect
	shape.position = Vector2(0, -3)
	add_child(shape)
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_update_sprite()

func _draw() -> void:
	# soft ground shadow
	draw_set_transform(Vector2(0, -1), 0, Vector2(1, 0.4))
	draw_circle(Vector2.ZERO, 10, Color(0, 0, 0, 0.28))

func move_input() -> Vector2:
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return v

func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO if frozen else move_input()
	if sitting:
		if input.length() > 0.3:
			stand_up()
		else:
			return
	if input.length() > 0.1:
		velocity = velocity.move_toward(input.normalized() * SPEED * minf(input.length() * 1.2, 1.0), ACCEL * delta)
		if absf(input.x) > absf(input.y) * 1.1:
			facing = Vector2.RIGHT if input.x > 0 else Vector2.LEFT
		elif absf(input.y) > 0.1:
			facing = Vector2.DOWN if input.y > 0 else Vector2.UP
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()
	if velocity.length() > 12.0:
		_anim_t += delta * (velocity.length() / SPEED) * 7.5
		_frame = [1, 0, 2, 0][int(_anim_t) % 4]
	else:
		_anim_t = 0.0
		_frame = 0
	_update_sprite()

func _update_sprite() -> void:
	if sprite == null:
		return
	var dir := "down"
	if facing == Vector2.UP:
		dir = "up"
	elif facing.x != 0:
		dir = "side"
	var f := 3 if sitting else _frame
	sprite.texture = PixelArt.avatar(dir, f)
	sprite.flip_h = facing == Vector2.LEFT
	sprite.offset.y = -46 - (1 if (f == 1 or f == 2) else 0) - (8 if sitting else 0)

func face(dir: Vector2) -> void:
	facing = dir
	_update_sprite()

func sit_on(seat_pos: Vector2) -> void:
	sitting = true
	velocity = Vector2.ZERO
	global_position = seat_pos
	facing = Vector2.DOWN
	_update_sprite()

func stand_up() -> void:
	sitting = false
	global_position += Vector2(0, 14)
	_update_sprite()

# Point a little in front of the feet, used for interactions and casting.
func front_point(dist: float = 22.0) -> Vector2:
	return global_position + Vector2(0, -6) + facing * dist
