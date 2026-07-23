extends Control
#the fullscreen crt + glitch overlays. gameplay code never touches shader
#uniforms directly — it calls glitch_burst() and this node does the rest.
#both rects ignore the mouse so clicks pass through to the game.

@export var glitch_rect : ColorRect
@export var burst_strength : float = 0.7
@export var burst_time : float = 0.4

var _tween : Tween


#start with the glitch rect off so the crt layer underneath stays visible
func _ready() -> void:
	if glitch_rect != null:
		glitch_rect.visible = false


#a short bad-connection rip across the screen. the rect stays hidden at rest —
#an idle screen-reading rect repaints a stale screen copy over the crt layer
#in the compatibility renderer, wiping the crt look. shown only mid-burst.
func glitch_burst(strength: float = -1.0) -> void:
	if glitch_rect == null:
		return
	var mat: ShaderMaterial = glitch_rect.material as ShaderMaterial
	if mat == null:
		return
	if _tween != null:
		_tween.kill()
	var s: float = burst_strength if strength < 0.0 else strength
	mat.set_shader_parameter("intensity", s)
	glitch_rect.visible = true
	_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(mat, "shader_parameter/intensity", 0.0, burst_time)
	_tween.tween_callback(func() -> void: glitch_rect.visible = false)
