extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	Button.new().pressed.connect(func():
		get_tree().quit(0)
	)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
