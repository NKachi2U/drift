extends Node
## Loads the game's content from JSON once at startup.

const SITUATIONS_PATH = "res://data/situations.json"
const MEMORIES_PATH = "res://data/memories.json"
const ENDINGS_PATH = "res://data/endings.json"
const RUN_PATH = "res://data/run.json"

var _situations: Dictionary = {}
var _memories: Dictionary = {}
var _endings: Dictionary = {}
var _memory_order: Array = []
var _run: Array = []

func _ready() -> void:
	_situations = _index_by_id(_load_array(SITUATIONS_PATH))
	var memory_list := _load_array(MEMORIES_PATH)
	_memories = _index_by_id(memory_list)
	for memory in memory_list:
		_memory_order.append(memory.get("id", ""))
	_endings = _index_by_id(_load_array(ENDINGS_PATH))
	_run = _load_array(RUN_PATH)

func situation(id: String) -> Dictionary:
	return _get_entry(_situations, id, "situation")

func memory(id: String) -> Dictionary:
	return _get_entry(_memories, id, "memory")

func ending(id: String) -> Dictionary:
	return _get_entry(_endings, id, "ending")

func has_memory(id: String) -> bool:
	return _memories.has(id)

## Memory ids in the order they appear in memories.json.
func memory_ids() -> Array:
	return _memory_order.duplicate()

## The ordered beats of a playthrough, e.g. "sit:relax", "mem", "end".
func run() -> Array:
	return _run.duplicate()

func _get_entry(table: Dictionary, id: String, kind: String) -> Dictionary:
	if not table.has(id):
		push_error("Content: unknown %s '%s'" % [kind, id])
		return {}
	return table[id]

func _load_array(path: String) -> Array:
	if not FileAccess.file_exists(path):
		push_error("Content: missing file %s" % path)
		return []
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		push_error("Content: %s line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return []
	if not json.data is Array:
		push_error("Content: %s must contain a list" % path)
		return []
	return json.data

func _index_by_id(entries: Array) -> Dictionary:
	var table := {}
	for entry in entries:
		if not entry is Dictionary or not entry.has("id"):
			push_error("Content: entry without an id: %s" % str(entry))
			continue
		if table.has(entry["id"]):
			push_error("Content: duplicate id '%s'" % entry["id"])
		table[entry["id"]] = entry
	return table
