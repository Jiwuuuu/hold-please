extends Label3D
#makes the neon sign stutter like a loose connection. dips the sign and its
#glow light for a moment at random intervals, then holds steady again.

@export var glow_light : OmniLight3D
@export var min_wait : float = 1.4
@export var max_wait : float = 4.5
@export var flicker_time : float = 0.14

var _base_alpha : float
var _base_energy : float
var _timer : float


func _ready() -> void:
	_base_alpha = modulate.a
	if glow_light != null:
		_base_energy = glow_light.light_energy
	_timer = randf_range(min_wait, max_wait)


#count down to the next stutter, then run a quick double dip
func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = randf_range(min_wait, max_wait)
	var t := create_tween()
	t.tween_callback(_dim.bind(0.35))
	t.tween_interval(flicker_time * 0.5)
	t.tween_callback(_dim.bind(1.0))
	t.tween_interval(flicker_time * 0.4)
	t.tween_callback(_dim.bind(0.55))
	t.tween_interval(flicker_time * 0.6)
	t.tween_callback(_dim.bind(1.0))


#scale the sign brightness and the glow together
func _dim(f: float) -> void:
	modulate.a = _base_alpha * f
	if glow_light != null:
		glow_light.light_energy = _base_energy * f
