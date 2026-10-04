extends Node
## Walks the beats in run.json, one at a time.
## Choices come from any node with present(prompt, options) and a chosen(index) signal.

const MENU_SCENE = "res://scenes/MainMenu.tscn"
const AFTER_CHOICE_PAUSE = 0.7

@export var choices: Node

func run() -> void:
	for beat: String in Content.run():
		if beat.begins_with("sit:"):
			await _play_situation(beat.trim_prefix("sit:"))
		elif beat == "mem":
			await _play_memory_event()
		elif beat == "end":
			await _play_ending()
			return
		else:
			push_error("GameController: unknown beat '%s'" % beat)

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

# TODO: tarot pick, memory text and the give-up choice.
func _play_memory_event() -> void:
	pass

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
	return "   ".join(parts)
