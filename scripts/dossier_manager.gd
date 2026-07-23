extends Node
#this script manages the dossier on the desk
#the signals are called via manual raycasting by the Room node

@export var dossier_panel : Panel
@export var pages : Array[RichTextLabel]
var current_page : int = 0

func _ready():
	for i in get_tree().get_nodes_in_group("dossierPages"):
		pages.append(i)

func show_panel():
	dossier_panel.visible = true
func hide_panel():
	dossier_panel.visible = false

#to set the current page as visible
func set_page():
	for i in pages:
		i.visible = false
	pages[current_page].visible = true
func page_forward():
	current_page += 1
	if current_page >= pages.size():
		current_page = 0
	set_page()
func page_back():
	current_page -= 1
	if current_page <= -1:
		current_page = (pages.size() -1)
	set_page()

func _on_room_dossier_signal() -> void:
	show_panel()
	set_page()
func _on_bye_button_pressed() -> void:
	hide_panel()
func _on_forward_button_pressed() -> void:
	page_forward()
func _on_back_button_pressed() -> void:
	page_back()
