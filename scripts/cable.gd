class_name Cable
extends Node3D
#the patch cable. a chain of points pinned at a jack on one end and at
#whoever holds the plug on the other (the player while carrying, then the
#socket after seating). drawn as a flat ribbon that always faces the camera,
#rebuilt every frame — webgl can't draw thick lines, so no line primitives.
#everything runs in _process because it's all visual; the pins read the
#interpolated transforms so the cable never judders against the player.
#the ribbon mesh and material are set up on the Ribbon node in cable.tscn.
#if the sag simulation ever misbehaves, turn use_verlet off in the inspector
#for a simple curve fallback that uses the same ribbon drawing.

#the "message" variable is used for the puzzle logic
#for the cable scene, it should always be ""
@export var message : String = ""

#the jack or anchor this cable came out of, and the socket/anchor it seated
#into. the room sets these so unplugging can walk the chain back to the jack.
var origin_node : Node3D = null
var seat_node : Node3D = null

@export var point_count: int = 14
@export var rest_length: float = 4.0
@export var gravity: float = 18.0
@export var iterations: int = 8
@export var thickness: float = 0.06
@export var damping: float = 0.985
@export var use_verlet: bool = true

var _anchor: Node3D = null
var _follow: Node3D = null
var _points: PackedVector3Array = PackedVector3Array()
var _prev_points: PackedVector3Array = PackedVector3Array()
var _mesh: ImmediateMesh

@onready var _ribbon: MeshInstance3D = %Ribbon
@onready var _plug: Sprite3D = %Plug


func _ready() -> void:
	_mesh = _ribbon.mesh as ImmediateMesh
	if _anchor == null:
		_setup_self_test()


#call before add_child() — only stores refs and seeds the points
#from the (already in-tree) anchor/follow positions
func setup(anchor: Node3D, follow: Node3D) -> void:
	_anchor = anchor
	_follow = follow
	_reset_points()


#retarget the loose end onto a socket, with a little plug punch on the way in
func seat_to(snap: Node3D) -> void:
	_follow = snap
	_punch_plug()


#pull the plug back out of a socket into a carrier's hands, same punch
func unseat_to(follow: Node3D) -> void:
	_follow = follow
	_punch_plug()


#quick scale pop on the plug so seating and unseating both feel snappy
func _punch_plug() -> void:
	_plug.scale = Vector3.ONE * 1.6
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_plug, "scale", Vector3.ONE, 0.18)


func _process(delta: float) -> void:
	if _anchor == null or _follow == null or _points.is_empty():
		return
	if use_verlet:
		_simulate(minf(delta, 1.0 / 30.0))
	else:
		_bezier_droop()
	_rebuild_ribbon()
	_plug.global_position = _points[point_count - 1]


#the drawn position of a pin, not the physics-tick one, so the cable
#ends track what's actually on screen
func _pin(node: Node3D) -> Vector3:
	return node.get_global_transform_interpolated().origin


#lay the points out in a straight line between the two ends to start
func _reset_points() -> void:
	_points.resize(point_count)
	_prev_points.resize(point_count)
	var a: Vector3 = _anchor.global_position
	var b: Vector3 = _follow.global_position
	for i: int in point_count:
		var t: float = float(i) / float(point_count - 1)
		_points[i] = a.lerp(b, t)
		_prev_points[i] = _points[i]
	#poke the interpolation once before first use, avoids a streak on spawn
	_pin(_anchor)
	_pin(_follow)


#verlet: each point keeps its momentum and falls, then a few relax passes
#pull neighbours back to segment length. endpoints stay pinned.
func _simulate(delta: float) -> void:
	var segment: float = rest_length / float(point_count - 1)
	for i: int in range(1, point_count - 1):
		var p: Vector3 = _points[i]
		var vel: Vector3 = (p - _prev_points[i]) * damping
		_prev_points[i] = p
		_points[i] = p + vel + Vector3.DOWN * gravity * delta * delta

	for _iter: int in iterations:
		_points[0] = _pin(_anchor)
		_points[point_count - 1] = _pin(_follow)
		for i: int in point_count - 1:
			var a: Vector3 = _points[i]
			var b: Vector3 = _points[i + 1]
			var d: Vector3 = b - a
			var dist: float = d.length()
			if dist < 0.0001:
				continue
			var correction: Vector3 = d * ((dist - segment) / dist)
			if i == 0:
				_points[i + 1] = b - correction
			elif i + 1 == point_count - 1:
				_points[i] = a + correction
			else:
				_points[i] = a + correction * 0.5
				_points[i + 1] = b - correction * 0.5

	#keep the cable from clipping under the floor
	for i: int in point_count:
		var p: Vector3 = _points[i]
		if p.y < 0.03:
			_points[i] = Vector3(p.x, 0.03, p.z)


#fallback: no simulation, just a curve that droops by how much slack is left
func _bezier_droop() -> void:
	var a: Vector3 = _pin(_anchor)
	var b: Vector3 = _pin(_follow)
	var slack: float = maxf(rest_length - a.distance_to(b), 0.0)
	var mid: Vector3 = (a + b) * 0.5 + Vector3.DOWN * slack * 0.5
	for i: int in point_count:
		var t: float = float(i) / float(point_count - 1)
		var q: Vector3 = a.lerp(mid, t).lerp(mid.lerp(b, t), t)
		_points[i] = Vector3(q.x, maxf(q.y, 0.03), q.z)


#rebuild the ribbon: one thin quad strip through the points, widened
#sideways so it always faces the camera
func _rebuild_ribbon() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	_mesh.clear_surfaces()
	if cam == null:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i: int in point_count:
		var p: Vector3 = _points[i]
		var along: Vector3
		if i == 0:
			along = _points[1] - _points[0]
		elif i == point_count - 1:
			along = _points[i] - _points[i - 1]
		else:
			along = _points[i + 1] - _points[i - 1]
		var to_cam: Vector3 = (cam.global_position - p).normalized()
		var side: Vector3 = along.cross(to_cam).normalized() * thickness
		_mesh.surface_add_vertex(_ribbon.to_local(p - side))
		_mesh.surface_add_vertex(_ribbon.to_local(p + side))
	_mesh.surface_end()


#f6 on cable.tscn alone: hang between two markers with its own camera
func _setup_self_test() -> void:
	if get_parent() != get_tree().root or get_tree().current_scene != self:
		return
	var a: Marker3D = Marker3D.new()
	a.position = Vector3(-2.0, 2.0, 0.0)
	add_child(a)
	var b: Marker3D = Marker3D.new()
	b.position = Vector3(2.0, 1.2, 0.0)
	add_child(b)
	var cam: Camera3D = Camera3D.new()
	cam.position = Vector3(0.0, 1.5, 5.0)
	add_child(cam)
	cam.current = true
	setup(a, b)
