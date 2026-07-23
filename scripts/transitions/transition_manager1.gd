extends Node
#manages the transition from one scene to the next

@export var tr_panel : Panel
@export var tr_label : RichTextLabel
@export var tr_button : Button

var rows : Array[String] = [
	"…Mom?",
	"Evelyn? My little girl! How are the children? And your father?",
	"The kids are well, they often ask about you. Dad… we don’t really talk.",
	"I see, I don’t blame you. Still, let’s focus on the children today, we don’t have much time."
]

var delay := 2.0
func show_rows():
	for i in rows:
		tr_label.text += i + "\n"
		await get_tree().create_timer(delay).timeout

func transition():
	tr_panel.visible = true
	await show_rows()
	tr_button.visible = true
	

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Levels/level2.tscn")
