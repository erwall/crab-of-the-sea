extends Label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	text = "FPS: " + str(1 / Performance.get_monitor(Performance.TIME_PROCESS)).pad_decimals(1)
