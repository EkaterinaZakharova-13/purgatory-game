extends CharacterBody2D

@export_group("Movement")
@export var max_speed: float = 240.0
@export var acceleration: float = 1800.0
@export_range(0.0, 1.0) var ground_friction: float = 0.45
@export var ground_braking: float = 3000.0
@export var stop_threshold: float = 5.0

@export_group("Jump")
@export var coyote_time: float = 0.125 # seconds
@export var jump_buffer_time: float = 0.125 # seconds
@export var jump_strength: float = 400.0
@export var gravity: float = 1800.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_grounded_time := -INF
var last_jump_pressed_time := -INF

var last_direction := 1 # -1 = left, 1 = right

@export_group("Layer")
@export var starting_layer: int = 2
var current_layer := starting_layer
@export var starting_zindex := 2
var current_zindex := starting_zindex

func _ready():
	z_index = starting_zindex
	collision_mask = 0
	set_collision_mask_value(starting_layer, true)

func _physics_process(delta: float) -> void:
	
	var now := Time.get_ticks_msec() / 1000.0
	var on_floor := is_on_floor()

	if on_floor:
		last_grounded_time = now

	if Input.is_action_just_pressed("jump"):
		last_jump_pressed_time = now

	var direction := Input.get_axis("left", "right")
	
	if current_layer == 1:
		get_node("Sprite2D").modulate = Color.from_hsv(0.0, 0.0, 1.0, 1.0)
	elif current_layer == 2:
		get_node("Sprite2D").modulate = Color.from_hsv(0.0, 0.0, 0.75, 1.0)
	elif current_layer == 3:
		get_node("Sprite2D").modulate = Color.from_hsv(0.0, 0.0, 0.5, 1.0)
	
	if Input.is_action_just_pressed("further"):
		if current_layer < 3:
			set_collision_mask_value(current_layer, false)
			set_collision_mask_value(current_layer+1, true)
			current_layer += 1
			current_zindex -= 1
			z_index = current_zindex

	if Input.is_action_just_pressed("closer"):
		if current_layer > 1:
			set_collision_mask_value(current_layer, false)
			set_collision_mask_value(current_layer-1, true)
			current_layer -= 1
			current_zindex += 1
			z_index = current_zindex
	
	if not on_floor:
		var current_gravity := gravity
		velocity.y += current_gravity * delta

	if direction != 0.0:
		var reversing_on_ground := (
			on_floor
			and velocity.x != 0.0
			and signf(velocity.x) != signf(direction)
		)

		if reversing_on_ground:
			velocity.x = move_toward(
				velocity.x,
				0.0,
				ground_braking * delta
			)
		else:
			velocity.x = move_toward(
				velocity.x,
				direction * max_speed,
				acceleration * delta
			)

		last_direction = signi(direction)

		if on_floor:
			_play_animation("walk")
	elif on_floor:
		velocity.x *= ground_friction
		if absf(velocity.x) < stop_threshold:
			velocity.x = 0.0
			_play_animation("idle")

	animated_sprite.flip_h = last_direction < 0

	var jump_is_buffered := now - last_jump_pressed_time <= jump_buffer_time
	var can_coyote_jump := now - last_grounded_time <= coyote_time

	if jump_is_buffered and can_coyote_jump:
		velocity.y = -jump_strength
		last_grounded_time = -INF
		last_jump_pressed_time = -INF
		_play_animation("jump")

	move_and_slide()

func _play_animation(animation_name: StringName) -> void:
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)
