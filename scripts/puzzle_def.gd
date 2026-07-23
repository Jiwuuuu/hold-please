class_name PuzzleDef
extends Resource
#one puzzle of the campaign, pure data. the puzzle manager walks an array
#of these, so adding a puzzle is just filling a new one in the inspector.

#shown on the hud and the task paper header
@export var title : String = ""

#the full daily task text: listening line, caller requests, instructions
@export_multiline var task_text : String = ""

#how many callers ring this puzzle: jacks 1..callers light up, the rest stay dark
@export_range(1, 4) var callers : int = 1

#the four listening ghosts in socket order — floats above the sockets
@export var listening : Array[String] = ["", "", "", ""]

#one short request line per caller, shown on the hud while carrying their cable
@export_multiline var caller_lines : Array[String] = []

#required connections as "<socketcode><jack>" (e.g. "DD01"), "XXXX" = unused slot
@export var solution : Array[String] = ["XXXX", "XXXX", "XXXX", "XXXX"]

#the little conversation played after solving
@export_multiline var vignette_rows : Array[String] = []

#one nudge per caller (index 0 = caller 01), shown after two failed verifies
@export_multiline var hints : Array[String] = []
