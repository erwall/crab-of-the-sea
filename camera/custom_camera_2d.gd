class_name CustomCamera2D
extends Camera2D

var move := false
var alpha := 0.0
var transition_time := .5
var org_pos := Vector2.ZERO

func _ready() -> void:
	pass

func _process(delta: float) -> void:	
	if (move):
		alpha += delta 	
		position = lerp(org_pos, target_pos, alpha / transition_time)
	if (alpha > 1):
		move = false


func MoveCamera(screen_space_delta: float, transition_time: float) -> void:
	org_pos = position
	target_pos = position + get_viewport_rect().size * screen_space_delta * Vector2.UP
