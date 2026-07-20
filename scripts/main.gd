extends Node
#the pixel look. the whole 3d world renders inside %Container's viewport
#at window size divided by pixel_scale, then scales up with hard pixels.

@export_range(1, 6) var pixel_scale: int = 3

@onready var _container: SubViewportContainer = %Container


func _ready() -> void:
	_container.stretch_shrink = pixel_scale
