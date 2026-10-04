extends TextureRect
## The raft on the river. Empty once the player has died, and while the big character is on screen.

const BOB_HEIGHT = 6.0
const BOB_TIME = 2.4

@export var with_person: Texture2D
@export var empty: Texture2D
@export var portrait: Node

var _portrait_present := false

func _ready() -> void:
	GameState.player_died.connect(_refresh)
	portrait.presence_changed.connect(_on_portrait_presence_changed)
	_refresh()
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y + BOB_HEIGHT, BOB_TIME)
	tween.tween_property(self, "position:y", position.y, BOB_TIME)

func _on_portrait_presence_changed(present: bool) -> void:
	_portrait_present = present
	_refresh()

func _refresh() -> void:
	texture = empty if GameState.died or _portrait_present else with_person
