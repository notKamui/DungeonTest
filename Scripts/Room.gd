extends RigidBody2D

var size: Vector2

func make_room(pos: Vector2, siz: Vector2) -> void:
	position = pos
	size = siz
	
	var s = RectangleShape2D.new()
	s.custom_solver_bias = 1
	s.extents = size
	$CollisionShape2D.shape = s
