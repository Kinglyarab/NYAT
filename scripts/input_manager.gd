extends Node
# Adaptive input (autoload "InputMgr"): the last device used wins.
# Touching the screen switches to on-screen controls; pressing a key or a controller
# button switches straight back. Every device drives the same InputMap actions, so
# game code never asks which device is in use.

signal mode_changed(new_mode: int)

enum Mode { TOUCH, KEYBOARD, CONTROLLER }

var mode: int = Mode.KEYBOARD
var _last_touch_ms := -100000

func _ready() -> void:
	_setup_actions()
	if DisplayServer.is_touchscreen_available():
		mode = Mode.TOUCH

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_last_touch_ms = Time.get_ticks_msec()
		_set_mode(Mode.TOUCH)
	elif event is InputEventKey:
		if event.is_pressed() and not event.is_echo():
			_set_mode(Mode.KEYBOARD)
	elif event is InputEventMouseButton:
		# Touches also arrive as emulated mouse events; those must not flip the mode.
		var synthetic: bool = event.device == InputEvent.DEVICE_ID_EMULATION
		var after_touch: bool = Time.get_ticks_msec() - _last_touch_ms < 500
		if event.is_pressed() and not synthetic and not after_touch:
			_set_mode(Mode.KEYBOARD)
	elif event is InputEventJoypadButton:
		if event.is_pressed():
			_set_mode(Mode.CONTROLLER)
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) > 0.6:
			_set_mode(Mode.CONTROLLER)

func _set_mode(m: int) -> void:
	if m == mode:
		return
	mode = m
	mode_changed.emit(m)

func is_touch() -> bool:
	return mode == Mode.TOUCH

# Short label for the action button on the current device, used in prompts.
func action_label() -> String:
	match mode:
		Mode.TOUCH:
			return ""
		Mode.KEYBOARD:
			return "Space"
	return "A"

func log_label() -> String:
	match mode:
		Mode.TOUCH:
			return ""
		Mode.KEYBOARD:
			return "L"
	return "Y"

func cancel_label() -> String:
	match mode:
		Mode.TOUCH:
			return ""
		Mode.KEYBOARD:
			return "Esc"
	return "B"

func vibrate(ms: int) -> void:
	# Bonus layer only: works on native mobile builds, does nothing in Safari.
	if mode == Mode.TOUCH:
		Input.vibrate_handheld(ms)

func _setup_actions() -> void:
	var acts := ["move_left", "move_right", "move_up", "move_down", "action", "log", "cancel"]
	for a in acts:
		if InputMap.has_action(a):
			InputMap.erase_action(a)
		InputMap.add_action(a, 0.25)
	_key("move_left", KEY_LEFT); _key("move_left", KEY_A)
	_key("move_right", KEY_RIGHT); _key("move_right", KEY_D)
	_key("move_up", KEY_UP); _key("move_up", KEY_W)
	_key("move_down", KEY_DOWN); _key("move_down", KEY_S)
	_key("action", KEY_SPACE); _key("action", KEY_ENTER); _key("action", KEY_E)
	_key("log", KEY_TAB); _key("log", KEY_L)
	_key("cancel", KEY_ESCAPE)
	_btn("move_left", JOY_BUTTON_DPAD_LEFT)
	_btn("move_right", JOY_BUTTON_DPAD_RIGHT)
	_btn("move_up", JOY_BUTTON_DPAD_UP)
	_btn("move_down", JOY_BUTTON_DPAD_DOWN)
	_btn("action", JOY_BUTTON_A)
	_btn("log", JOY_BUTTON_Y)
	_btn("cancel", JOY_BUTTON_B)
	_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)

func _key(action: String, keycode: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = keycode
	InputMap.action_add_event(action, e)

func _btn(action: String, button: JoyButton) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	InputMap.action_add_event(action, e)

func _axis(action: String, axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	InputMap.action_add_event(action, e)
