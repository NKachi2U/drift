extends CanvasLayer
## Shows a row of tarot cards and reports which one was clicked.

signal picked(id: String)

const FADE_TIME = 0.3
const CARD_SIZE = Vector2(140, 196)
const HOVER_SCALE = Vector2(1.08, 1.08)

@onready var _root: Control = $Root
@onready var _cards: HBoxContainer = %Cards

func _ready() -> void:
	_root.hide()

## Each card is {"id": String, "texture": Texture2D}.
func present(cards: Array[Dictionary]) -> void:
	for old in _cards.get_children():
		old.queue_free()
	for card in cards:
		var button := TextureButton.new()
		button.texture_normal = card["texture"]
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.custom_minimum_size = CARD_SIZE
		button.pivot_offset = CARD_SIZE / 2
		button.mouse_entered.connect(func(): button.scale = HOVER_SCALE)
		button.mouse_exited.connect(func(): button.scale = Vector2.ONE)
		button.pressed.connect(_on_card_pressed.bind(card["id"]))
		_cards.add_child(button)
	_root.modulate.a = 0.0
	_root.show()
	create_tween().tween_property(_root, "modulate:a", 1.0, FADE_TIME)

func _on_card_pressed(id: String) -> void:
	for button: TextureButton in _cards.get_children():
		button.disabled = true
	var tween := create_tween()
	tween.tween_property(_root, "modulate:a", 0.0, FADE_TIME)
	await tween.finished
	_root.hide()
	picked.emit(id)
