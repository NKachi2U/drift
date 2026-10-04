extends TextureRect
## The raft on the river. Shows the empty raft once the player has died.

const BOB_HEIGHT = 6.0
const BOB_TIME = 2.4

@export var with_person: Texture2D
@export var empty: Texture2D

func _ready() -> void:
	texture = empty if GameState.died else with_person
	GameState.player_died.connect(func(): texture = empty)
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y + BOB_HEIGHT, BOB_TIME)
	tween.tween_property(self, "position:y", position.y, BOB_TIME)
