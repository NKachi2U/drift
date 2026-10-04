extends CanvasLayer
## Full-screen ending image with a button back to the menu.

signal closed

const FADE_TIME = 1.0

@onready var _root: Control = $Root
@onready var _image: TextureRect = %Image
@onready var _return: Button = %Return

func _ready() -> void:
	_root.hide()
	_return.hide()
	_return.pressed.connect(func(): closed.emit())

func show_ending(texture: Texture2D) -> void:
	_image.texture = texture
	_root.modulate.a = 0.0
	_root.show()
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 1.0, FADE_TIME)
	await tween.finished

func offer_return() -> void:
	_return.show()
