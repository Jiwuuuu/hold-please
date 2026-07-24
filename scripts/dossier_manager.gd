extends Node
#this script manages the dossier on the desk
#the signals are called via manual raycasting by the Room node

@export var dossier_panel : Panel
@export var pages : Array[RichTextLabel]
@export var page_indicator : Label
var current_page : int = 0
#each page's authored rest position, so the flip slide can restore it
var _page_rest : Dictionary = {}
var _flip_tween : Tween

func _ready():
	for i in get_tree().get_nodes_in_group("dossierPages"):
		pages.append(i)
		_page_rest[i] = (i as Control).position

func show_panel():
	dossier_panel.visible = true
func hide_panel():
	dossier_panel.visible = false

#to set the current page as visible. flip_dir slides the page in from
#the side the press came from, 0 means no slide
func set_page(flip_dir: int = 0):
	for i in pages:
		i.visible = false
		i.position = _page_rest[i]
		i.modulate.a = 1.0
	var page: RichTextLabel = pages[current_page]
	page.visible = true
	if page_indicator != null:
		page_indicator.text = "page %d / %d" % [current_page + 1, pages.size()]
	if flip_dir != 0:
		if _flip_tween != null:
			_flip_tween.kill()
		page.position = _page_rest[page] + Vector2(48.0 * flip_dir, 0.0)
		page.modulate.a = 0.0
		_flip_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_flip_tween.tween_property(page, "position", _page_rest[page], 0.12)
		_flip_tween.tween_property(page, "modulate:a", 1.0, 0.12)
func page_forward():
	current_page += 1
	if current_page >= pages.size():
		current_page = 0
	set_page(1)
func page_back():
	current_page -= 1
	if current_page <= -1:
		current_page = (pages.size() -1)
	set_page(-1)

func _on_room_dossier_signal() -> void:
	show_panel()
	set_page()
func _on_bye_button_pressed() -> void:
	hide_panel()
func _on_forward_button_pressed() -> void:
	page_forward()
func _on_back_button_pressed() -> void:
	page_back()
