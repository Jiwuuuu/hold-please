extends Node
#shows the little after-puzzle conversation one row at a time, then a
#button to move on. the rows come from the solved puzzle's data, so one
#manager serves the whole campaign.

signal advance_pressed

@export var tr_panel : Panel
@export var tr_label : RichTextLabel
@export var tr_button : Button
@export var row_delay : float = 2.0


func play(rows: Array[String]) -> void:
	tr_label.text = ""
	tr_button.visible = false
	tr_panel.visible = true
	for row: String in rows:
		tr_label.text += row + "\n"
		#pause-respecting timer, so the vignette freezes with the pause menu
		await get_tree().create_timer(row_delay, false).timeout
	tr_button.visible = true


func _on_button_pressed() -> void:
	tr_panel.visible = false
	advance_pressed.emit()
