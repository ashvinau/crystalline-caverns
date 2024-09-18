extends Area2D

func hit(from_node, magnitude: float):
	get_parent().get_parent().apply_impulse(from_node.velocity * (magnitude/100))
	get_parent().get_parent().apply_torque_impulse(randf_range(-1000,1000))
