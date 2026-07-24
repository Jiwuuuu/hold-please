extends Node
#saved options, applied on boot so they hold in the menu and the game alike.
#lives at user://settings.cfg. audio rides the Master/Music/SFX buses from
#default_bus_layout.tres; a slider at 0 mutes instead of dropping to -inf db.

const PATH := "user://settings.cfg"

var master: float = 0.8
var music: float = 0.8
var sfx: float = 0.8
var fullscreen: bool = false
#the saved night index; -1 means no shift in progress
var night: int = -1


func _ready() -> void:
	_load()
	_apply_all()
	#opt into wavedash platform features. safe no-op off the web.
	WavedashSDK.init({})


func set_master(v: float) -> void:
	master = v
	_apply_bus("Master", v)
	_save()


func set_music(v: float) -> void:
	music = v
	_apply_bus("Music", v)
	_save()


func set_sfx(v: float) -> void:
	sfx = v
	_apply_bus("SFX", v)
	_save()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_fullscreen()
	_save()


#shift progress, so the menu can offer continue
func set_night(v: int) -> void:
	night = v
	_save()


func clear_night() -> void:
	night = -1
	_save()


#push a linear 0..1 level onto a bus, muting it at the very bottom
func _apply_bus(bus_name: String, v: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, v <= 0.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(v))


func _apply_fullscreen() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _apply_all() -> void:
	_apply_bus("Master", master)
	_apply_bus("Music", music)
	_apply_bus("SFX", sfx)
	_apply_fullscreen()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	master = cfg.get_value("audio", "master", master)
	music = cfg.get_value("audio", "music", music)
	sfx = cfg.get_value("audio", "sfx", sfx)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	night = cfg.get_value("progress", "night", night)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master)
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("progress", "night", night)
	cfg.save(PATH)
