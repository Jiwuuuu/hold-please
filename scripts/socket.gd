class_name Socket
extends StaticBody3D
#a destination socket. interact while carrying a cable to seat the plug.
#interact with free hands on an occupied socket to unplug the whole line.
#the body material lives on the Body node (local to scene) so flash() can tint it per socket.

#the "message" variable is used for the puzzle logic
@export var message : String = ""

#the numbered panel sprite for this socket, picked per instance in room.tscn
@export var panel_texture : Texture2D

signal plug_seated(socket: Socket)
signal unplug_requested(socket: Socket)

const FLASH_COLOR: Color = Color(0.55, 1.0, 0.55)

var occupied: bool = false
#the cable currently seated here, so unplug can walk the chain back
var incoming_cable: Cable = null

var _base_color: Color
#the socket code ("AA".."DD") before any cable message was added on
var _base_message: String

@onready var _body: Sprite3D = %Body
@onready var _snap_point: Marker3D = %SnapPoint


func _ready() -> void:
	if panel_texture != null:
		_body.texture = panel_texture
	_base_color = _body.modulate
	_base_message = message


#where the plug snaps to
func snap_point() -> Node3D:
	return _snap_point


func interact(player: Player) -> void:
	if not occupied and player.is_carrying():
		occupied = true
		plug_seated.emit(self)
	elif occupied and not player.is_carrying():
		unplug_requested.emit(self)


#back to an empty socket: code restored, free for a new plug
func reset() -> void:
	occupied = false
	incoming_cable = null
	message = _base_message


#quick green blink when a call connects
func flash() -> void:
	_body.modulate = FLASH_COLOR
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_body, "modulate", _base_color, 0.35)
