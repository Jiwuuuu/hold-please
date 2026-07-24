extends Camera3D
#the crisp pass camera. lives in its own full-res viewport and copies the
#world camera every frame, so the player sprite lines up exactly with the
#pixelated world behind it.

var _world_camera: Camera3D


func _ready() -> void:
	#run after the room has moved its camera (lower priority goes first),
	#otherwise the player would lag one frame behind the world
	process_priority = 10
	_world_camera = get_tree().get_first_node_in_group("world_camera") as Camera3D

#mirror the world camera so both viewports see the same framing.
#the offsets carry the menu's idle sway, so the crisp pass sways too
func _process(_delta: float) -> void:
	if _world_camera == null:
		return
	global_transform = _world_camera.global_transform
	size = _world_camera.size
	h_offset = _world_camera.h_offset
	v_offset = _world_camera.v_offset
