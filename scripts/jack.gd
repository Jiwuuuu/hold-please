class_name Jack
extends StaticBody3D
#a caller jack. the lamp stays lit while a caller waits.
#interact grabs the plug — test_room spawns the cable and hands it to the player.
#the lamp material lives on the Lamp node (local to scene, so every jack has its own copy).

#the "message" variable is used for the puzzle logic
@export var message : String = ""

#the port sprite for this jack, picked per instance in room.tscn
@export var port_texture : Texture2D

signal plug_grabbed(jack: Jack)

const LAMP_LIT: Color = Color(1.0, 0.72, 0.2)
const LAMP_OFF: Color = Color(0.25, 0.18, 0.1)

@export var lit: bool = true

var cable_out: bool = false

@onready var _lamp: MeshInstance3D = %Lamp
@onready var _body: Sprite3D = %Body
@onready var _cable_anchor: Marker3D = %CableAnchor


func _ready() -> void:
	if port_texture != null:
		_body.texture = port_texture
	set_lit(lit)


#while a caller waits, the lamp breathes so it reads as ringing
func _process(_delta: float) -> void:
	if not lit:
		return
	var mat: StandardMaterial3D = _lamp.material_override as StandardMaterial3D
	if mat == null:
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.7 + 0.3 * sin(t * 5.0 + float(message.to_int()))
	mat.albedo_color = LAMP_OFF.lerp(LAMP_LIT, pulse)


#flip the lamp between waiting-amber and off
func set_lit(value: bool) -> void:
	lit = value
	var mat: StandardMaterial3D = _lamp.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = LAMP_LIT if lit else LAMP_OFF


#where the cable stays pinned
func cable_anchor() -> Node3D:
	return _cable_anchor


#only hand out the plug if someone is actually calling and the player's hands are free.
#interacting again while carrying this jack's own cable puts the plug back.
func interact(player: Player) -> void:
	if lit and not cable_out and not player.is_carrying():
		cable_out = true
		set_lit(false)
		plug_grabbed.emit(self)
	elif cable_out and player.is_carrying() and player.carried_cable.origin_node == self:
		player.carried_cable.queue_free()
		player.carried_cable = null
		reset_waiting()


#back to "caller waiting": lamp on, plug home. used by cancel and unplug.
func reset_waiting() -> void:
	cable_out = false
	set_lit(true)


#dark and idle, for jacks with no caller this puzzle or a board reset
func reset_idle() -> void:
	cable_out = false
	set_lit(false)
