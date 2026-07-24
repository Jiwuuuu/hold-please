extends Node3D
#the exchange room. jacks on the dead side wall, sockets on the living side,
#the operator carries cables across the floor between them. wires the pieces
#together and drives the camera follow.

const CABLE_SCENE: PackedScene = preload("res://scenes/props/cable.tscn")

@export var camera_follow_speed: float = 3.0
#how far the camera focus may drift from room center (x and z) before it
#stops, so the walls stay framed and the void outside never shows
@export var camera_limit_min: Vector2 = Vector2(-1.8, -1.4)
@export var camera_limit_max: Vector2 = Vector2(1.8, 1.4)
#the desk close-up: how long the glide takes. the zoom itself lives on the
#desk's ViewPoint camera (its size), so you preview the exact framing in-editor
@export var desk_transition_time: float = 0.9

#power outage bits: the breaker prop, the red emergency light, and every
#light that dims when the power dies. all assigned in room.tscn
@export var breaker_box: BreakerBox
@export var emergency_light: OmniLight3D
@export var outage_lights: Array[Light3D] = []
#how much of each light's energy survives an outage
@export var outage_dim: float = 0.12
@export var outage_fade_time: float = 0.5

#fires once the breaker close-up glide has landed
signal breaker_focused

var _cam_offset: Vector3
var _home_basis: Basis
var _home_size: float
#desk mode covers the whole trip: fly in, sit, fly back out
var _desk_mode: bool = false
#true only once the fly-in has landed, so exit input works when the view is settled
var _at_desk: bool = false
var _cam_tween: Tween
#breaker mode covers the trip to the breaker box and back, like desk mode
var _breaker_mode: bool = false
var _powered: bool = true
#each outage light's normal energy, cached so set_power can restore it
var _light_base: Dictionary = {}
var _power_tween: Tween

@onready var _player: Player = %Player
@onready var _camera: Camera3D = %Camera
@onready var _desk: Desk = %Desk
@onready var _environment: WorldEnvironment = $WorldEnvironment

func _ready() -> void:
	#the camera is moved by hand in _process, so keep godot's automatic
	#physics interpolation off for it (the 4.7 docs say to do this)
	_camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_cam_offset = _camera.global_position - _focus()
	_home_basis = _camera.global_transform.basis
	_home_size = _camera.size
	_desk.opened.connect(_on_desk_opened)
	if breaker_box != null:
		breaker_box.opened.connect(_on_breaker_opened)
	for light: Light3D in outage_lights:
		_light_base[light] = light.light_energy
	for jack: Node in get_tree().get_nodes_in_group("jacks"):
		if jack is Jack:
			(jack as Jack).plug_grabbed.connect(_on_plug_grabbed)
		elif jack is Anchor:
			(jack as Anchor).plug_grabbed.connect(_on_plug_grabbed)
	for socket: Node in get_tree().get_nodes_in_group("sockets"):
		if socket is Socket:
			(socket as Socket).plug_seated.connect(_on_plug_seated)
			(socket as Socket).unplug_requested.connect(_on_unplug_requested)
		elif socket is Anchor:
			(socket as Anchor).plug_seated.connect(_on_plug_seated)
			(socket as Anchor).unplug_requested.connect(_on_unplug_requested)


#glide toward the player's drawn position, not the physics tick, or it judders
func _process(delta: float) -> void:
	if _desk_mode:
		#the player script skips its own interact check while frozen,
		#so reading the press here keeps it once per frame
		if _at_desk and (Inputs.interact_pressed() or Inputs.cancel_pressed()):
			_close_desk()
		return
	#a nervous flicker on the emergency light while the power is out,
	#once the outage fade has finished writing to it
	if not _powered and emergency_light != null \
			and (_power_tween == null or not _power_tween.is_running()):
		var t: float = Time.get_ticks_msec() / 1000.0
		emergency_light.light_energy = 1.4 + sin(t * 13.0) * 0.2
	#the breaker trip reads no input here — the power manager closes it
	if _breaker_mode:
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


#fly the camera to the breaker box close-up, same glide as the desk.
#no exit input here — the power manager calls close_breaker when done
func _on_breaker_opened(box: BreakerBox) -> void:
	_breaker_mode = true
	_player.controls_enabled = false
	var vp: Camera3D = box.view_point()
	_start_cam_tween(vp.global_transform, vp.size)
	_cam_tween.finished.connect(func() -> void: breaker_focused.emit())


#pull back out from the breaker and hand control back once the glide lands
func close_breaker() -> void:
	_start_cam_tween(Transform3D(_home_basis, _focus() + _cam_offset), _home_size)
	_cam_tween.finished.connect(func() -> void:
		_breaker_mode = false
		_player.controls_enabled = true
	)


#fade the room down to a dim red glow when the power dies, or bring it back.
#jack lamps go dark too so nobody can read who's calling in the dark
func set_power(on: bool) -> void:
	_powered = on
	if _power_tween != null:
		_power_tween.kill()
	_power_tween = create_tween().set_parallel()
	for light: Light3D in outage_lights:
		var energy: float = _light_base[light] if on else _light_base[light] * outage_dim
		_power_tween.tween_property(light, "light_energy", energy, outage_fade_time)
	var env: Environment = _environment.environment
	if env != null:
		_power_tween.tween_property(env, "ambient_light_energy", 1.0 if on else 0.25, outage_fade_time)
	if emergency_light != null:
		_power_tween.tween_property(emergency_light, "light_energy", 0.0 if on else 1.4, outage_fade_time)
	for node: Node in get_tree().get_nodes_in_group("jacks"):
		if node is Jack:
			(node as Jack).set_powered(on)
	if breaker_box != null:
		breaker_box.set_tripped(not on)


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
	cable.origin_node = jack
	add_child(cable)
	_player.carried_cable = cable
	_player.carried_cable.message = jack.message


#the plug went into a socket: drop it there and blink the socket
func _on_plug_seated(socket: Node) -> void:
	if _player.carried_cable == null:
		return
	socket.message += _player.carried_cable.message
	socket.incoming_cable = _player.carried_cable
	_player.carried_cable.seat_to(socket.snap_point())
	_player.carried_cable.seat_node = socket
	_player.carried_cable = null
	socket.flash()


#free hands on an occupied socket or anchor: pop just that plug back into
#the player's hands, so the line can move to another socket without a
#walk back to the jack. the rest of the chain stays put.
func _on_unplug_requested(node: Node) -> void:
	var cable: Cable = node.incoming_cable
	if cable == null or _player.carried_cable != null:
		return
	node.reset()
	cable.seat_node = null
	cable.unseat_to(_player.carry_point())
	_player.carried_cable = cable

#this section is used to gather the solution from the sockets/endpoints
var solution : Array[String] = []

func get_solution():
	solution.clear()
	for endpoint: Node in get_tree().get_nodes_in_group("endpoints"):
		solution.append(endpoint.message)


#the floating name tags above the sockets, assigned in room.tscn
@export var socket_name_labels : Array[Label3D] = []
#the little electric flash shown where two lines tangle
@export var spark : Node3D

#write tonight's listening ghosts above their sockets
func set_listening(names: Array[String]) -> void:
	for i: int in socket_name_labels.size():
		socket_name_labels[i].text = names[i] if i < names.size() else ""


#the puzzle manager reads carry state off the player for the hud
func player() -> Player:
	return _player


#the pause menu asks this so esc at the desk closes the desk, not the game.
#the breaker close-up counts too — the minigame owns esc there
func at_desk() -> bool:
	return _desk_mode or _breaker_mode


#a slow electric flash at the last crossing, so it's still fading
#when the player pulls back from the desk
func flash_spark() -> void:
	if spark == null:
		return
	spark.global_position = last_crossing + Vector3(0.0, 0.25, 0.0)
	spark.visible = true
	var burst: CPUParticles3D = spark.get_node_or_null("Burst") as CPUParticles3D
	if burst != null:
		burst.restart()
	var light: OmniLight3D = spark.get_node("Light") as OmniLight3D
	if light != null:
		light.light_energy = 4.0
		var tween: Tween = create_tween()
		tween.tween_property(light, "light_energy", 0.0, 2.5)
		tween.tween_callback(func() -> void: spark.visible = false)


#light up jacks 1..callers and darken the rest, so only real callers ring.
#jack numbers come from their messages ("01".."04")
func set_active_callers(callers: int) -> void:
	for node: Node in get_tree().get_nodes_in_group("jacks"):
		if node is Jack:
			var jack: Jack = node
			if jack.message.to_int() <= callers:
				jack.reset_waiting()
			else:
				jack.reset_idle()


#clear every cable and put jacks, sockets and anchors back to their rest
#state, ready for the next puzzle (or a retry)
func reset_board() -> void:
	if _player.carried_cable != null:
		_player.carried_cable.queue_free()
		_player.carried_cable = null
	for cable: Node in get_children():
		if cable is Cable:
			cable.queue_free()
	for node: Node in get_tree().get_nodes_in_group("endpoints"):
		if node is Socket:
			(node as Socket).reset()
	for node: Node in get_tree().get_nodes_in_group("sockets"):
		if node is Anchor:
			(node as Anchor).reset()


#every completed line as a run of floor points: socket, anchors, jack.
#each path also marks which of its segments are lifted off the floor —
#a segment touching an anchor post hangs high enough to pass over another line
func _connection_paths() -> Array[Dictionary]:
	var paths: Array[Dictionary] = []
	for node: Node in get_tree().get_nodes_in_group("endpoints"):
		if node is Socket and (node as Socket).occupied:
			var points: PackedVector2Array = PackedVector2Array()
			var anchor_flags: Array[bool] = [false]
			points.append(Vector2(node.global_position.x, node.global_position.z))
			var cable: Cable = (node as Socket).incoming_cable
			while cable != null:
				var origin: Node3D = cable.origin_node
				points.append(Vector2(origin.global_position.x, origin.global_position.z))
				anchor_flags.append(origin is Anchor)
				cable = (origin as Anchor).incoming_cable if origin is Anchor else null
			var lifted: Array[bool] = []
			for s: int in points.size() - 1:
				lifted.append(anchor_flags[s] or anchor_flags[s + 1])
			paths.append({"points": points, "lifted": lifted})
	return paths


#where the last detected crossing sits on the floor, for feedback effects
var last_crossing: Vector3 = Vector3.ZERO

#count how many times different lines cross on the floor. a crossing is
#fine when one of the two lines runs through an anchor post there — the
#post holds it up, so it passes over the other line instead of tangling
func count_crossings() -> int:
	var paths: Array[Dictionary] = _connection_paths()
	var crossings: int = 0
	for i: int in paths.size():
		for j: int in range(i + 1, paths.size()):
			var pa: PackedVector2Array = paths[i].points
			var pb: PackedVector2Array = paths[j].points
			for a: int in pa.size() - 1:
				for b: int in pb.size() - 1:
					if paths[i].lifted[a] or paths[j].lifted[b]:
						continue
					var hit: Variant = Geometry2D.segment_intersects_segment(
						pa[a], pa[a + 1], pb[b], pb[b + 1])
					if hit != null:
						crossings += 1
						last_crossing = Vector3((hit as Vector2).x, 0.1, (hit as Vector2).y)
	return crossings


#because of camera shenanigans, we use brute force and manual raycasting to make the papers on the desk clickable
@export var dossier_body : StaticBody3D
@export var task_body : StaticBody3D
#this one is the big button on the desk
@export var big_button : StaticBody3D
signal dossier_signal
signal task_signal
signal big_button_signal

func _input(event):
	if event is InputEventMouseButton and _desk_mode:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var camera = get_viewport().get_camera_3d()
			var origin = camera.project_ray_origin(event.position)
			var direction = camera.project_ray_normal(event.position)
			var destination = origin + direction * 1000
			
			var query = PhysicsRayQueryParameters3D.create(origin, destination)
			var result = get_world_3d().direct_space_state.intersect_ray(query)
			if result.collider == dossier_body:
				dossier_signal.emit()
			elif result.collider == task_body:
				task_signal.emit()
			elif result.collider == big_button:
				big_button_signal.emit()
