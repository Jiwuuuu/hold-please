extends Control
#the in-game pause screen. esc toggles it, the tree freezes underneath
#(this node runs on process_mode ALWAYS so it keeps listening).
#the desk close-up owns esc first — see at_desk() below.

@export var room : Node3D

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _fullscreen_check: CheckButton = %FullscreenCheck


func _ready() -> void:
	hide()
	%ResumeButton.pressed.connect(_resume)
	%QuitButton.pressed.connect(_quit_to_menu)
	_master_slider.set_value_no_signal(Settings.master)
	_music_slider.set_value_no_signal(Settings.music)
	_sfx_slider.set_value_no_signal(Settings.sfx)
	_fullscreen_check.set_pressed_no_signal(Settings.fullscreen)
	_master_slider.value_changed.connect(func(v: float) -> void: Settings.set_master(v))
	_music_slider.value_changed.connect(func(v: float) -> void: Settings.set_music(v))
	_sfx_slider.value_changed.connect(func(v: float) -> void: Settings.set_sfx(v))
	_fullscreen_check.toggled.connect(func(on: bool) -> void: Settings.set_fullscreen(on))


func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	#at the desk, esc means "stand up", not "pause" — the room handles it
	if not visible and room != null and room.at_desk():
		return
	if visible:
		_resume()
	else:
		_pause()


func _pause() -> void:
	get_tree().paused = true
	show()


func _resume() -> void:
	get_tree().paused = false
	hide()


func _quit_to_menu() -> void:
	get_tree().paused = false
	hide()
	TransitionScreen.change_scene("res://scenes/main_menu.tscn")
