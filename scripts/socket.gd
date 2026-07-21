class_name Socket
extends StaticBody3D
#a destination socket. interact while carrying a cable to seat the plug.
#the body material lives on the Body node (local to scene) so flash() can tint it per socket.

#the "message" variable is used for the puzzle logic
@export var message : String = ""

signal plug_seated(socket: Socket)

const FLASH_COLOR: Color = Color(0.55, 1.0, 0.55)

var occupied: bool = false
var _base_color: Color

@onready var _body: MeshInstance3D = %Body
@onready var _snap_point: Marker3D = %SnapPoint


func _ready() -> void:
	_base_color = (_body.material_override as StandardMaterial3D).albedo_color


#where the plug snaps to
func snap_point() -> Node3D:
	return _snap_point


func interact(player: Player) -> void:
	if not occupied and player.is_carrying():
		occupied = true
		plug_seated.emit(self)


#quick green blink when a call connects
func flash() -> void:
	var mat: StandardMaterial3D = _body.material_override as StandardMaterial3D
	if mat == null:
		return
	mat.albedo_color = FLASH_COLOR
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color", _base_color, 0.35)
