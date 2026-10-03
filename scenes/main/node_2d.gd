extends Node2D

var image_fullscreen = preload("res://assets/fullscreen.png")
var image_windowed = preload("res://assets/windowed.png")

func _on_toggle_fullscreen_pressed() -> void:
	if is_fullscreen_mode_active():
		do_windowed()
	else:
		do_fullscreen()
	setup_toggle_icon()

func setup_toggle_icon():
	if is_fullscreen_mode_active():
		$toggle_fullscreen.texture_normal = image_windowed
	else:
		$toggle_fullscreen.texture_normal = image_fullscreen
		

func do_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func do_windowed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func is_fullscreen_mode_active():
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return true
	if mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		return true
	return false
