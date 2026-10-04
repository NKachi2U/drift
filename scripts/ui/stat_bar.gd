extends HBoxContainer
## One stat: icon, bar and number. Follows GameState on its own.

const TWEEN_TIME = 0.4

@export var stat_name := "style"
@export var icon: Texture2D

var _shown := 0.0
var _tween: Tween
@onready var _icon: TextureRect = $Icon
@onready var _bar: TextureProgressBar = $BarHolder/Bar
@onready var _value: Label = $Value

func _ready() -> void:
	_icon.texture = icon
	_bar.max_value = GameState.BAR_MAX
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

# The bar stops at BAR_MAX, the number keeps counting.
func _show_value(value: float) -> void:
	_shown = value
	_bar.value = value
	_value.text = str(roundi(value))
