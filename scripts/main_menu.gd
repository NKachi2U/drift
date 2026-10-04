extends Control

var _starting := false
var _fade: TextureRect
static var _beginning_played := false
const BEGINNING_DIALOGUE = preload("res://data/dialogue/untitled.dialogue")
@onready var _buttons: Array[TextureButton] = [
	$VBoxContainer/Control/Start,
	#$VBoxContainer/Control2/Settings,
	$VBoxContainer/Control3/Quit,
]

func _ready() -> void:
	for button in _buttons:
		button.modulate.a = 0.0 if not _beginning_played else 1.0
		button.disabled = not _beginning_played
	var background_layer := CanvasLayer.new()
	background_layer.layer = -1
	add_child(background_layer)
	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.texture = preload("res://assets/intro_fade.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_layer.add_child(background)
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = TextureRect.new()
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.texture = preload("res://assets/intro_fade.png")
	_fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fade.modulate.a = 0.0
	layer.add_child(_fade)
	if not _beginning_played:
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
		DialogueManager.show_dialogue_balloon(BEGINNING_DIALOGUE, "beginning")

func _on_dialogue_ended(resource: DialogueResource) -> void:
	if resource != BEGINNING_DIALOGUE:
		return
	DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
	_beginning_played = true
	var tween := create_tween()
	tween.set_parallel(true)
	for button in _buttons:
		tween.tween_property(button, "modulate:a", 1.0, 1.0)
	await tween.finished
	for button in _buttons:
		button.disabled = false

func _on_start_pressed() -> void:
	if _starting:
		return
	_starting = true
	_buttons[0].disabled = true
	Music.play("main")
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, 1.0)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

#func _on_settings_pressed():
	#print("Settings clicked")

func _on_quit_pressed():
	get_tree().quit()
	
