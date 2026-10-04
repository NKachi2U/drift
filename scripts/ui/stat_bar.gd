extends HBoxContainer
## One stat: icon and number. Follows GameState on its own.

const TWEEN_TIME = 0.4

@export var stat_name := "style"
@export var icon: Texture2D

var _shown := 0.0
var _tween: Tween
@onready var _icon: TextureRect = $Icon
@onready var _value: Label = $Value

func _ready() -> void:
	_icon.texture = icon
	_show_value(GameState.stat(stat_name))
	GameState.stats_changed.connect(_on_stats_changed)

func _on_stats_changed(stats: Dictionary) -> void:
	var target: float = stats.get(stat_name, 0)
	if is_equal_approx(target, _shown):
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_show_value, _shown, target, TWEEN_TIME)

func _show_value(value: float) -> void:
	_shown = value
	_value.text = str(roundi(value))
