extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var i = 3 # Decrements 
	var j = 1 # Increments
	for layer in self.get_children():
		layer.z_index = j #
		layer.z_as_relative = 0
		for node in layer.get_children():
			if node is CollisionObject2D:
				node.collision_layer = 0
				node.set_collision_layer_value(i, 1)
			else:
				pass
		i -= 1
		j += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
