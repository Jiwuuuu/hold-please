class_name Desk
extends StaticBody3D
#the operator's desk, where requests from the living come in.
#interact leans in for a close look — the room listens for opened and
#flies the camera to %ViewPoint. the marker is posed in the scene, so
#framing is tuned by dragging it in the editor, not by code.

signal opened(desk: Desk)

@onready var _view_point: Camera3D = %ViewPoint


#the camera pose for the desk close-up. it's a real ortho camera so its
#framing can be previewed in the editor, and the room reads its size for zoom.
func view_point() -> Camera3D:
	return _view_point


#only lean in with free hands, a carried cable would drag across the desk
func interact(player: Player) -> void:
	if not player.is_carrying():
		opened.emit(self)
