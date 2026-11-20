extends CharacterBody2D
@onready var further_check: Area2D = $FurtherCheck
@onready var closer_check: Area2D = $CloserCheck
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var layer_manager := get_tree().get_first_node_in_group("LayerManager")

@export_group("Movement")
@export var max_speed: float = 240.0
@export var acceleration: float = 1800.0
@export_range(0.0, 1.0) var ground_friction: float = 0.45
@export var ground_braking: float = 3000.0
@export var stop_threshold: float = 5.0

@export_group("Jump")
@export var coyote_time: float = 0.125
@export var jump_buffer_time: float = 0.125
@export var jump_strength: float = 600.0
@export var gravity: float = 1800.0
@export var jump_cut_multiplier: float = 0.45

var last_grounded_time := -INF
var last_jump_pressed_time := -INF

var starting_mask: int = 2
var current_mask := starting_mask

var last_direction := 1

func _ready():
	_update_z_index()
	collision_mask = 0
	set_collision_mask_value(starting_mask, true)
	
	further_check.collision_mask = 0
	further_check.set_collision_mask_value(starting_mask-1, 1)
	closer_check.collision_mask = 0
	closer_check.set_collision_mask_value(starting_mask+1, 1)

func _physics_process(delta: float) -> void:
	print("Object behind player = " + str(has_overlapping_group_body("LayerCollider", further_check)))
	print("Object in front of player = " + str(has_overlapping_group_body("LayerCollider", closer_check)))
	
	if Input.is_action_just_pressed("further"):
		_move_further()

	if Input.is_action_just_pressed("closer"):
		_move_closer()
	
	var now := Time.get_ticks_msec() / 1000.0
	var on_floor := is_on_floor()

	if on_floor:
		last_grounded_time = now

	if Input.is_action_just_pressed("jump"):
		last_jump_pressed_time = now

	var direction := Input.get_axis("left", "right")
	
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

		last_direction = signi(int(direction))

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
		
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	move_and_slide()

func _play_animation(animation_name: StringName) -> void:
	if animated_sprite.animation != animation_name:
		animated_sprite.play(animation_name)

func _update_z_index() -> void:
	z_index = current_mask + 1

func _move_further() -> void:
	if current_mask > 1 and !has_overlapping_group_body("LayerCollider", further_check):
		collision_mask = 0
		global_position.y -= 32
		set_collision_mask_value(current_mask-1, true)
		current_mask -= 1
		further_check.collision_mask = 0
		further_check.set_collision_mask_value(current_mask-1, 1)
		closer_check.collision_mask = 0
		closer_check.set_collision_mask_value(current_mask+1, 1)
		_update_z_index()
		
func _move_closer() -> void:
	if current_mask < layer_manager.layer_size and !has_overlapping_group_body("LayerCollider", closer_check):
		collision_mask = 0
		global_position.y += 32
		set_collision_mask_value(current_mask+1, true)
		current_mask += 1
		further_check.collision_mask = 0
		further_check.set_collision_mask_value(current_mask-1, 1)
		closer_check.collision_mask = 0
		closer_check.set_collision_mask_value(current_mask+1, 1)
		_update_z_index()
		
func has_overlapping_group_body(group_name: String, check: Area2D) -> bool:
	for body in check.get_overlapping_bodies():
		if body.is_in_group(group_name):
			return true
	return false
