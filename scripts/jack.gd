class_name Jack
extends StaticBody3D
#a caller jack. the lamp stays lit while a caller waits.
#interact grabs the plug — test_room spawns the cable and hands it to the player.
#the lamp material lives on the Lamp node (local to scene, so every jack has its own copy).

signal plug_grabbed(jack: Jack)

const LAMP_LIT: Color = Color(1.0, 0.72, 0.2)
const LAMP_OFF: Color = Color(0.25, 0.18, 0.1)

@export var lit: bool = true

var cable_out: bool = false

@onready var _lamp: MeshInstance3D = %Lamp
@onready var _cable_anchor: Marker3D = %CableAnchor


func _ready() -> void:
	set_lit(lit)


#flip the lamp between waiting-amber and off
func set_lit(value: bool) -> void:
	lit = value
	var mat: StandardMaterial3D = _lamp.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = LAMP_LIT if lit else LAMP_OFF


#where the cable stays pinned
func cable_anchor() -> Node3D:
	return _cable_anchor


#only hand out the plug if someone is actually calling and the player's hands are free
func interact(player: Player) -> void:
	if lit and not cable_out and not player.is_carrying():
		cable_out = true
		set_lit(false)
		plug_grabbed.emit(self)
