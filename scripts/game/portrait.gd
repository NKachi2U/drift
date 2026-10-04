extends Control
## The big character. Only shown while dialogue is playing.

## Emitted when the big character comes on or leaves the screen.
signal presence_changed(present: bool)

const FADE_TIME = 0.3

var _talking := false
var _present := false
var _tween: Tween

func _ready() -> void:
	modulate.a = 0.0
	DialogueManager.dialogue_started.connect(func(_resource): _set_talking(true))
	DialogueManager.dialogue_ended.connect(func(_resource): _set_talking(false))
	GameState.player_died.connect(_refresh)

func _set_talking(value: bool) -> void:
	_talking = value
	_refresh()

func _refresh() -> void:
	var present := _talking and not GameState.died
	if present != _present:
		_present = present
		presence_changed.emit(present)
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0 if present else 0.0, FADE_TIME)
