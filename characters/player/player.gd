class_name PlayableCharacter2D
extends CharacterBody2D

@export_group("Movement")
## Maximum sideways movement speed (px/s)
@export_range(0.0, 10000.0, 1.0, "suffix:px/s") var move_velocity := 500.0
## Sideways movement acceleration (px/s/s)
@export_range(0.0, 10000.0, 1.0, "suffix:px/s/s") var acceleration := 2000.0
## Sideways movement deceleration (px/s/s)
@export_range(0.0, 10000.0, 1.0, "suffix:px/s/s") var deceleration := 5000.0
@export_group("Jump")
## Height of jump (px)
@export_range(0.0, 1000.0, 1.0, "suffix:px") var jump_height := 250.0
## Duration of a jump, from leaving the ground to landing (s)
## [br][br]
## [b]Note:[/b] The time set here assumes [member fall_gravity_multiplier] is 1.
## If [member fall_gravity_multiplier] is > 1.0 the actual duration will be shorter.
@export_range(0.0, 10.0, 0.1, "suffix:s") var jump_duration := 1.0
@export_group("Fall")
## Maximum speed when falling (px/s)
@export_range(0.0, 10000.0, 1.0, "suffix:px/s") var terminal_velocity := 2000.0
## Gravity multiplier for falling
## [br][br]
## Set to 1 causes the up and down motion of a jump to
## be the same duration. Set to > 1 causes the down motion to be quicker.
@export_range(0.0, 10.0, 0.1, "suffix:px/s") var fall_gravity_multiplier := 2.5

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
@onready var camera: CustomCamera2D = $Camera
@onready var dirt_particles: CPUParticles2D = $DirtParticles

func _physics_process(delta: float) -> void:
	state = CharacterState.IDLE
	var gravity := -up_direction * (8.0 * jump_height * 0.9677 / pow(jump_duration, 2.0))
	var falling := velocity.y > 0
	if not is_on_floor():
		if falling:
			state = CharacterState.FALLING
			gravity *= fall_gravity_multiplier
		else:
			state = CharacterState.RISING
		velocity += gravity * delta
		velocity = velocity.clampf(-terminal_velocity, terminal_velocity)

	var jumped := Input.is_action_just_pressed("jump") and is_on_floor()
	var jump_cancelled := Input.is_action_just_released("jump") and velocity.y < 0
	var jump_velocity := -gravity.y * jump_duration / 2.0
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
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	elif breaking:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	else:
		velocity.x += acceleration * input_horizontal * delta
		velocity.x = clampf(velocity.x, -move_velocity, move_velocity)

	if is_on_floor() and input_horizontal:
		if was_idle:
			state = CharacterState.WALKING_START
		else:
			state = CharacterState.WALKING

	move_and_slide()

	if falling and is_on_floor():
		state = CharacterState.LANDING

	_handle_animations(input_horizontal)

	handle_particles(input_horizontal)

func _handle_animations(input: float) -> void:
	var state_to_animation: Dictionary[CharacterState, String] = {
		CharacterState.IDLE: "idle",
		CharacterState.JUMPING: "jump-start",
		CharacterState.RISING: "rising",
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
	if (event.is_action_pressed("move_camera_up")):
		camera.move_camera_up()
	if (event.is_action_pressed("move_camera_down")):
		camera.move_camera_down()
	if (event.is_action_released("move_camera_up")):
		camera.center_camera()
	if (event.is_action_released("move_camera_down")):
		camera.center_camera()

func handle_particles(lr_direction: float) -> void:
	# Show or hide particles
	dirt_particles.visible = (state == CharacterState.WALKING)

	# Set particle direction to behind the player
	if lr_direction > 0:
		dirt_particles.direction.x = -1.0
	elif lr_direction < 0:
		dirt_particles.direction.x = 1.0
