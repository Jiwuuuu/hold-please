extends Node
#trips the power at random moments during a shift. while the power is out
#the room goes dark, the verify button is dead, and the only fix is the
#tuning minigame at the wall breaker.

signal power_lost
signal power_restored

@export var room : Node3D
@export var minigame : TuningMinigame
@export var outage_banner : Control
#panels that mean "not normal play" — the countdown pauses while any is up
@export var blocking_panels : Array[Control] = []

@export var min_between: float = 45.0
@export var max_between: float = 90.0
#calm stretch at the start of every night before an outage may hit
@export var grace_period: float = 20.0
#first night index that can have outages, so night 1 stays safe
@export var start_night: int = 1
@export var max_outages_per_night: int = 2

var powered: bool = true
var _countdown: float = 0.0
var _outages_left: int = 0
var _night: int = 0


func _ready() -> void:
	room.breaker_focused.connect(_on_breaker_focused)
	minigame.succeeded.connect(_on_minigame_succeeded)
	minigame.aborted.connect(_on_minigame_aborted)
	outage_banner.visible = false


func _process(delta: float) -> void:
	if not powered or not _is_safe_window():
		return
	_countdown -= delta
	if _countdown <= 0.0:
		_trip_power()


#the puzzle manager calls this on every night start and shift retry,
#so a new night never begins in the dark
func on_night_started(night: int) -> void:
	_night = night
	_outages_left = max_outages_per_night
	if not powered:
		_restore_power()
	_countdown = grace_period + randf_range(min_between, max_between)


func _is_safe_window() -> bool:
	if _night < start_night or _outages_left <= 0:
		return false
	if room.at_desk():
		return false
	for panel: Control in blocking_panels:
		if panel != null and panel.visible:
			return false
	return true


func _trip_power() -> void:
	powered = false
	_outages_left -= 1
	room.set_power(false)
	room.breaker_box.active = true
	outage_banner.visible = true
	power_lost.emit()


func _restore_power() -> void:
	powered = true
	room.set_power(true)
	room.breaker_box.active = false
	outage_banner.visible = false
	_countdown = randf_range(min_between, max_between)
	power_restored.emit()


func _on_breaker_focused() -> void:
	if not powered:
		minigame.begin(float(_night))


func _on_minigame_succeeded() -> void:
	_restore_power()
	room.close_breaker()


#backing out leaves the power down — the breaker still needs fixing
func _on_minigame_aborted() -> void:
	room.close_breaker()
