class_name PlayableCharacter2D
extends CharacterBody2D


const MAX_VELOCITY_WALK = 500.0
const TERMINAL_VELOCITY = 2000.0
const JUMP_HEIGHT = 225.0
const JUMP_TIME = 1.0
const ACCELERATION = 2000.0
const DECELERATION = 5000.0
const FALL_GRAVITY_MULTIPLIER = 3.5

enum CharacterState {
	IDLE,
	JUMPING,
	RISING,
	FALLING,
	LANDING,
	WALKING_START,
	WALKING,
}

var state := CharacterState.IDLE
@onready var sprite: AnimatedSprite2D = $Sprite

func _physics_process(delta: float) -> void:
	state = CharacterState.IDLE
	var acceleration := -up_direction * (8.0 * JUMP_HEIGHT / pow(JUMP_TIME, 2.0))
	var falling := velocity.y > 0
	if not is_on_floor():
		if falling:
			state = CharacterState.FALLING
			acceleration *= FALL_GRAVITY_MULTIPLIER
		else:
			state = CharacterState.RISING
		velocity += acceleration * delta
		velocity = velocity.clampf(-TERMINAL_VELOCITY, TERMINAL_VELOCITY)

	var jumped := Input.is_action_just_pressed("jump") and is_on_floor()
	var jump_cancelled := Input.is_action_just_released("jump") and velocity.y < 0
	var jump_velocity := -acceleration.y * JUMP_TIME / 2.0
	if jumped:
		velocity.y = jump_velocity
		state = CharacterState.JUMPING
	elif jump_cancelled:
		velocity.y *= 0.2
		state = CharacterState.RISING

	var input_horizontal := Input.get_axis("left", "right")
	var breaking := signf(input_horizontal) + signf(velocity.x) == 0
	var was_idle := not velocity.x
	if not input_horizontal:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
	elif breaking:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
	else:
		velocity.x += ACCELERATION * input_horizontal * delta
		velocity.x = clampf(velocity.x, -MAX_VELOCITY_WALK, MAX_VELOCITY_WALK)

	if is_on_floor() and input_horizontal:
		if was_idle:
			state = CharacterState.WALKING_START
		else:
			state = CharacterState.WALKING

	move_and_slide()

	if falling and is_on_floor():
		state = CharacterState.LANDING

	_handle_animations(input_horizontal)

func _handle_animations(input: float) -> void:
	var state_to_animation: Dictionary[CharacterState, String] = {
		CharacterState.IDLE: "idle",
		CharacterState.JUMPING: "jump-start",
		CharacterState.RISING: "idle",
		CharacterState.FALLING: "fall",
		CharacterState.LANDING: "land-start",
		CharacterState.WALKING_START: "walk-start",
		CharacterState.WALKING: "walk",
	}

	if sprite.animation.contains("start"):
		return

	sprite.animation = state_to_animation[state]

	if input:
		sprite.flip_h = input < 0

	sprite.play()

func _on_sprite_animation_finished() -> void:
	sprite.animation = "idle"
	_handle_animations(0.0)


	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("move_camera_down"):
		pass
		
	
	
	
	