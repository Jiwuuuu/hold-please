class_name TuningScope
extends Control
#pure drawing for the breaker minigame: a dark scope grid, the drifting
#target wave and the player's wave. the minigame sets the fields each
#frame and calls queue_redraw.

const BG_COLOR: Color = Color(0.03, 0.05, 0.05)
const GRID_COLOR: Color = Color(0.25, 0.35, 0.33, 0.35)
const TARGET_COLOR: Color = Color(0.5, 1.0, 0.92)
const PLAYER_COLOR: Color = Color(1.0, 0.72, 0.2)

var target_freq: float = 2.0
var player_freq: float = 1.0
var locked: bool = false


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)
	for i: int in range(1, 8):
		var x: float = size.x * float(i) / 8.0
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), GRID_COLOR)
	for i: int in range(1, 4):
		var y: float = size.y * float(i) / 4.0
		draw_line(Vector2(0.0, y), Vector2(size.x, y), GRID_COLOR)
	_draw_wave(target_freq, TARGET_COLOR, 2.0)
	#the player wave brightens and thickens while it sits on the target
	var color: Color = PLAYER_COLOR.lightened(0.3) if locked else PLAYER_COLOR
	var width: float = 4.0 if locked else 2.0
	_draw_wave(player_freq, color, width)


func _draw_wave(freq: float, color: Color, width: float) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var amp: float = size.y * 0.32
	var mid: float = size.y * 0.5
	for i: int in 129:
		var t: float = float(i) / 128.0
		points.append(Vector2(t * size.x, mid + sin(t * freq * TAU) * amp))
	draw_polyline(points, color, width, true)
