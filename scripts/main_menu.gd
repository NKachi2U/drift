extends Control

var _starting := false
var _fade: TextureRect

func _ready() -> void:
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

func _on_start_pressed() -> void:
	if _starting:
		return
	_starting = true
	$VBoxContainer/Start.disabled = true
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", 1.0, 1.0)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_settings_pressed():
	print("Settings clicked")

func _on_quit_pressed():
	get_tree().quit()
	
