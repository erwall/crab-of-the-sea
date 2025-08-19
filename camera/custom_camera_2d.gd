class_name CustomCamera2D
extends Camera2D

@export var transition_time_out := .5
@export var transition_time_back := .5
@export var screen_space_offset := .5
@export var curve : Path2D

var move := false
var timer := 0.0
var org_pos := Vector2.ZERO
var target_pos := Vector2.ZERO
var transition_time := 0.0


func _ready() -> void:
	pass

func _process(delta: float) -> void:	
	if (move):
		timer += delta 	
		var alpha := timer / transition_time
		var curve_alpha : float = curve.curve.sample(0, alpha).y / 100
		position = lerp(org_pos, target_pos, curve_alpha)
		
		if (alpha > 1):
			move = false
			
func move_camera_up() -> void:
	var target := position + screen_space_offset * Vector2.UP * get_viewport_rect().size
	__move_camera(target, transition_time_out)
	
func move_camera_down() -> void:
	var target := position + screen_space_offset * Vector2.DOWN * get_viewport_rect().size
	__move_camera(target, transition_time_out)
	
func center_camera() -> void:
	__move_camera(Vector2.ZERO, transition_time_back)
	
func __move_camera(target: Vector2, time : float) -> void:
	org_pos = position
	move = true
	timer = 0.0
	target_pos = target
	transition_time = time
