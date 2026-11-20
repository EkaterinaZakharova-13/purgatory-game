extends Node2D

@onready var player = get_tree().get_first_node_in_group("Player") 
@onready var current_layer = player.current_mask
@onready var layer_size = get_children().size()
@export_range(0, 1, 0.01) var ambient_color := 0.0

func _ready():
	var i = 1 # Increments
	
	for layer in get_children():
		layer.z_index = i
		layer.z_as_relative = 0
		
		for node in layer.get_children():
			var distance = abs(abs(i)-abs(player.current_mask))
			
			node.modulate = Color.from_hsv(ambient_color, (float(distance)/10.0), 1.0-(float(distance)/10.0), 1.0)
			
			if node is CollisionObject2D:
				node.collision_layer = 0
				node.set_collision_layer_value(i, 1)
			else:
				pass
		i += 1

var color_transitioning := false

func _process(delta):
	if not player:
		return

	if current_layer != player.current_mask:
		current_layer = player.current_mask
		color_transitioning = true

	if color_transitioning:
		var finished := true
		var i = 1 # Increments

		for layer in get_children():
			for node in layer.get_children():
				var distance = abs(i - player.current_mask)

				var target_color = Color.from_hsv(ambient_color, float(distance) / 10.0, 1.0 - (float(distance) / 10.0), 1.0)

				var weight = 1.0 - exp(-10.0 * delta)

				node.modulate = node.modulate.lerp(target_color, weight)

				if node.modulate != target_color:
					finished = false
				else:
					node.modulate = target_color

			i += 1

		if finished:
			color_transitioning = false
