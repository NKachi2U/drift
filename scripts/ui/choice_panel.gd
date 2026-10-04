extends CanvasLayer
## Placeholder choice UI: a prompt and one button per option.
## Anything that replaces it needs present(prompt, options) and the chosen(index) signal.

signal chosen(index: int)

const FADE_TIME = 0.25

@onready var _root: Control = $Root
@onready var _prompt: Label = %Prompt
@onready var _options: HBoxContainer = %Options

func _ready() -> void:
	_root.hide()

func present(prompt: String, options: Array[String]) -> void:
	for old in _options.get_children():
		old.queue_free()
	_prompt.text = prompt
	for i in options.size():
		var button := Button.new()
		button.text = options[i]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_option_pressed.bind(i))
		_options.add_child(button)
	_root.modulate.a = 0.0
	_root.show()
	create_tween().tween_property(_root, "modulate:a", 1.0, FADE_TIME)

func _on_option_pressed(index: int) -> void:
	for button: Button in _options.get_children():
		button.disabled = true
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, FADE_TIME)
	await tween.finished
	_root.hide()
	chosen.emit(index)
