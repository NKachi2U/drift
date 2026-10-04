extends Node
## Owns every number in a playthrough. UI reads from here and listens to the signals.
## A stat is the base value (from choices) plus the packages of the memories still held.

signal stats_changed(stats: Dictionary)
signal memory_lost(memory_id: String)
signal memory_gained(memory_id: String)

const STATS: Array[String] = ["style", "sturdiness", "size"]
## Scale of the HUD bars. Stats themselves have no cap.
const BAR_MAX = 150
const FOOL_ID = "fool"

var base: Dictionary = {}
var held_memories: Array[String] = []
var died := false

func _ready() -> void:
	reset()

## Start a fresh playthrough.
func reset() -> void:
	died = false
	base = {}
	for stat_name in STATS:
		base[stat_name] = 0
	held_memories.clear()
	for id in Content.memory_ids():
		if Content.memory(id).get("starts_held", false):
			held_memories.append(id)
	stats_changed.emit(stats())

func stat(stat_name: String) -> int:
	var total: int = base.get(stat_name, 0)
	for id in held_memories:
		total += int(Content.memory(id).get("package", {}).get(stat_name, 0))
	return max(total, 0)

func stats() -> Dictionary:
	var result := {}
	for stat_name in STATS:
		result[stat_name] = stat(stat_name)
	return result

## Apply a choice. Takes any Dictionary with stat keys, so a choice from situations.json can be passed as is.
func apply(deltas: Dictionary) -> void:
	for stat_name in STATS:
		base[stat_name] += int(deltas.get(stat_name, 0))
	stats_changed.emit(stats())

## What giving up a memory costs, e.g. "lose 20 Style, 10 Sturdiness". Used by the dialogue files.
func cost_text(memory_id: String) -> String:
	var package: Dictionary = Content.memory(memory_id).get("package", {})
	var parts: PackedStringArray = []
	for stat_name in STATS:
		var amount := int(package.get(stat_name, 0))
		if amount != 0:
			parts.append("%d %s" % [amount, stat_name.capitalize()])
	return "lose " + ", ".join(parts)

func holds(memory_id: String) -> bool:
	return held_memories.has(memory_id)

func beads_left() -> int:
	return held_memories.size()

func give_up(memory_id: String) -> void:
	if not holds(memory_id):
		push_warning("GameState: memory '%s' is not held" % memory_id)
		return
	held_memories.erase(memory_id)
	memory_lost.emit(memory_id)
	stats_changed.emit(stats())

## The Death card: every memory goes into the river.
func give_up_all() -> void:
	died = true
	for id in held_memories.duplicate():
		held_memories.erase(id)
		memory_lost.emit(id)
	stats_changed.emit(stats())

## For "jump off the boat" style choices that end in the Death ending without losing memories.
func die() -> void:
	died = true

func fool_unlocked() -> bool:
	return held_memories.is_empty()

func take_fool() -> void:
	if not fool_unlocked():
		push_warning("GameState: the Fool is still locked")
		return
	held_memories.append(FOOL_ID)
	memory_gained.emit(FOOL_ID)
	stats_changed.emit(stats())

## Returns an id from endings.json. Ties go to the earlier stat in STATS.
func pick_ending() -> String:
	if died:
		return "death"
	var best := STATS[0]
	for stat_name in STATS:
		if stat(stat_name) > stat(best):
			best = stat_name
	return best
