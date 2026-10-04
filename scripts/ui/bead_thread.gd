extends Control
## A hanging thread with one bead per memory still held.

const SPACING = 34.0
const RADIUS = 10.0
const THREAD_COLOR = Color(1, 1, 1, 0.8)

func _ready() -> void:
	GameState.stats_changed.connect(func(_stats): queue_redraw())

func _draw() -> void:
	var count := GameState.beads_left()
	var x := size.x / 2
	draw_line(Vector2(x, 0), Vector2(x, SPACING * (count + 0.5)), THREAD_COLOR, 2.0)
	for i in count:
		var memory := Content.memory(GameState.held_memories[i])
		var center := Vector2(x, SPACING * (i + 1))
		draw_circle(center, RADIUS, Color.from_string(memory.get("color", ""), Color.WHITE))
		draw_arc(center, RADIUS, 0, TAU, 24, THREAD_COLOR, 1.5)
