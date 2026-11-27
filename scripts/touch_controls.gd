extends Control
# On-screen controls (shown in TOUCH mode): floating joystick on the left half,
# ACTION button bottom-right. Drives the same InputMap actions as keyboard/controller.
# While fishing, the ACTION hit area grows to match the big fishing button.

const JOY_MAX := 36.0
const ACT_R := 30.0

var enabled := true:
	set(v):
		enabled = v
		if not v:
			_reset()
var fishing_mode := false      # big button is drawn by FishingUI instead
var prompt_active := false     # ACTION glows when something is interactable

var joy_id := -1
var joy_origin := Vector2.ZERO
var joy_pos := Vector2.ZERO
var act_id := -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	InputMgr.mode_changed.connect(func(_m): _reset(); queue_redraw())

func act_center() -> Vector2:
	return get_viewport_rect().size + Vector2(-78, -78)

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			_press(e.index, e.position)
		else:
			_release(e.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == joy_id:
			joy_pos = d.position
			_apply_joy()

func _press(idx: int, pos: Vector2) -> void:
	var vs := get_viewport_rect().size
	var r := 56.0 if fishing_mode else ACT_R + 12.0
	if act_id == -1 and pos.distance_to(act_center()) <= r:
		act_id = idx
		Input.action_press("action")
	elif joy_id == -1 and pos.x < vs.x * 0.5 and pos.y > vs.y * 0.2:
		joy_id = idx
		joy_origin = pos
		joy_pos = pos
		_apply_joy()
	queue_redraw()

func _release(idx: int) -> void:
	if idx == act_id:
		act_id = -1
		Input.action_release("action")
	elif idx == joy_id:
		joy_id = -1
		_apply_joy()
	queue_redraw()

func _apply_joy() -> void:
	var d := Vector2.ZERO
	if joy_id != -1:
		var v := joy_pos - joy_origin
		if v.length() > JOY_MAX:
			joy_origin = joy_pos - v.normalized() * JOY_MAX   # base follows the thumb
			v = joy_pos - joy_origin
		if v.length() > 3.0:
			d = v / JOY_MAX
	_axis("move_left", "move_right", d.x)
	_axis("move_up", "move_down", d.y)
	queue_redraw()

func _axis(neg: String, pos: String, value: float) -> void:
	if value > 0.05:
		Input.action_press(pos, value)
		Input.action_release(neg)
	elif value < -0.05:
		Input.action_press(neg, -value)
		Input.action_release(pos)
	else:
		Input.action_release(neg)
		Input.action_release(pos)

func _reset() -> void:
	if act_id != -1:
		Input.action_release("action")
	act_id = -1
	joy_id = -1
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)

func _process(_d: float) -> void:
	if InputMgr.is_touch():
		queue_redraw()

func _draw() -> void:
	if not InputMgr.is_touch() or not enabled:
		return
	if joy_id != -1:
		draw_circle(joy_origin, JOY_MAX + 6, Color(0, 0, 0, 0.25))
		draw_arc(joy_origin, JOY_MAX + 6, 0, TAU, 32, Color(1, 1, 1, 0.35), 2.0)
		var knob := joy_origin + (joy_pos - joy_origin).limit_length(JOY_MAX)
		draw_circle(knob, 16, Color(1, 1, 1, 0.45))
	else:
		var vs := get_viewport_rect().size
		var hint := Vector2(70, vs.y - 70)
		draw_arc(hint, JOY_MAX, 0, TAU, 32, Color(1, 1, 1, 0.14), 2.0)
		draw_circle(hint, 12, Color(1, 1, 1, 0.1))
	if fishing_mode:
		return
	var c := act_center()
	var down := act_id != -1
	var glow := prompt_active
	draw_circle(c + Vector2(0, 3), ACT_R, Color(0, 0, 0, 0.35))
	draw_circle(c, ACT_R, Color("5a3a20") if not glow else Color("8a5a2a"))
	draw_circle(c, ACT_R - 3, Color("d4a24c").darkened(0.25 if down else 0.0) if glow else Color("7a5a3a"))
	draw_arc(c, ACT_R, 0, TAU, 40, Color("ffe0a0") if glow else Color(1, 1, 1, 0.4), 2.0)
	var font := ThemeDB.fallback_font
	var s := "ACTION"
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	draw_string(font, c + Vector2(-w / 2.0, 4), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
