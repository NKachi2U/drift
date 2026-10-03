extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(2.0).timeout   
	DialogueManager.show_dialogue_balloon(load("res://data/dialogue/untitled.dialogue"), "start")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
