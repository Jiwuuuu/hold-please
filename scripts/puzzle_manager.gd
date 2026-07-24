extends Node
#the campaign manager. holds the ordered list of puzzles, checks the
#board against the current one, hands out strikes and hints on mistakes,
#and rolls the whole shift from tutorial 1 to the ending screen.

@export var room : Node3D
@export var tr_manager : Node

#the puzzles of the shift, in order, as PuzzleDef resources on this node
@export var puzzles : Array[PuzzleDef] = []
@export var max_strikes : int = 3

#the short opening card played before night 1 on a fresh shift
@export var prologue_rows : Array[String] = []

#hud + panels, all living in main.tscn
@export var task_label : RichTextLabel
@export var hud_label : Label
@export var carry_label : Label
@export var feedback_panel : Panel
@export var feedback_label : RichTextLabel
@export var feedback_button : Button
@export var ending_panel : Panel
@export var screen_fx : Node
@export var power_manager : Node

var index : int = 0
var strikes : int = 0
var fails : int = 0
#true once strikes run out, flips the feedback button into "start over"
var failed_shift : bool = false
#true while the prologue card is up, so its button doesn't skip night 1
var _prologue_open : bool = false


func _ready() -> void:
	#a saved night means the menu's continue button brought us here
	var fresh: bool = Settings.night < 0
	index = 0 if fresh else clampi(Settings.night, 0, puzzles.size() - 1)
	Settings.set_night(index)
	_apply_puzzle()
	if fresh and not prologue_rows.is_empty():
		_prologue_open = true
		tr_manager.play(prologue_rows)


func current_puzzle() -> PuzzleDef:
	return puzzles[index]


#reset the board and load the current puzzle's text and callers
func _apply_puzzle() -> void:
	strikes = max_strikes
	fails = 0
	failed_shift = false
	room.reset_board()
	room.set_active_callers(current_puzzle().callers)
	room.set_listening(current_puzzle().listening)
	task_label.text = current_puzzle().task_text
	_update_hud()
	if power_manager != null:
		power_manager.on_night_started(index)


func _update_hud() -> void:
	hud_label.text = "%s   —   strikes left: %d" % [current_puzzle().title, strikes]


#compare the board against the required connections.
#reports which callers sit on a wrong line, which are still waiting,
#and how many times the lines cross on the floor
func evaluate() -> Dictionary:
	room.get_solution()
	var required : Array[String] = []
	for combo: String in current_puzzle().solution:
		if combo != "XXXX":
			required.append(combo)
	var wrong : Array[String] = []
	var waiting : Array[String] = []
	for m: String in room.solution:
		if m.length() > 2 and not required.has(m):
			wrong.append(m.substr(2))
	for combo: String in required:
		if not room.solution.has(combo):
			var caller: String = combo.substr(2)
			if not wrong.has(caller):
				waiting.append(caller)
	var crossings: int = room.count_crossings()
	return {
		"correct": wrong.is_empty() and waiting.is_empty() and crossings == 0,
		"wrong": wrong,
		"waiting": waiting,
		"crossings": crossings,
	}


#the big button: verify the board
func do_solution() -> void:
	var report: Dictionary = evaluate()
	if report.correct:
		tr_manager.play(current_puzzle().vignette_rows)
	else:
		_handle_mistake(report)


func _handle_mistake(report: Dictionary) -> void:
	strikes -= 1
	fails += 1
	_update_hud()
	if screen_fx != null:
		screen_fx.glitch_burst()
	if report.crossings > 0:
		room.flash_spark()
	if strikes <= 0:
		failed_shift = true
		feedback_label.text = "The board falls silent. Too many wrong connections tonight.\n\nThe shift starts over — the callers are patient. They have time."
		feedback_button.text = "Start Over"
	else:
		feedback_label.text = _mistake_text(report)
		feedback_button.text = "Back to the Board"
	feedback_panel.visible = true


#turn the evaluation report into readable feedback lines
func _mistake_text(report: Dictionary) -> String:
	var lines : Array[String] = []
	for caller: String in report.wrong:
		lines.append("The caller on jack %s is connected to the wrong listener." % caller.trim_prefix("0"))
	for caller: String in report.waiting:
		lines.append("The caller on jack %s is still waiting to be connected." % caller.trim_prefix("0"))
	if report.crossings > 0:
		lines.append("Lines are tangling on the floor — route one of them through an anchor post so it passes above the other.")
	if fails >= 2:
		var hint: String = _pick_hint(report)
		if hint != "":
			lines.append("\nA whisper down the line: %s" % hint)
	lines.append("\nStrikes left: %d" % strikes)
	return "\n".join(lines)


#one authored nudge for the first caller that's wrong or waiting
func _pick_hint(report: Dictionary) -> String:
	var problem_callers : Array[String] = []
	problem_callers.append_array(report.wrong)
	problem_callers.append_array(report.waiting)
	problem_callers.sort()
	for caller: String in problem_callers:
		var i: int = caller.to_int() - 1
		if i >= 0 and i < current_puzzle().hints.size():
			return current_puzzle().hints[i]
	return ""


func _on_feedback_button_pressed() -> void:
	feedback_panel.visible = false
	if failed_shift:
		_apply_puzzle()


#the vignette's button: move to the next puzzle, or end the shift.
#the prologue uses the same panel, so its press just closes it.
func _on_transition_advanced() -> void:
	if _prologue_open:
		_prologue_open = false
		return
	if screen_fx != null:
		screen_fx.glitch_burst(0.4)
	index += 1
	if index >= puzzles.size():
		Settings.clear_night()
		ending_panel.visible = true
	else:
		Settings.set_night(index)
		_apply_puzzle()


func _on_ending_button_pressed() -> void:
	TransitionScreen.change_scene("res://scenes/main_menu.tscn")


func _on_room_big_button_signal() -> void:
	#clicks reach the desk even under an open panel, so ignore them there —
	#otherwise closing a panel could re-press the button and burn a strike
	if feedback_panel.visible or ending_panel.visible or tr_manager.tr_panel.visible:
		return
	#no verifying in the dark — the board is dead until the breaker is fixed
	if power_manager != null and not power_manager.powered:
		if screen_fx != null:
			screen_fx.glitch_burst(0.25)
		return
	do_solution()


#the hud line naming the caller whose cable is in the player's hands
func _update_carry_hud() -> void:
	if carry_label == null:
		return
	var p: Player = room.player()
	if p.is_carrying():
		var caller: int = p.carried_cable.message.to_int()
		var line: String = ""
		if caller >= 1 and caller <= current_puzzle().caller_lines.size():
			line = current_puzzle().caller_lines[caller - 1]
		carry_label.text = "Caller %d — “%s”" % [caller, line]
		carry_label.visible = true
	else:
		carry_label.visible = false


func _process(_delta: float) -> void:
	_update_carry_hud()
	#just for testing: Q prints the evaluation to the console
	if Inputs.debug_pressed():
		print(evaluate())
