extends Control
## The big character. Only shown while dialogue is playing or a choice is on screen.

const FADE_TIME = 0.3

@export var choices: Node

var _talking := false
var _choosing := false
var _tween: Tween

func _ready() -> void:
	modulate.a = 0.0
	DialogueManager.dialogue_started.connect(func(_resource): _set_talking(true))
	DialogueManager.dialogue_ended.connect(func(_resource): _set_talking(false))
	choices.opened.connect(func(): _set_choosing(true))
	choices.closed.connect(func(): _set_choosing(false))
	GameState.player_died.connect(_refresh)

func _set_talking(value: bool) -> void:
	_talking = value
	_refresh()

func _set_choosing(value: bool) -> void:
	_choosing = value
	_refresh()

func _refresh() -> void:
	var target := 1.0 if (_talking or _choosing) and not GameState.died else 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", target, FADE_TIME)
