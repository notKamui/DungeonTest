extends KinematicBody2D

export var id: int = 0
export var speed: int = 250

var velocity: Vector2 = Vector2()

func _input(event) -> void:
	if event.is_action_pressed("scroll_up"):
		$Camera2D.zoom = $Camera2D.zoom - Vector2(0.1, 0.1)
	if event.is_action_pressed("scroll_down"):
		$Camera2D.zoom = $Camera2D.zoom + Vector2(0.1, 0.1)


func _physics_process(_delta) -> void:
	get_input()
	velocity = move_and_slide(velocity)


func get_input() -> void:
	velocity = Vector2()
	if Input.is_action_pressed('ui_right'):
		velocity.x += 1
	if Input.is_action_pressed('ui_left'):
		velocity.x -= 1
	if Input.is_action_pressed('ui_up'):
		velocity.y -= 1
	if Input.is_action_pressed('ui_down'):
		velocity.y += 1
	velocity = velocity.normalized() * speed
