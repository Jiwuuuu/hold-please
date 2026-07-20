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

var _cam_offset: Vector3

@onready var _player: Player = %Player
@onready var _camera: Camera3D = %Camera


func _ready() -> void:
	#the camera is moved by hand in _process, so keep godot's automatic
	#physics interpolation off for it (the 4.7 docs say to do this)
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_cam_offset = _camera.global_position - _focus()
	for jack: Node in get_tree().get_nodes_in_group("jacks"):
		(jack as Jack).plug_grabbed.connect(_on_plug_grabbed)
	for socket: Node in get_tree().get_nodes_in_group("sockets"):
		(socket as Socket).plug_seated.connect(_on_plug_seated)


#glide toward the player's drawn position, not the physics tick, or it judders
func _process(delta: float) -> void:
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


#a jack gave out its plug: spawn a cable from that jack to the player's hands
func _on_plug_grabbed(jack: Jack) -> void:
	var cable: Cable = CABLE_SCENE.instantiate()
	cable.setup(jack.cable_anchor(), _player.carry_point())
	add_child(cable)
	_player.carried_cable = cable


#the plug went into a socket: drop it there and blink the socket
func _on_plug_seated(socket: Socket) -> void:
	if _player.carried_cable == null:
		return
	_player.carried_cable.seat_to(socket.snap_point())
	_player.carried_cable = null
	socket.flash()
