extends CanvasLayer
#the tv power-off between scenes. call TransitionScreen.change_scene(path)
#instead of get_tree().change_scene_to_file — the screen collapses to a
#bright line and a dot, the scene swaps behind the black, then powers on.
#the rect stays hidden at rest: an idle screen-reading rect repaints a
#stale screen copy in the compatibility renderer (same gotcha as screen_fx).

@export var off_time: float = 0.35
@export var on_time: float = 0.5

var _busy: bool = false

@onready var _rect: ColorRect = %Rect


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	var mat: ShaderMaterial = _rect.material as ShaderMaterial
	mat.set_shader_parameter("progress", 0.0)
	_rect.visible = true
	var off: Tween = create_tween()
	off.tween_property(mat, "shader_parameter/progress", 1.0, off_time)
	await off.finished
	get_tree().change_scene_to_file(path)
	#let the new scene draw a frame behind the black before powering on
	await get_tree().process_frame
	var on: Tween = create_tween()
	on.tween_property(mat, "shader_parameter/progress", 0.0, on_time)
	await on.finished
	_rect.visible = false
	_busy = false
