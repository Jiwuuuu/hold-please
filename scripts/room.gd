extends Node3D
#the exchange room. jacks on the dead side wall, sockets on the living side,
#the operator carries cables across the floor between them. wires the pieces
#together and drives the camera follow.

const CABLE_SCENE: PackedScene = preload("res://scenes/cable.tscn")

@export var camera_follow_speed: float = 3.0
#how far the camera focus may drift from room center (x and z) before it
#stops, so the walls stay framed and the void outside never shows
@export var camera_limit_min: Vector2 = Vector2(-1.8, -1.4)
@export var camera_limit_max: Vector2 = Vector2(1.8, 1.4)
#the desk close-up: how long the glide takes. the zoom itself lives on the
#desk's ViewPoint camera (its size), so you preview the exact framing in-editor
@export var desk_transition_time: float = 0.9

var _cam_offset: Vector3
var _home_basis: Basis
var _home_size: float
#desk mode covers the whole trip: fly in, sit, fly back out
var _desk_mode: bool = false
#true only once the fly-in has landed, so exit input works when the view is settled
var _at_desk: bool = false
var _cam_tween: Tween

@onready var _player: Player = %Player
@onready var _camera: Camera3D = %Camera
@onready var _desk: Desk = %Desk


func _ready() -> void:
	#the camera is moved by hand in _process, so keep godot's automatic
	#physics interpolation off for it (the 4.7 docs say to do this)
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_cam_offset = _camera.global_position - _focus()
	_home_basis = _camera.global_transform.basis
	_home_size = _camera.size
	_desk.opened.connect(_on_desk_opened)
	for jack: Node in get_tree().get_nodes_in_group("jacks"):
		if jack is Jack:
			(jack as Jack).plug_grabbed.connect(_on_plug_grabbed)
		elif jack is Anchor:
			(jack as Anchor).plug_grabbed.connect(_on_plug_grabbed)
	for socket: Node in get_tree().get_nodes_in_group("sockets"):
		if socket is Socket:
			(socket as Socket).plug_seated.connect(_on_plug_seated)
		elif socket is Anchor:
			(socket as Anchor).plug_seated.connect(_on_plug_seated)


#glide toward the player's drawn position, not the physics tick, or it judders
func _process(delta: float) -> void:
	if _desk_mode:
		#the player script skips its own interact check while frozen,
		#so reading the press here keeps it once per frame
		if _at_desk and (Inputs.interact_pressed() or Inputs.cancel_pressed()):
			_close_desk()
		return
	var target: Vector3 = _focus() + _cam_offset
	var weight: float = 1.0 - exp(-camera_follow_speed * delta)
	_camera.global_position = _camera.global_position.lerp(target, weight)


#where the camera should look: the player, clamped inside the room, on the floor
func _focus() -> Vector3:
	var p: Vector3 = _player.get_global_transform_interpolated().origin
	return Vector3(
		clampf(p.x, camera_limit_min.x, camera_limit_max.x),
		0.0,
		clampf(p.z, camera_limit_min.y, camera_limit_max.y)
	)


#fly the camera down to the desk close-up and freeze the operator
func _on_desk_opened(desk: Desk) -> void:
	_desk_mode = true
	_player.controls_enabled = false
	var vp: Camera3D = desk.view_point()
	_start_cam_tween(vp.global_transform, vp.size)
	_cam_tween.finished.connect(func() -> void: _at_desk = true)


#pull back out to the room and hand control back once the glide lands
func _close_desk() -> void:
	_at_desk = false
	_start_cam_tween(Transform3D(_home_basis, _focus() + _cam_offset), _home_size)
	_cam_tween.finished.connect(func() -> void:
		_desk_mode = false
		_player.controls_enabled = true
	)


#one tween moves the camera pose and zoom together, killing any older one.
#tweening global_transform blends the rotation properly (interpolate_with
#under the hood), and the crisp pass camera mirrors it every frame for free.
func _start_cam_tween(target: Transform3D, target_size: float) -> void:
	if _cam_tween != null:
		_cam_tween.kill()
	_cam_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_parallel()
	_cam_tween.tween_property(_camera, "global_transform", target, desk_transition_time)
	_cam_tween.tween_property(_camera, "size", target_size, desk_transition_time)


#I changed these ones to "Node"
#this way they also work with the new "Anchor" class

#a jack gave out its plug: spawn a cable from that jack to the player's hands
func _on_plug_grabbed(jack: Node) -> void:
	var cable: Cable = CABLE_SCENE.instantiate()
	cable.setup(jack.cable_anchor(), _player.carry_point())
	add_child(cable)
	_player.carried_cable = cable
	_player.carried_cable.message = jack.message


#the plug went into a socket: drop it there and blink the socket
func _on_plug_seated(socket: Node) -> void:
	if _player.carried_cable == null:
		return
	socket.message += _player.carried_cable.message
	_player.carried_cable.seat_to(socket.snap_point())
	_player.carried_cable = null
	socket.flash()
	get_solution()

#this section is used to gather the solution from the sockets/endpoints
var solution : Array[String] = []

func get_solution():
	for endpoint: Node in get_tree().get_nodes_in_group("endpoints"):
		solution.append(endpoint.message)
