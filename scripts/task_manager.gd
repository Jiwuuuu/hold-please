extends Node
#simpler script to manage the daily task panel

@export var panel : Panel

func _on_room_task_signal() -> void:
	panel.visible = true
func _on_bye_button_pressed() -> void:
	panel.visible = false
