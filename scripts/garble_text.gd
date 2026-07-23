@tool
class_name GarbleText
extends RichTextEffect
#a subtle bad-line flicker for caller text: [garble]like this[/garble].
#a few characters shiver and dim now and then, but everything stays readable.

var bbcode: String = "garble"

@export var flicker_threshold : float = 0.965
@export var shake_pixels : float = 1.5


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var seed: float = float(char_fx.range.x)
	var wave: float = sin(char_fx.elapsed_time * 11.0 + seed * 7.31)
	if wave > flicker_threshold:
		char_fx.offset.y += sin(seed * 3.7) * shake_pixels
		char_fx.color.a = 0.55
	return true
