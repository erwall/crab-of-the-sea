class_name PlayableCharacter2D
extends CharacterBody2D


const MAX_VELOCITY_WALK = 500.0
const TERMINAL_VELOCITY = 2000.0
const JUMP_VELOCITY = 700.0
const ACCELERATION = 2000.0
const DECELERATION = 5000.0
const FALL_GRAVITY_MULTIPLIER = 3.5


@onready var sprite: AnimatedSprite2D = $Sprite

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * (FALL_GRAVITY_MULTIPLIER if (velocity.y > 0) else 1.0) * delta
		velocity = velocity.clampf(-TERMINAL_VELOCITY, TERMINAL_VELOCITY)

	var jumped := Input.is_action_just_pressed("jump") and is_on_floor()
	var jump_cancelled := Input.is_action_just_released("jump") and velocity.y < 0
	if jumped:
		velocity.y = -JUMP_VELOCITY
	elif jump_cancelled:
		velocity.y *= 0.5

	var input_horizontal := Input.get_axis("left", "right")
	var breaking := signf(input_horizontal) + signf(velocity.x) == 0
	if not input_horizontal:
		velocity.x = move_toward(velocity.x, 0, ACCELERATION * delta)
	elif breaking:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
	else:
		velocity.x += ACCELERATION * input_horizontal * delta
		velocity.x = clampf(velocity.x, -MAX_VELOCITY_WALK, MAX_VELOCITY_WALK)

	if input_horizontal:
		sprite.animation = "walk"
	else:
		sprite.animation = "idle"

	if input_horizontal:
		sprite.flip_h = input_horizontal < 0
	sprite.play()

	move_and_slide()
