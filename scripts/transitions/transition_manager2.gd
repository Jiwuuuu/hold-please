extends Node
#manages the transition from one scene to the next

@export var tr_panel : Panel
@export var tr_label : RichTextLabel
@export var tr_button : Button

var rows : Array[String] = [
	"You won’t believe it! The young couple next door…",
	"Won’t believe? I knew it! I always knew it!",
	"Alright, alright, don’t gloat too much.",
	"Oh, I’ll gloat plenty. I always knew, and you naysayers called me a hag!"
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
