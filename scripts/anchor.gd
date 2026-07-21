class_name Anchor
extends StaticBody3D
#an anchor is basically a mid-point used to break the cable 
#and change its direction to avoid crossing wires

#the "message" variable is used for the puzzle logic
#for anchors, it should always be ""
@export var message : String = ""

#it must have to signals: one for taking the wire, one for returning it
signal plug_grabbed(anchor: Anchor)
signal plug_seated(anchor: Anchor)

#I shamelessly took these from the jack
const LAMP_LIT: Color = Color(1.0, 0.72, 0.2)
const LAMP_OFF: Color = Color(0.25, 0.18, 0.1)
@export var lit : bool = true

@onready var _lamp: MeshInstance3D = %Lamp
@onready var _cable_anchor: Marker3D = %CableAnchor

#and a simple enum to determine whether it has a cable or not
enum anchor_status {nocable, yescable}
var status : anchor_status = anchor_status.nocable
var cable_out : bool = false

func _ready() -> void:
	set_lit(lit)

#this is taken from the jack as well
func set_lit(value: bool) -> void:
	lit = value
	var mat: StandardMaterial3D = _lamp.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = LAMP_LIT if lit else LAMP_OFF

func cable_anchor() -> Node3D:
	return _cable_anchor
func snap_point() -> Node3D:
	return _cable_anchor

func interact(player: Player) -> void:
	#I feel like using just lit to check if there is a cable would be
	#more elegant and concise, but I want to be extra-sure
	
	#if player is carrying, we want the anchor to act as a socket
	if status == anchor_status.nocable and player.is_carrying():
		status = anchor_status.yescable
		set_lit(true)
		plug_seated.emit(self)
	#otherwise, the anchor must act as a jack
	#it can only give one cable because of cable_out
	elif status == anchor_status.yescable and !player.is_carrying() and !cable_out:
		cable_out = true
		plug_grabbed.emit(self)

#the original script calls for socket.flash
#this script uses the jack light logic
#but we still need a flash function
func flash():
	pass
