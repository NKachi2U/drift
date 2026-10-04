extends Node
## Walks the beats in run.json, one at a time.
## Choices come from any node with present(prompt, options) and a chosen(index) signal.

const MENU_SCENE = "res://scenes/MainMenu.tscn"
const MEMORIES_DIALOGUE = preload("res://data/dialogue/memories.dialogue")
const CARD_ART = "res://assets/Cards/%s.jpg"
const AFTER_CHOICE_PAUSE = 0.7
# Cards in a memory event that are not memories.
const HANGED_MAN = "hanged_man"
const DEATH = "death"

@export var choices: Node
@export var memory_picker: Node

func run() -> void:
	for beat: String in Content.run():
		if beat.begins_with("sit:"):
			await _play_situation(beat.trim_prefix("sit:"))
		elif beat.begins_with("mem:"):
			await _play_memory_event(beat.trim_prefix("mem:"))
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
		options.append("%s\n\n%s" % [choice.get("label", ""), _describe(choice)])
	choices.present(situation.get("text", ""), options)
	var index: int = await choices.chosen
	var picked: Dictionary = situation["choices"][index]
	GameState.apply(picked)
	if picked.get("dies", false):
		GameState.die()
	await get_tree().create_timer(AFTER_CHOICE_PAUSE).timeout
	if picked.get("memory_event", false):
		await _play_memory_event("")

## intro_cue is a label in memories.dialogue. The give-up choice itself is written there too.
func _play_memory_event(intro_cue: String) -> void:
	if intro_cue != "":
		await _say(intro_cue)
	while true:
		memory_picker.present(_memory_cards())
		var id: String = await memory_picker.picked
		if id == HANGED_MAN:
			await _say(HANGED_MAN)
		elif id == DEATH:
			await _say(DEATH)
			if not GameState.died:
				continue
		elif id == GameState.FOOL_ID:
			await _say(Content.memory(id).get("cue", ""))
			GameState.take_fool()
		else:
			await _say(Content.memory(id).get("cue", ""))
			if not GameState.holds(id):
				await _say("memory_gone")
		break
	await get_tree().create_timer(AFTER_CHOICE_PAUSE).timeout

func _memory_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for id: String in GameState.held_memories:
		if id != GameState.FOOL_ID:
			cards.append(_card(id, Content.memory(id).get("card", "")))
	if GameState.fool_unlocked():
		cards.append(_card(GameState.FOOL_ID, Content.memory(GameState.FOOL_ID).get("card", "")))
	cards.append(_card(HANGED_MAN, "TheHangedMan"))
	cards.append(_card(DEATH, "Death"))
	return cards

func _card(id: String, art: String) -> Dictionary:
	return {"id": id, "texture": load(CARD_ART % art)}

func _say(cue: String) -> void:
	DialogueManager.show_dialogue_balloon(MEMORIES_DIALOGUE, cue)
	await DialogueManager.dialogue_ended

func _play_ending() -> void:
	var ending := Content.ending(GameState.pick_ending())
	var back: Array[String] = ["Return to the menu"]
	choices.present("%s\n\n%s" % [ending.get("title", ""), ending.get("text", "")], back)
	await choices.chosen
	get_tree().change_scene_to_file(MENU_SCENE)

func _describe(choice: Dictionary) -> String:
	var parts: PackedStringArray = []
	for stat_name in GameState.STATS:
		var amount := int(choice.get(stat_name, 0))
		if amount != 0:
			parts.append("%+d %s" % [amount, stat_name.capitalize()])
	return "\n".join(parts)
