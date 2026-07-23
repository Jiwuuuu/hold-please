class_name CameraDirector
extends RefCounted
#the desk close-up move, pulled out so anything can borrow it. give it a camera and
#it glides that camera to a pose + ortho zoom with the same cubic ease the desk uses.
#one tween at a time: a new move kills the old one, so interrupting a glide is safe.

var _camera: Camera3D
var _time: float = 0.9
var _tween: Tween


#hand it the camera it drives and how long a glide takes
func setup(camera: Camera3D, transition_time: float = 0.9) -> void:
	_camera = camera
	_time = transition_time


#glide to a raw pose + zoom. returns the tween so callers can await its finished
func move_to(target: Transform3D, target_size: float) -> Tween:
	if _tween != null:
		_tween.kill()
	_tween = _camera.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_parallel()
	_tween.tween_property(_camera, "global_transform", target, _time)
	_tween.tween_property(_camera, "size", target_size, _time)
	return _tween


#glide to a posed anchor camera, reading its pose and its ortho size (like the desk viewpoint)
func focus(anchor: Camera3D) -> Tween:
	return move_to(anchor.global_transform, anchor.size)
