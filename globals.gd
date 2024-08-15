extends Node

# World Constants
const RAND_SEED = 42 # 42 for fast-loading debug level
const WIDTH = 512
const HEIGHT = 512
const CLAMP = 120
const GRAVITY = 490

# Player Stat Constants
const PLAYER_COLOR: Color = Color.LIGHT_CORAL
const MOVE_SPEED: float = 500.0
const SPEED_CAP: int = 800
const INERTIA: float = 2
const JUMP_VELOCITY: float = -400
const DBL_JUMP_VELOCITY: float = -300
const SLIDE: float = 10
const ACCEL: float = 5
const DOUBLE_JUMPS: int = 3
const SHOT_COLOR: Color = Color.BLUE_VIOLET
const SHOT_SPREAD: int = 10
const SHOT_VELOCITY: int = 600
const SHOT_WEIGHT: float = 0.5
const SHOT_LIFE: float = 7
const SHOT_GCD: float = 0.75
const MELEE_COLOR: Color = Color.HOT_PINK
const MELEE_VELOCITY: int = 900
const MELEE_WEIGHT: float = 0.5
const MELEE_LIFE: float = 0.15
const MELEE_GCD: float = 1

# Player Stat Variables
var player_color: Color
var move_speed : float
var speed_cap: int
var inertia: float
var jump_velocity: float
var dbl_jump_velocity: float
var slide: float
var accel: float
var double_jumps: int
var shot_color: Color
var shot_spread: int
var shot_velocity: int
var shot_weight: float
var shot_life: float
var shot_gcd: float
var melee_color: Color
var melee_velocity: int
var melee_weight: float
var melee_life: float
var melee_gcd: float

func init_player():
	player_color = PLAYER_COLOR
	move_speed = MOVE_SPEED
	speed_cap = SPEED_CAP
	inertia = INERTIA
	jump_velocity = JUMP_VELOCITY
	dbl_jump_velocity = DBL_JUMP_VELOCITY
	slide = SLIDE
	accel = ACCEL
	double_jumps = DOUBLE_JUMPS
	shot_color = SHOT_COLOR
	shot_spread = SHOT_SPREAD
	shot_velocity = SHOT_VELOCITY
	shot_weight = SHOT_WEIGHT
	shot_life = SHOT_LIFE
	shot_gcd = SHOT_GCD
	melee_color = MELEE_COLOR
	melee_velocity = MELEE_VELOCITY
	melee_weight = MELEE_WEIGHT
	melee_life = MELEE_LIFE
	melee_gcd = MELEE_GCD	
	
# For using vector4 colors in shaders
func color_to_vector(inColor: Color) -> Vector4:
	var returnVec: Vector4
	returnVec.x = inColor.r
	returnVec.y = inColor.g
	returnVec.z = inColor.b
	returnVec.w = inColor.a
	return returnVec	
	
func I82F(intNum : int) -> float:
	return intNum / 255.0
	
func tileMapToImage(tilemap: TileMap) -> ViewportTexture:
	var viewport = SubViewport.new()
	viewport.size = Vector2i(Globals.WIDTH * 16, Globals.HEIGHT * 16)
	var holder = Node2D.new()
	holder.position = tilemap.position
	viewport.add_child(tilemap)		
	return viewport.get_texture()	
	
func SafeIndex(index : Vector2i) -> Vector2i:
	var x = index.x % Globals.WIDTH
	var y = index.y % Globals.HEIGHT
	return Vector2i(x,y)
	
func invertMonoColor(value: int) -> Color:
	value = 255 - value
	return Color8(value, value, value)
	
func flood_fill(matrix, start_pos: Vector2i, target_value, replacement_value):
	# Check if the target value is the same as the replacement value
	if target_value == replacement_value:
		return

	# Check if start position is within the bounds of the matrix
	if start_pos.x < 0 or start_pos.x >= matrix.size() or start_pos.y < 0 or start_pos.y >= matrix[0].size():
		return

	# Create a stack for positions to visit
	var stack = [start_pos]

	while stack.size() > 0:
		var pos = stack.pop_back()
				
		# Make index positions safe
		var adj_index: Vector2i = Globals.SafeIndex(Vector2i(pos.x, pos.y))
		
		# Get the current value at the position
		var current_value = matrix[adj_index.x][adj_index.y]

		# If the current value is not the target value, continue
		if current_value != target_value:
			continue

		# Replace the value at the current position		
		matrix[adj_index.x][adj_index.y] = replacement_value

		# Push neighboring positions to the stack
		stack.append(Vector2i(pos.x + 1, pos.y))
		stack.append(Vector2i(pos.x - 1, pos.y))
		stack.append(Vector2i(pos.x, pos.y + 1))
		stack.append(Vector2i(pos.x, pos.y - 1))
		
func pickPlayerSpawn(matrix) -> Vector2i:
	var found: bool = false
	var spawnDist = 40
	var curX: int
	var curY: int
	
	while !found:
		curX = randi_range(0,Globals.WIDTH)
		curY = randi_range(0,Globals.HEIGHT)
		found = raycastCardinal(matrix, curX, curY, spawnDist)		
	
	return Vector2i(curX, curY)	
	
func raycastCardinal(matrix, x: int, y: int, minDist: int) -> bool:
	return raycastUp(matrix, x, y, minDist) && raycastDown(matrix, x, y, minDist) && raycastLeft(matrix, x, y, minDist) && raycastRight(matrix, x, y, minDist)
		
func raycastUp(matrix, x: int, y: int, minDist: int) -> bool:
	for yi in range(y-1, y-minDist, -1):
		var xs = Globals.SafeIndex(Vector2i(x,yi)).x
		var yis = Globals.SafeIndex(Vector2i(x,yi)).y
		if (matrix[xs][yis] == 1):
			return false
	return true	
	
func raycastDown(matrix, x: int, y: int, minDist: int) -> bool:
	for yi in range(y+1, y+minDist, 1):
		var xs = Globals.SafeIndex(Vector2i(x,yi)).x
		var yis = Globals.SafeIndex(Vector2i(x,yi)).y
		if (matrix[xs][yis] == 1):
			return false
	return true	
	
func raycastLeft(matrix, x: int, y: int, minDist: int) -> bool:
	for xi in range(x-1, x-minDist, -1):
		var xis = Globals.SafeIndex(Vector2i(xi,y)).x
		var ys = Globals.SafeIndex(Vector2i(xi,y)).y
		if (matrix[xis][ys] == 1):
			return false
	return true	
	
func raycastRight(matrix, x: int, y: int, minDist: int) -> bool:
	for xi in range(x+1, x+minDist, 1):
		var xis = Globals.SafeIndex(Vector2i(xi,y)).x
		var ys = Globals.SafeIndex(Vector2i(xi,y)).y
		if (matrix[xis][ys] == 1):
			return false
	return true	

# Called when the node enters the scene tree for the first time.
func _ready():	
	init_player()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
