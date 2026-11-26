extends Area2D

signal pressed
signal released

@onready var plate_top: Polygon2D = $PlateTop

var _occupying_crates: Array[Node2D] = []
var _is_pressed := false
var _press_tween: Tween

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("OrbCrates"):
		return
	if not _occupying_crates.has(body):
		_occupying_crates.append(body)
	_update_pressed_state()

func _on_body_exited(body: Node2D) -> void:
	_occupying_crates.erase(body)
	_update_pressed_state()

func _update_pressed_state() -> void:
	for index in range(_occupying_crates.size() - 1, -1, -1):
		var crate := _occupying_crates[index]
		if not is_instance_valid(crate) or not crate.is_inside_tree():
			_occupying_crates.remove_at(index)
	var should_be_pressed := not _occupying_crates.is_empty()
	if should_be_pressed == _is_pressed:
		return
	_is_pressed = should_be_pressed
	if _is_pressed:
		pressed.emit()
	else:
		released.emit()
	if _press_tween != null and _press_tween.is_running():
		_press_tween.kill()
	_press_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var target_position := Vector2(0.0, -2.0) if _is_pressed else Vector2(0.0, -5.0)
	_press_tween.tween_property(plate_top, "position", target_position, 0.12)