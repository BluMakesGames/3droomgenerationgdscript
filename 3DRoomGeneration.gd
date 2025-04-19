extends Node3D

@export var room_size_in_meters = 48

@export var columns : int = 4
@export var rows : int = 4
@export var layers : int = 3

##0, 1 or 2 are the only safe numbers ATM. Anything higher can result in infinite loops
@export var layer_drop_cooldown : int = 2

##The amount of times the algorithm will attempt to place an extraction room on each layer. The success of the algorithm is highly dependent on the size of each layer. Extraction rooms must be on the main path
@export var extraction_placement_attempts = 10

##The amount of times the algorithm will attempt to place a bonus room on each layer. The success of the algorithm is highly dependent on the size of each layer. Bonus rooms must NOT be horizontally adjacent to any main path room, extraction point, start, or finish. 
@export var bonus_placement_attempts = 30

@export var bulk_rooms : Array[PackedScene]
@export var start_rooms : Array[PackedScene]
@export var hallway_rooms : Array[PackedScene]
@export var drop_rooms : Array[PackedScene]
@export var catch_rooms : Array[PackedScene]
@export var bonus_rooms : Array[PackedScene]
@export var extraction_rooms : Array[PackedScene]
@export var end_rooms : Array[PackedScene]

#Rooms with value of:
# 0 (bulk rooms) - filled with non-path room
# 1 (start rooms) - starting room
# 2 (hallway rooms) - room with exits on all 4 sides
# 3 (drop rooms)- room with exits on all 4 sides and bottom, if another 2 is above it also has a top exit
# 4 (catch rooms) - room with exits on all 4 sides and top
# 
# 7 (bonus rooms) - bonus room
# 8 (extraction rooms) - extraction points
# 9 (end rooms) - exit room
#Note: All rooms are gaurenteed to have these exits but may have more
var grid : Array[int] = []

var starting_room_index : int

var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var total_rooms = columns * rows * layers
	
	for i in range(0, total_rooms):
		grid.append(0)
	
	generate_path()
	add_special_rooms()
	print_grid()
	
	place_rooms()

func generate_path():
	starting_room_index = rng.randi_range(0, (columns * rows) - 1)
	
	#print(starting_room_index)
	grid[starting_room_index] = 1
	# 1 = North
	# 2 = East
	# 3 = South
	# 4 = West
	# 5 = Down a layer
	var direction : int = rng.randi_range(1, 4)
	var next_room_index : int = starting_room_index
	var current_layer : int = 0
	var room_value : int = 2
	var layer_drop_cooldown_current = layer_drop_cooldown
	
	var generating_path = true
	while(generating_path):
		var last_room_index = next_room_index
		if direction == 1:
			if next_room_index - rows < current_layer * (rows * columns):
				if next_room_index + (columns * rows) > (rows * columns * layers - 1):
					if layer_drop_cooldown_current < 1:
						room_value = 9
						generating_path = false
				else:
					room_value = 4
					next_room_index += (columns * rows)
			else:
				next_room_index -= rows
				room_value = 2
		elif direction == 2:
			if (next_room_index + 1) % rows == 0:
				if next_room_index + (columns * rows) > (rows * columns * layers - 1):
					if layer_drop_cooldown_current < 1:
						room_value = 9
						generating_path = false
				else:
					room_value = 4
					next_room_index += (columns * rows)
			else:
				next_room_index += 1
				room_value = 2
		elif direction == 3:
			if next_room_index + rows > (current_layer + 1) * (rows * columns) - 1:
				if next_room_index + (columns * rows) > (rows * columns * layers - 1):
					if layer_drop_cooldown_current < 1:
						room_value = 9
						generating_path = false
				else:
					room_value = 4
					next_room_index += (columns * rows)
			else:
				next_room_index += rows
				room_value = 2
		elif direction == 4:
			if (next_room_index) % rows == 0:
				if next_room_index + (columns * rows) > (rows * columns * layers - 1):
					if layer_drop_cooldown_current < 1:
						room_value = 9
						generating_path = false
				else:
					room_value = 4
					next_room_index += (columns * rows)
			else:
				next_room_index -= 1
				room_value = 2
		
		
		if (room_value == 4 or room_value == 9) and layer_drop_cooldown_current > 0:
			next_room_index = last_room_index
		else:
			if grid[next_room_index] == 0:
				grid[next_room_index] = room_value
				layer_drop_cooldown_current -= 1
				if room_value == 4:
					current_layer += 1
					grid[last_room_index] = 3
					layer_drop_cooldown_current = layer_drop_cooldown
			else:
				next_room_index = last_room_index
		
		direction = rng.randi_range(1, 4)
	#print(current_layer)
	grid[next_room_index] = 9

func add_special_rooms():
	#Add extraction points, 1 per layer
	var current_layer : int = 0
	var attempts = 0
	var adding_extraction_points = true
	
	while (adding_extraction_points):
		var rand = rng.randi_range(0 + (current_layer * (rows * columns)), 15 + (current_layer * (rows * columns)))
		if grid[rand] == 0 and check_if_room_is_next_to_path(rand, current_layer):
			grid[rand] = 8
			current_layer += 1
			attempts = 0
		
		attempts += 1
		if attempts > extraction_placement_attempts:
			current_layer += 1
			attempts = 0
		
		if current_layer > layers - 1:
			adding_extraction_points = false
	
	current_layer = 0
	attempts = 0
	var adding_bonus_rooms = true
	
	while (adding_bonus_rooms):
		var rand = rng.randi_range(0 + (current_layer * (rows * columns)), 15 + (current_layer * (rows * columns)))
		if grid[rand] == 0 and not check_if_room_is_next_to_anything(rand, current_layer):
			grid[rand] = 7
			current_layer += 1
			attempts = 0
		
		attempts += 1
		if attempts > bonus_placement_attempts:
			current_layer += 1
			attempts = 0
		
		if current_layer > layers - 1:
			adding_bonus_rooms = false

func check_if_room_is_next_to_path(room : int, current_layer : int):
	if not room - rows < current_layer * (rows * columns):
		if grid[room - rows] == 2 or grid[room - rows] == 3 or grid[room - rows] == 4:
			return true
	if not (room + 1) % rows == 0:
		if grid[room + 1] == 2 or grid[room + 1] == 3 or grid[room + 1] == 4:
			return true
	if not room + rows > (current_layer + 1) * (rows * columns) - 1:
		if grid[room + rows] == 2 or grid[room + rows] == 3 or grid[room + rows] == 4:
			return true
	if not (room) % rows == 0:
		if grid[room - 1] == 2 or grid[room - 1] == 3 or grid[room - 1] == 4:
			return true
	
	return false

func check_if_room_is_next_to_anything(room : int, current_layer : int):
	if not room - rows < current_layer * (rows * columns):
		if grid[room - rows] != 0:
			return true
	if not (room + 1) % rows == 0:
		if grid[room + 1] != 0:
			return true
	if not room + rows > (current_layer + 1) * (rows * columns) - 1:
		if grid[room + rows] != 0:
			return true
	if not (room) % rows == 0:
		if grid[room - 1] != 0:
			return true
	
	return false

func print_grid():
	#for i in grid:
		#print(i)
	for l in range(0, layers):
		print("Layer " + str(l))
		for c in range(0, columns):
			var row : String = ""
			for r in range(0, rows):
				row += str(grid[(l * (columns * rows)) + (c * rows) + r]) + ",  "
			print(row)

func place_rooms():
	var index = 0
	var current_column = 0
	var current_row = 0
	var current_layer = 0
	for r in grid:
		var rand = rng.randi_range(0,3)
		var rand_rotation = 0
		if rand == 1:
			rand_rotation = 90
		elif rand == 2:
			rand_rotation = 180
		elif rand == 3:
			rand_rotation = 270
		
		if r == 0:
			var room = bulk_rooms[rng.randi_range(0, bulk_rooms.size() - 1)].instantiate()
			add_child(room)
			room.position.x += current_row * room_size_in_meters
			room.position.z += current_column * room_size_in_meters
			room.position.y -= current_layer * room_size_in_meters
			room.rotation_degrees.y = rand_rotation
		if r == 1:
			var room = start_rooms[rng.randi_range(0, start_rooms.size() - 1)].instantiate()
			add_child(room)
			room.position.x += current_row * room_size_in_meters
			room.position.z += current_column * room_size_in_meters
			room.position.y -= current_layer * room_size_in_meters
			room.rotation_degrees.y = rand_rotation
			get_parent().starting_pos = room.position
		if r == 2:
			var room = hallway_rooms[rng.randi_range(0, hallway_rooms.size() - 1)].instantiate()
			add_child(room)
			room.position.x += current_row * room_size_in_meters
			room.position.z += current_column * room_size_in_meters
			room.position.y -= current_layer * room_size_in_meters
			room.rotation_degrees.y = rand_rotation
		if r == 3:
			var room = drop_rooms[0].instantiate()
			add_child(room)
			room.position.x += current_row * room_size_in_meters
			room.position.z += current_column * room_size_in_meters
			room.position.y -= current_layer * room_size_in_meters
		if r == 4:
			var room = catch_rooms[0].instantiate()
			add_child(room)
			room.position.x += current_row * room_size_in_meters
			room.position.z += current_column * room_size_in_meters
			room.position.y -= current_layer * room_size_in_meters
		if r == 7:
			var room = bonus_rooms[0].instantiate()
			add_child(room)
			room.position.x += current_row * room_size_in_meters
			room.position.z += current_column * room_size_in_meters
			room.position.y -= current_layer * room_size_in_meters
		if r == 8:
			var room = extraction_rooms[0].instantiate()
			add_child(room)
			room.position.x += current_row * room_size_in_meters
			room.position.z += current_column * room_size_in_meters
			room.position.y -= current_layer * room_size_in_meters
		if r == 9:
			var room = end_rooms[0].instantiate()
			add_child(room)
			room.position.x += current_row * room_size_in_meters
			room.position.z += current_column * room_size_in_meters
			room.position.y -= current_layer * room_size_in_meters
		
		index += 1
		current_column += 1
		if current_column > columns - 1:
			current_column = 0
			current_row += 1
		if current_row > rows - 1:
			current_row = 0
			current_layer += 1
