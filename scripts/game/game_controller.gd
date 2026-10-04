extends Node
## Walks the beats in run.json, one at a time.
## Choices come from any node with present(prompt, options) and a chosen(index) signal.

const MENU_SCENE = "res://scenes/MainMenu.tscn"
const MEMORIES_DIALOGUE = preload("res://data/dialogue/memories.dialogue")
const CARD_ART = "res://assets/Cards/%s.jpg"
const AFTER_CHOICE_PAUSE = 0.7
const MEMORIES_OFFERED = 3
# The one card in a memory event that is not a memory.
const DEATH = "death"

@export var choices: Node
@export var memory_picker: Node

func run() -> void:
	for beat: String in Content.run():
		if beat.begins_with("sit:"):
			await _play_situation(beat.trim_prefix("sit:"))
		elif beat.begins_with("mem:"):
			await _play_memory_event(beat.trim_prefix("mem:"))
		elif beat.begins_with("say:"):
			await _say(beat.trim_prefix("say:"))
		elif beat == "end":
			break
		else:
			push_error("GameController: unknown beat '%s'" % beat)
		if GameState.died:
			break
	await _play_ending()

func _play_situation(id: String) -> void:
	var situation := Content.situation(id)
	if situation.is_empty():
		return
	var options: Array[String] = []
	for choice: Dictionary in situation["choices"]:
		var effects := _describe(choice)
		var label: String = choice.get("label", "")
		options.append(label if effects == "" else "%s\n\n%s" % [label, effects])
	choices.present(situation.get("text", ""), options)
	var index: int = await choices.chosen
	var picked: Dictionary = situation["choices"][index]
	GameState.apply(picked)
	if picked.get("dies", false):
		GameState.die()
	await get_tree().create_timer(AFTER_CHOICE_PAUSE).timeout

## One memory has to go each time. intro_cue is a label in memories.dialogue, where the
## give-up choice itself is written too.
func _play_memory_event(intro_cue: String) -> void:
	if GameState.beads_left() <= 1:
		return
	await _say(intro_cue)
	var offered: Array = GameState.held_memories.duplicate()
	offered.shuffle()
	offered.resize(mini(MEMORIES_OFFERED, offered.size()))
	var cards: Array[Dictionary] = []
	for id: String in offered:
		cards.append(_card(id, Content.memory(id).get("card", "")))
	cards.append(_card(DEATH, "Death"))
	while true:
		memory_picker.present(cards)
		var id: String = await memory_picker.picked
		if id == DEATH:
			await _say(DEATH)
			if GameState.died:
				return
			continue
		await _say(Content.memory(id).get("cue", ""))
		if not GameState.holds(id):
			break
	await _say("memory_gone")
	await get_tree().create_timer(AFTER_CHOICE_PAUSE).timeout

func _play_ending() -> void:
	var id := GameState.pick_ending()
	await _say("ending_" + id)
	var back: Array[String] = ["Return to the menu"]
	choices.present(Content.ending(id).get("title", ""), back)
	await choices.chosen
	get_tree().change_scene_to_file(MENU_SCENE)

func _card(id: String, art: String) -> Dictionary:
	return {"id": id, "texture": load(CARD_ART % art)}

func _say(cue: String) -> void:
	DialogueManager.show_dialogue_balloon(MEMORIES_DIALOGUE, cue)
	await DialogueManager.dialogue_ended

func _describe(choice: Dictionary) -> String:
	var parts: PackedStringArray = []
	for stat_name in GameState.STATS:
		var amount := int(choice.get(stat_name, 0))
		if amount != 0:
			parts.append("%+d %s" % [amount, stat_name.capitalize()])
	return "   ".join(parts)
