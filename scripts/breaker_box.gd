class_name BreakerBox
extends StaticBody3D
#the wall breaker cabinet. sleeps until the power manager trips it during
#an outage, then one interact sends the camera in for the tuning minigame.
#the status lamp material lives on the StatusLamp node (local to scene).

signal opened(box: BreakerBox)

const LAMP_TRIPPED: Color = Color(1.0, 0.25, 0.2)
const LAMP_OK: Color = Color(0.3, 0.8, 0.4)

#set by the power manager while the power is out
var active: bool = false

@onready var _view_point: Camera3D = %ViewPoint
@onready var _lamp: MeshInstance3D = %StatusLamp


func _ready() -> void:
	set_tripped(false)


#the close-up camera pose, tuned in the editor like the desk's ViewPoint
func view_point() -> Camera3D:
	return _view_point


func set_tripped(tripped: bool) -> void:
	var mat: StandardMaterial3D = _lamp.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = LAMP_TRIPPED if tripped else LAMP_OK


#only answers during an outage, and only with free hands — same rule as the desk
func interact(player: Player) -> void:
	if active and not player.is_carrying():
		opened.emit(self)
