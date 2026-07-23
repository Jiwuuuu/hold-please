class_name Anchor
extends StaticBody3D
#an anchor is basically a mid-point used to break the cable
#and change its direction to avoid crossing wires

#the "message" variable is used for the puzzle logic
#for anchors, it should always be "" until a cable passes through
@export var message : String = ""

#it must have two signals: one for taking the wire, one for returning it
signal plug_grabbed(anchor: Anchor)
signal plug_seated(anchor: Anchor)

#I shamelessly took these from the jack
const LAMP_LIT: Color = Color(1.0, 0.72, 0.2)
const LAMP_OFF: Color = Color(0.25, 0.18, 0.1)
@export var lit : bool = false

@onready var _lamp: MeshInstance3D = %Lamp
@onready var _cable_anchor: Marker3D = %CableAnchor

#and a simple enum to determine whether it has a cable or not
enum anchor_status {nocable, yescable}
var status : anchor_status = anchor_status.nocable
var cable_out : bool = false
#the cable seated into this anchor, so unplug can walk past it to the jack
var incoming_cable : Cable = null


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
	#carrying the anchor's own outgoing cable back to it puts the plug back
	if cable_out and player.is_carrying() and player.carried_cable.origin_node == self:
		player.carried_cable.queue_free()
		player.carried_cable = null
		cable_out = false
	#if player is carrying, we want the anchor to act as a socket
	elif status == anchor_status.nocable and player.is_carrying():
		status = anchor_status.yescable
		set_lit(true)
		plug_seated.emit(self)
	#otherwise, the anchor must act as a jack
	#it can only give one cable because of cable_out
	elif status == anchor_status.yescable and !player.is_carrying() and !cable_out:
		cable_out = true
		plug_grabbed.emit(self)


#back to an empty mid-point, ready to route another line
func reset() -> void:
	status = anchor_status.nocable
	cable_out = false
	incoming_cable = null
	message = ""
	set_lit(false)


#the original script calls for socket.flash
#this script uses the jack light logic
#but we still need a flash function
func flash():
	pass
