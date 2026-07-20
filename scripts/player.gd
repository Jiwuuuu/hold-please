class_name Player
extends CharacterBody3D
#the night-shift operator. walks the room, grabs a plug at a jack,
#carries the cable to a socket. anything in the "interactable" group
#that has an interact(player) function can be used with E.
#the sprite, carry point and reach area are all set up on the scene nodes.

signal interacted(target: Node3D)

@export var move_speed: float = 4.0
@export var accel: float = 20.0
@export var fall_gravity: float = 20.0

#the room turns this off while the camera sits at the desk
var controls_enabled: bool = true
var carried_cable: Cable = null

@onready var _visual: Sprite3D = %Visual
@onready var _carry_point: Marker3D = %CarryPoint
@onready var _interact_area: Area3D = %InteractArea


#movement stays in physics so collisions behave the same every run
func _physics_process(delta: float) -> void:
	var input: Vector2 = Inputs.move_vector() if controls_enabled else Vector2.ZERO
	var target: Vector3 = Vector3(input.x, 0.0, input.y) * move_speed
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)
	if not is_on_floor():
		velocity.y -= fall_gravity * delta
	move_and_slide()

	if absf(velocity.x) > 0.05:
		_visual.flip_h = velocity.x < 0.0

	if controls_enabled and Inputs.interact_pressed():
		_try_interact()


#where the carried plug and cable end ride
func carry_point() -> Node3D:
	return _carry_point


func is_carrying() -> bool:
	return carried_cable != null


#use the closest interactable inside the reach area
func _try_interact() -> void:
	var nearest: Node3D = null
	var best: float = INF
	for body: Node3D in _interact_area.get_overlapping_bodies():
		if not body.is_in_group("interactable"):
			continue
		var d: float = global_position.distance_squared_to(body.global_position)
		if d < best:
			best = d
			nearest = body
	if nearest != null and nearest.has_method("interact"):
		nearest.call("interact", self)
		interacted.emit(nearest)
