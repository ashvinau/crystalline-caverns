extends Node

# Game Constants
const DAMAGE_COLOR: Color = Color(1,0.1,0.1,0.8)

# World Constants
const RAND_SEED: int = 42 # 42 for fast-loading debug level
const WIDTH: int = 512
const HEIGHT: int = 512
const CLAMP: int = 120
const GRAVITY: int = 490

# Stat Reference Values
const PLAYER_MAX_HEALTH = 1000
const PLAYER_HEALTH = 1000
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
const SHOT_VELOCITY: int = 575
const SHOT_WEIGHT: float = 0.5
const SHOT_LIFE: float = 7
const SHOT_GCD: float = 0.75
const MELEE_COLOR: Color = Color.HOT_PINK
const MELEE_VELOCITY: int = 900
const MELEE_WEIGHT: float = 0.5
const MELEE_LIFE: float = 0.15
const MELEE_GCD: float = 1

# Player Stat Variables
var STR: float = 5
var CON: float = 5
var DEX: float = 5
var INT: float = 5
var WIS: float = 5

# Derived Stat Variables
var player_max_health: int
var player_health: int
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
	print("Init Player...")
	player_color = PLAYER_COLOR
	melee_color = player_color
	shot_color = player_color
	
	player_max_health = 60 * log(pow(CON,10) + 3.5) # y=60 ln(x^10+3.5)
	player_health = player_max_health
	print("Max/Current Health: ", player_health)
	
	move_speed = 20 * log(pow(DEX,15.5) + 100) # y=20 ln(x^15.5+100)
	print("Move Speed: ", move_speed)
	
	speed_cap = 40 * log(pow(CON,15) + 100) # y=40 ln(x^15+100)
	print("Speed Cap: ", speed_cap)
	
	inertia = log(pow(STR+CON,0.65) + 3) # y=ln(x^0.65+3)
	print("Inertia: ", inertia)
	
	jump_velocity = -(15 * log(pow(STR+DEX,11.6) + 500)) # y=ln(x^11.6+500)
	print("Jump velocity: ", jump_velocity)
	
	dbl_jump_velocity = -(20 * log(pow(DEX,12.3) + 70)) # y=ln(x^12.3+70)
	print("Double jump velocity: ", dbl_jump_velocity)
	
	slide = log(6 * pow(DEX+WIS, 4) + 3) - 1 # y=ln(6x^4+3)-1
	print("Slide control: ", slide)
	
	accel = log(15 * pow(DEX+CON, 1.43) + 1) # y=ln (15x^1.43+1)
	print("Acceleration: ", accel)
	
	double_jumps = floor(log(67 * pow(DEX+INT, 1.23))-4) # ln(67x^1.23)-4
	print("Double jumps: ", double_jumps)
	
	shot_spread = -log(2.5 * pow(WIS,2.9)) + 16.5 # y=-ln(2.5x^2.9)+15.5
	if shot_spread < 0:
		shot_spread = 0
	print("Shot Spread: ", shot_spread)
	
	shot_velocity = 90 * log(pow(INT+WIS,3.2)) - 60 # y=90 ln(x^3.2)-60
	print("Shot velocity: ", shot_velocity)
		
	shot_weight = ((log(pow(INT + 2.4, 3) + 6.62)) / 12) # y=(ln((x+2.4)^3)+6.62)/12
	print("Shot weight: ", shot_weight)
	
	shot_life = log(pow(WIS,3)+1)+1 # ln(x^3+1)+1
	print("Shot life: ", shot_life)
	
	shot_gcd = -(log(pow(INT+DEX,5))-23)/10 # y=-(ln(x^5)-23)/10
	if shot_gcd < 0.1:
		shot_gcd = 0.1
	print("Shot gcd: ", shot_gcd)
	
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
	
func tilemap_to_image(tilemap: TileMap) -> ViewportTexture:
	var viewport = SubViewport.new()
	viewport.size = Vector2i(Globals.WIDTH * 16, Globals.HEIGHT * 16)
	var holder = Node2D.new()
	holder.position = tilemap.position
	viewport.add_child(tilemap)		
	return viewport.get_texture()	
	
func safe_index(index : Vector2i) -> Vector2i:
	var x = index.x % Globals.WIDTH
	var y = index.y % Globals.HEIGHT
	return Vector2i(x,y)
	
func fade(x: float) -> float:
	return x * x * x * (x * (x * 6 - 15) + 10) # y = 6x^5 - 15x^4 + 10x^3
	
func invert_mono_color(value: int) -> Color:
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
		var adj_index: Vector2i = Globals.safe_index(Vector2i(pos.x, pos.y))
		
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
		
func pick_spawn(matrix, dist: int) -> Vector2i:
	var found: bool = false	
	var curX: int
	var curY: int
	var tried: int = 0
	
	while !found:
		tried += 1
		curX = randi_range(0,Globals.WIDTH)
		curY = randi_range(0,Globals.HEIGHT)
		found = raycast_cardinal(matrix, curX, curY, dist)
	
	print("Spawn found in ", tried, " attempts.")
	return Vector2i(curX, curY)	
	
func raycast_cardinal(matrix, x: int, y: int, minDist: int) -> bool:
	return raycast(matrix,Vector2(0,-1),x,y,minDist) && raycast(matrix,Vector2(0,1),x,y,minDist) && raycast(matrix,Vector2(1,0),x,y,minDist) && raycast(matrix,Vector2(0,-1),x, y,minDist) && raycast(matrix,Vector2(1,-1),x,y,minDist) && raycast(matrix,Vector2(1,1),x,y,minDist) && raycast(matrix,Vector2(-1,1),x,y,minDist) && raycast(matrix,Vector2(-1,-1),x, y,minDist)
	
func raycast(matrix, direction: Vector2, x: float, y: float, minDist: int) -> bool:
	for cur_dist in range(0, minDist):
		var safeCoords: Vector2i = safe_index(Vector2i(x,y))
		if (matrix[safeCoords.x][safeCoords.y] == 1):
			return false
		x += direction.x
		y += direction.y
	return true
	
func toroidal_matrix_dist(width: int, height: int, p1: Vector2i, p2: Vector2i) -> float:
	if ((p1.x > width) || (p1.x < 0) || (p1.y > height) || (p1.y < 0) || (p2.x > width) || (p2.x < 0) || (p2.y > height) || (p2.y < 0)):
		return -1

	var x1: float = float(p1.x) / float(width)
	var y1: float = float(p1.y) / float(height)
	var x2: float = float(p2.x) / float(width)
	var y2: float = float(p2.y) / float(height)

	var large_dimension: int = max(width, height) 
	return toroidal_distance(x1,y1,x2,y2) * large_dimension

func toroidal_distance(x1: float, y1: float, x2: float, y2: float) -> float:
	var dx: float = abs(x2 - x1)
	var dy: float = abs(y2 - y1)
	
	if (dx > 0.5):
		dx = 1.0 - dx
	
	if (dy > 0.5):
		dy = 1.0 - dy
		
	return sqrt(dx*dx + dy*dy)	

# Called when the node enters the scene tree for the first time.
func _ready():	
	init_player()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
