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
## Maximum time to allow jump after walking off an edge (s)
@export_range(0.0, 10.0, 0.01, "suffix:s") var coyote_time := 0.1
## Maximum time to queue a jump before landing (s)
@export_range(0.0, 10.0, 0.01, "suffix:s") var jump_buffer := 0.2
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
	JUMP,
	FALL,
	MOVE,
}

var state := CharacterState.IDLE
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var camera: CustomCamera2D = $Camera
@onready var dirt_particles: CPUParticles2D = $DirtParticles
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer

func _physics_process(delta: float) -> void:
	match state:
		CharacterState.IDLE:
			_process_physics_idle(delta)
		CharacterState.MOVE:
			_process_physics_move(delta)
		CharacterState.JUMP:
			_process_physics_jump(delta)
		CharacterState.FALL:
			_process_physics_fall(delta)

func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("move_camera_up")):
		camera.move_camera_up()
	if (event.is_action_pressed("move_camera_down")):
		camera.move_camera_down()
	if (event.is_action_released("move_camera_up")):
		camera.center_camera()
	if (event.is_action_released("move_camera_down")):
		camera.center_camera()

	if event.is_action_pressed("left"):
		sprite.flip_h = true
	elif event.is_action_pressed("right"):
		sprite.flip_h = false

	match state:
		CharacterState.IDLE:
			_process_input_idle(event)
		CharacterState.MOVE:
			_process_input_move(event)
		CharacterState.JUMP:
			_process_input_jump(event)
		CharacterState.FALL:
			_process_input_fall(event)

func _on_sprite_animation_finished() -> void:
	match state:
		CharacterState.IDLE:
			sprite.play("idle")
		CharacterState.MOVE:
			sprite.play("walk")
		CharacterState.JUMP:
			sprite.play("rise")
		CharacterState.FALL:
			sprite.play("fall")

func _enter_idle() -> void:
	state = CharacterState.IDLE
	velocity = Vector2.ZERO
	if not sprite.animation == "land":
		sprite.play("idle")

func _exit_idle() -> void:
	pass

func _process_input_idle(event: InputEvent) -> void:
	if event.is_action_pressed('jump'):
		_exit_idle()
		_enter_jump()
		_jump()

func _process_physics_idle(delta: float) -> void:
	_process_physics_default(delta)
	if _is_moving_sideways():
		_exit_idle()
		_enter_move()

func _enter_move() -> void:
	state = CharacterState.MOVE
	if not sprite.animation == "land":
		sprite.play("walk-start")
	_show_particles()

func _exit_move() -> void:
	_hide_particles()
	pass

func _process_input_move(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		_exit_move()
		_enter_jump()
		_jump()

func _process_physics_move(delta: float) -> void:
	_process_physics_default(delta)
	if not is_on_floor():
		coyote_timer.start(coyote_time)
		_exit_move()
		_enter_fall()
	elif not _is_moving_sideways():
		_exit_move()
		_enter_idle()

func _enter_jump() -> void:
	state = CharacterState.JUMP

func _exit_jump() -> void:
	pass

func _process_input_jump(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_buffer_timer.start(jump_buffer)
	elif event.is_action_released('jump'):
		jump_buffer_timer.stop()
		_jump_cancel()

func _process_physics_jump(delta: float) -> void:
	_process_physics_default(delta)
	if _is_falling():
		_exit_jump()
		_enter_fall()
	elif is_on_floor():
		_exit_jump()
		_enter_idle()
	elif is_on_wall():
		_exit_fall()
		_enter_wall_slide()

func _enter_fall() -> void:
	state = CharacterState.FALL
	sprite.play("fall")

func _exit_fall() -> void:
	sprite.play("land")
	pass

func _process_input_fall(event: InputEvent) -> void:
	if event.is_action_pressed('jump'):
		if not coyote_timer.is_stopped():
			_exit_fall()
			_enter_jump()
			_jump()
		jump_buffer_timer.start(jump_buffer)
	elif event.is_action_released("jump"):
		jump_buffer_timer.stop()

func _process_physics_fall(delta: float) -> void:
	_process_physics_default(delta, _get_gravity() * fall_gravity_multiplier)
	if is_on_floor():
		if not jump_buffer_timer.is_stopped():
			_exit_fall()
			_enter_jump()
			_jump()
		elif _is_moving_sideways():
			_exit_fall()
			_enter_move()
		else:
			_exit_fall()
			_enter_idle()

func _process_physics_default(delta: float, gravity: Vector2 = _get_gravity()) -> void:
	if not is_on_floor():
		velocity += gravity * delta
		velocity = velocity.clampf(-terminal_velocity, terminal_velocity)

	var input_sideways := _get_sideways_movement_input()
	var breaking := signf(input_sideways) + signf(velocity.x) == 0
	if not input_sideways:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
	elif breaking:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	else:
		velocity.x += acceleration * input_sideways * delta
		velocity.x = clampf(velocity.x, -move_velocity, move_velocity)

	move_and_slide()

func _get_sideways_movement_input() -> float:
	return Input.get_axis("left", "right")

func _is_moving_sideways() -> bool:
	return abs(velocity.x) > 0

func _is_rising() -> bool:
	return velocity.y < 0

func _is_falling() -> bool:
	return velocity.y > 0

func _is_facing_right() -> bool:
	return not sprite.flip_h

func _jump() -> void:
	velocity.y = -_get_gravity().y * jump_duration / 2.0
	coyote_timer.stop()
	jump_buffer_timer.stop()
	sprite.play("jump")

func _jump_cancel() -> void:
	velocity.y *= 0.2

func _get_gravity() -> Vector2:
	return -up_direction * (8.0 * jump_height * 0.9677 / pow(jump_duration, 2.0))

func _hide_particles() -> void:
	dirt_particles.hide()

func _show_particles() -> void:
	var lr_direction := _get_sideways_movement_input()

	# Set particle direction to behind the player
	if lr_direction > 0:
		dirt_particles.direction.x = -1.0
	elif lr_direction < 0:
		dirt_particles.direction.x = 1.0

	# Show or hide particles
	dirt_particles.show()
