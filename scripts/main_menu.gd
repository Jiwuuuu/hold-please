extends Node
#the main menu. it's the real room seen through the pixel pipeline; pressing a
#button flies the shared camera to a posed anchor (same glide the desk uses) and
#fades that screen in over it. back or esc flies home. start shift loads the game.

@export_range(1, 6) var pixel_scale: int = 3
#the glide length, matched to the desk's desk_transition_time
@export var glide_time: float = 0.9
#hold before a screen fades in, so the camera lands before you read it
@export var reveal_delay: float = 0.55
@export var reveal_time: float = 0.25
#how far the camera breathes around its shot while idle
@export var sway_amount: float = 0.05
#gap between each home element fading in on boot
@export var intro_stagger: float = 0.08

@onready var _container: SubViewportContainer = %Container
@onready var _camera: Camera3D = %MenuCamera
@onready var _home_view: Camera3D = %HomeView
@onready var _settings_view: Camera3D = %SettingsView
@onready var _credits_view: Camera3D = %CreditsView
@onready var _howto_view: Camera3D = %HowToPlayView

@onready var _home: Control = %Home
@onready var _settings_panel: Control = %SettingsPanel
@onready var _credits_panel: Control = %CreditsPanel
@onready var _howto_panel: Control = %HowToPlayPanel

@onready var _credits_prop: Node3D = $Container/WorldViewport/MenuWorld/CreditsPoster
@onready var _howto_prop: Node3D = $Container/WorldViewport/MenuWorld/HowToBoard
@onready var _settings_prop: Node3D = $Container/WorldViewport/MenuWorld/ServicePanel

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SFXSlider
@onready var _fullscreen_check: CheckButton = %FullscreenCheck

var _director := CameraDirector.new()
#the screen currently open, or null when we're on the home shot
var _open_panel: Control
#the wall prop lit up for that screen, and each 3d label's authored alpha
var _open_prop: Node3D
var _label_alphas := {}


func _ready() -> void:
	_container.stretch_shrink = pixel_scale
	_director.setup(_camera, glide_time)
	#open already framed on the home shot, no glide on the first frame
	_camera.global_transform = _home_view.global_transform
	_camera.size = _home_view.size

	_settings_panel.hide()
	_credits_panel.hide()
	_howto_panel.hide()
	_home.show()

	%StartButton.pressed.connect(_on_start)
	%ContinueButton.pressed.connect(_on_continue)
	%ContinueButton.visible = Settings.night >= 0
	%NewShiftConfirm.confirmed.connect(_begin_new_shift)
	#the wall props stay hidden until their screen is opened
	for prop: Node3D in [_credits_prop, _howto_prop, _settings_prop]:
		for label: Label3D in prop.find_children("*", "Label3D", true, false):
			_label_alphas[label] = label.modulate.a
		prop.hide()

	%SettingsButton.pressed.connect(_open.bind(_settings_view, _settings_panel, _settings_prop))
	%HowToPlayButton.pressed.connect(_open.bind(_howto_view, _howto_panel, _howto_prop))
	%CreditsButton.pressed.connect(_open.bind(_credits_view, _credits_panel, _credits_prop))
	%QuitButton.pressed.connect(_on_quit)
	%SettingsBack.pressed.connect(_go_home)
	%CreditsBack.pressed.connect(_go_home)
	%HowToPlayBack.pressed.connect(_go_home)

	#quit is a no-op in a browser, so hide it on web builds
	if OS.has_feature("web"):
		%QuitButton.hide()

	_init_settings_controls()
	_play_intro()
	_setup_button_hover()


#the home screen fades in piece by piece on boot
func _play_intro() -> void:
	var intro_nodes: Array[Control] = [%Tagline]
	for child: Node in %Buttons.get_children():
		if child is Control:
			intro_nodes.append(child)
	var intro: Tween = create_tween()
	for i: int in intro_nodes.size():
		var node: Control = intro_nodes[i]
		node.modulate.a = 0.0
		intro.parallel().tween_property(node, "modulate:a", 1.0, 0.25).set_delay(intro_stagger * i)


#a small grow on hover so the buttons feel alive
func _setup_button_hover() -> void:
	for child: Node in %Buttons.get_children():
		if child is Button:
			var button: Button = child
			button.mouse_entered.connect(_on_button_hover.bind(button, true))
			button.mouse_exited.connect(_on_button_hover.bind(button, false))


func _on_button_hover(button: Button, over: bool) -> void:
	button.pivot_offset = button.size / 2.0
	var t: Tween = button.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(button, "scale", Vector2.ONE * (1.04 if over else 1.0), 0.08)


#a slow breathing drift on the camera. offsets compose with the glides,
#which only tween the transform and size, so there's never a pop
func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	_camera.h_offset = sin(t * 0.31) * sway_amount
	_camera.v_offset = cos(t * 0.23) * sway_amount * 0.6


#esc backs out of a screen to the home shot
func _unhandled_input(event: InputEvent) -> void:
	if _open_panel != null and event.is_action_pressed("ui_cancel"):
		_go_home()
		get_viewport().set_input_as_handled()


#fly to a screen's anchor, light its wall prop up, and reveal its panel once
#the camera lands
func _open(anchor: Camera3D, panel: Control, prop: Node3D) -> void:
	if _open_panel == panel:
		return
	_hide_panels()
	_home.hide()
	_open_panel = panel
	_show_prop(prop)
	_director.focus(anchor)
	_reveal(panel)


#fly back to the wide shot and bring the buttons back
func _go_home() -> void:
	_hide_panels()
	_open_panel = null
	if _open_prop != null:
		_open_prop.hide()
		_open_prop = null
	_director.focus(_home_view)
	_reveal(_home)


#swap the lit wall prop: hide the old one, pop the new one in while it's still
#small in frame, and fade its text up as the camera flies over
func _show_prop(prop: Node3D) -> void:
	if _open_prop != null and _open_prop != prop:
		_open_prop.hide()
	_open_prop = prop
	prop.show()
	for label: Label3D in prop.find_children("*", "Label3D", true, false):
		label.modulate.a = 0.0
		var t := label.create_tween()
		t.tween_interval(reveal_delay)
		t.tween_property(label, "modulate:a", _label_alphas[label], reveal_time)


#hard-hide every screen so nothing overlaps mid-switch
func _hide_panels() -> void:
	_settings_panel.hide()
	_credits_panel.hide()
	_howto_panel.hide()


#fade a control in after the camera has mostly arrived
func _reveal(panel: Control) -> void:
	panel.modulate.a = 0.0
	panel.show()
	var t := panel.create_tween()
	t.tween_interval(reveal_delay)
	t.tween_property(panel, "modulate:a", 1.0, reveal_time)


#start shift wipes any saved night — ask first if one exists
func _on_start() -> void:
	if Settings.night >= 0:
		%NewShiftConfirm.popup_centered()
	else:
		_begin_new_shift()


func _begin_new_shift() -> void:
	Settings.clear_night()
	TransitionScreen.change_scene("res://scenes/game.tscn")


#pick the shift back up on the saved night
func _on_continue() -> void:
	TransitionScreen.change_scene("res://scenes/game.tscn")


func _on_quit() -> void:
	get_tree().quit()


#seed the sliders/toggle from saved settings without firing their change signals,
#then start listening so only real user tweaks write to disk
func _init_settings_controls() -> void:
	_master_slider.set_value_no_signal(Settings.master)
	_music_slider.set_value_no_signal(Settings.music)
	_sfx_slider.set_value_no_signal(Settings.sfx)
	_fullscreen_check.set_pressed_no_signal(Settings.fullscreen)
	_master_slider.value_changed.connect(func(v: float) -> void: Settings.set_master(v))
	_music_slider.value_changed.connect(func(v: float) -> void: Settings.set_music(v))
	_sfx_slider.value_changed.connect(func(v: float) -> void: Settings.set_sfx(v))
	_fullscreen_check.toggled.connect(func(on: bool) -> void: Settings.set_fullscreen(on))
