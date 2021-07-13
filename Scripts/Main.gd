extends Node2D

var Room = preload("res://Scenes/Room.tscn")
var Player = preload("res://Scenes/Character.tscn")
onready var Map: TileMap = $TileMap

const TILE_SIZE: int = 32
const GROUND: int = 0
const WALL: int = 1

export var num_rooms: int = 30
export var room_min_size: int = 4
export var room_max_size: int = 10
export var hspread: float = 0
export var cull: float = .5

var path: AStar2D
var play_mode: bool = false
var player = null


func _ready():
	randomize()
	make_rooms()


func _draw():
	if play_mode: return
	
	$Camera2D.zoom = Vector2(10, 10)
	for room in $Rooms.get_children():
		draw_rect(
			Rect2(room.position - room.size, room.size * 2), 
			Color.aqua,
			false
		)
		
	if path:
		var visited: Array = []
		for pid in path.get_points():
			for con in path.get_point_connections(pid):
				if con in visited: continue
				var pos1 = path.get_point_position(pid)
				var pos2 = path.get_point_position(con)
				draw_line(pos1, pos2, Color.yellow, 10)
			visited.append(pid)


func _process(_delta: float):
	update()


func _input(event: InputEvent):
	if event.is_action_pressed("ui_select"):
		if play_mode:
			player.queue_free()
			play_mode = false
		Map.clear()
		for e in $Rooms.get_children():
			e.queue_free()
		path = null
		make_rooms()
	
	if event.is_action_pressed("ui_focus_next"):
		make_map()
	
	if event.is_action_pressed("ui_cancel"):
		player = Player.instance()
		add_child(player)
		player.position = $Rooms.get_children().front().position
		play_mode = true


func make_rooms():
	for i in num_rooms:
		var pos: Vector2 = Vector2(rand_range(-hspread, hspread), 0)
		var curr_room: RigidBody2D = Room.instance()
		var width: int = room_min_size + randi() % (room_max_size - room_min_size)
		var height: int = room_min_size + randi() % (room_max_size - room_min_size)
		
		curr_room.make_room(pos, Vector2(width, height) * TILE_SIZE)
		$Rooms.add_child(curr_room)
		
	yield(get_tree().create_timer(.3), "timeout")
	
	# room culling
	var room_positions: Array = []
	for room in $Rooms.get_children():
		if randf() < cull:
			room.queue_free()
		else:
			room.mode = RigidBody2D.MODE_STATIC
			room_positions.append(room.position)
	
	yield(get_tree(), "idle_frame")
	
	# Prim/Dijkstra
	path = mst_prim(room_positions)


func mst_prim(nodes: Array):
	var new_path: AStar2D = AStar2D.new()
	
	new_path.add_point(new_path.get_available_point_id(), nodes.pop_front())
	
	while nodes:
		var min_dist: float = INF
		var min_pos = null
		var curr_pos = null
		
		for pid in new_path.get_points():
			var pos1: Vector2 = new_path.get_point_position(pid)
			for pos2 in nodes:
				var dist = pos1.distance_to(pos2)
				if dist < min_dist:
					min_dist = min(min_dist, dist)
					min_pos = pos2
					curr_pos = pos1
		
		var id = new_path.get_available_point_id()
		new_path.add_point(id, min_pos)
		new_path.connect_points(new_path.get_closest_point(curr_pos), id)
		nodes.erase(min_pos)
	
	return new_path


func make_map():
	Map.clear()
	
	# enclose map in walls
	var enclosure: Rect2 = Rect2()
	for room in $Rooms.get_children():
		var rect: Rect2 = Rect2(
			room.position - room.size, 
			room.get_node("CollisionShape2D").shape.extents * 2
		)
		enclosure = enclosure.merge(rect)
	var top_left = Map.world_to_map(enclosure.position)
	var bottom_right = Map.world_to_map(enclosure.end)
	
	for x in range(top_left.x, bottom_right.x):
		for y in range(top_left.y, bottom_right.y):
			Map.set_cell(x, y, WALL)
	
	# carve rooms and corridors
	var corridors: Array = []
	for room in $Rooms.get_children():
		var size: Vector2 = (room.size / TILE_SIZE).floor()
		var up_left: Vector2 = (room.position / TILE_SIZE).floor() - size
		
		# room
		for x in range(2, size.x * 2 - 1):
			for y in range(2, size.y * 2 - 1):
				Map.set_cell(int(up_left.x) + x, int(up_left.y) + y, GROUND)
		
		# corridor
		var next = path.get_closest_point(room.position)
		for con in path.get_point_connections(next):
			if con in corridors: continue
			var start = Map.world_to_map(path.get_point_position(next))
			var end = Map.world_to_map(path.get_point_position(con))
			
			carve_path(start, end)
		corridors.append(next)


func carve_path(start: Vector2, end: Vector2):
	var delta_x = sign(end.x - start.x)
	var delta_y = sign(end.y - start.y)
	if delta_x == 0: delta_x = pow(-1, randi() % 2)
	if delta_y == 0: delta_y = pow(-1, randi() % 2)
	
	# either x then y, or y then x
	var x_y = start
	var y_x = end
	if randf() < .5:
		x_y = end
		y_x = start
		
	for x in range(start.x, end.x, delta_x):
		Map.set_cell(x, x_y.y, GROUND)
	
	for y in range(start.y, end.y, delta_y):
		Map.set_cell(y_x.x, y, GROUND)
