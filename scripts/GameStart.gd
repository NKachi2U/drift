extends Control

var _fade: TextureRect
func _ready() -> void:
	GameState.reset()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_fade = TextureRect.new()
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.texture = preload("res://assets/intro_fade.png")
	_fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.add_child(_fade)
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 0.0, 1.2)
	await tween.finished
	_fade.hide()
	DialogueManager.show_dialogue_balloon(load("res://data/dialogue/untitled.dialogue"), "narration")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
