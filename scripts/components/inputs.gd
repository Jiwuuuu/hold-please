class_name Inputs
extends RefCounted
#one place to read input. uses the input map actions once they're added in
#the editor (move_left/right/up/down, interact); until then falls back to
#raw keys so the game runs either way. gameplay code calls Inputs.*, never Input.

static var _checked: bool = false
static var _has_actions: bool = false
static var _interact_was_down: bool = false
static var _debug_was_down: bool = false


static func move_vector() -> Vector2:
	if _use_actions():
		return Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var v: Vector2 = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.y += 1.0
	return v.limit_length(1.0)


#true only on the frame the key goes down. call it once per physics frame
#(player.gd does), calling it twice would eat the press.
static func interact_pressed() -> bool:
	if _use_actions():
		return Input.is_action_just_pressed("interact")
	var down: bool = Input.is_physical_key_pressed(KEY_E) or Input.is_physical_key_pressed(KEY_SPACE)
	var pressed: bool = down and not _interact_was_down
	_interact_was_down = down
	return pressed

#for testing purposes
static func debug_pressed() -> bool:
	if _use_actions():
		return Input.is_action_just_pressed("debug")
	var down: bool = Input.is_physical_key_pressed(KEY_Q)
	var pressed: bool = down and not _debug_was_down
	_debug_was_down = down
	return pressed

#true on the frame escape goes down. ui_cancel is a godot built-in action,
#so no raw-key fallback needed here.
static func cancel_pressed() -> bool:
	return Input.is_action_just_pressed("ui_cancel")


#check the input map once and remember the answer
static func _use_actions() -> bool:
	if not _checked:
		_checked = true
		_has_actions = InputMap.has_action("move_left") and InputMap.has_action("interact")
	return _has_actions
