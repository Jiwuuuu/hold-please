class_name TuningMinigame
extends Control
#the breaker minigame: hold A/D to tune your line's frequency onto the
#drifting target wave, then hold the match until the lock meter fills.
#esc backs out without fixing anything.

signal succeeded
signal aborted

@export var tune_speed: float = 1.6
@export var freq_min: float = 1.0
@export var freq_max: float = 6.0
@export var drift_speed: float = 0.35
@export var drift_amount: float = 0.8
@export var lock_tolerance: float = 0.25
@export var lock_time: float = 2.0
#how much faster the meter empties than it fills when the match slips
@export var drain_rate: float = 1.5

var _running: bool = false
var _target_base: float = 0.0
var _player_freq: float = 0.0
var _lock: float = 0.0
var _tolerance: float = 0.25
var _drift: float = 0.8
var _time: float = 0.0

@onready var _scope: TuningScope = %Scope
@onready var _lock_meter: ProgressBar = %LockMeter


func _ready() -> void:
	visible = false


#difficulty is the night index: later nights get a tighter lock and more drift
func begin(difficulty: float) -> void:
	_tolerance = lock_tolerance / (1.0 + 0.3 * difficulty)
	_drift = drift_amount * (1.0 + 0.25 * difficulty)
	_target_base = randf_range(freq_min + 1.0, freq_max - 1.0)
	_player_freq = freq_min
	_lock = 0.0
	_time = 0.0
	_running = true
	visible = true


func _process(delta: float) -> void:
	if not _running:
		return
	_time += delta
	#the target wanders on two slow sines so it never settles
	var target: float = _target_base \
		+ _drift * 0.5 * sin(_time * drift_speed * TAU) \
		+ _drift * 0.5 * sin(_time * drift_speed * 0.37 * TAU + 1.7)
	_player_freq = clampf(_player_freq + Inputs.move_vector().x * tune_speed * delta, freq_min, freq_max)
	var matched: bool = absf(target - _player_freq) < _tolerance
	if matched:
		_lock += delta / lock_time
	else:
		_lock = maxf(_lock - delta * drain_rate / lock_time, 0.0)
	_lock_meter.value = _lock * 100.0
	_scope.target_freq = target
	_scope.player_freq = _player_freq
	_scope.locked = matched
	_scope.queue_redraw()
	if _lock >= 1.0:
		_finish(true)


func _unhandled_input(event: InputEvent) -> void:
	if _running and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_finish(false)


func _finish(won: bool) -> void:
	_running = false
	visible = false
	if won:
		succeeded.emit()
	else:
		aborted.emit()
