extends Node

# Game Constants
const DAMAGE_COLOR: Color = Color(1,0.1,0.1,0.8)
const NAV_SPEED: float = 0.5

# World Constants
const RAND_SEED: int = 75303546 # 42 for fast-loading debug level
const WIDTH: int = 512
const HEIGHT: int = 512
const CLAMP: int = 120
const GRAVITY: int = 490

# Customization
const PLAYER_COLOR: Color = Color.FUCHSIA

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
	
	player_max_health = calc_health(CON) # Ref val 1000
	player_health = player_max_health
	print("Max/Current Health: ", player_health)
	
	move_speed = calc_move_speed(DEX) # Ref val 500
	print("Move Speed: ", move_speed)
	
	speed_cap = calc_speed_cap(CON) # Ref val 800
	print("Speed Cap: ", speed_cap)
	
	inertia = calc_inertia(STR, CON) # Ref val 2
	print("Inertia: ", inertia)
	
	jump_velocity = calc_jump_velocity(STR, DEX) # Ref val -400
	print("Jump velocity: ", jump_velocity)
	
	dbl_jump_velocity = calc_double_jump_vel(DEX) # Ref val -300
	print("Double jump velocity: ", dbl_jump_velocity)
	
	slide = calc_slide(DEX, WIS) # Ref val 10
	print("Slide control: ", slide)
	
	accel = calc_accel(DEX, CON) # Ref val 5
	print("Acceleration: ", accel)
	
	double_jumps = calc_double_jumps(DEX, INT) # Ref val 3
	print("Double jumps: ", double_jumps)
	
	shot_spread = calc_shot_spread(WIS) # Ref val 10
	print("Shot Spread: ", shot_spread)
	
	shot_velocity = calc_shot_vel(INT, WIS) # Ref val 600
	print("Shot velocity: ", shot_velocity)
		
	shot_weight = calc_shot_weight(INT) # Ref val 0.5
	print("Shot weight: ", shot_weight)
	
	shot_life = calc_shot_life(WIS) # Ref val 7
	print("Shot life: ", shot_life)
	
	shot_gcd = calc_shot_gcd(INT, DEX) # Ref val 0.75
	print("Shot gcd: ", shot_gcd)
	
	melee_velocity = calc_melee_velocity(STR, DEX) # Ref val 900
	print("Melee velocity: ", melee_velocity)	
	
	melee_weight = calc_melee_weight(STR) # Ref val 0.5
	print("Melee weight: ", melee_weight)
	
	melee_life = calc_melee_life(WIS) # Ref val 0.15
	print("Melee life: ", melee_life)
	
	melee_gcd = calc_melee_gcd(CON, DEX) # Ref val 1
	print("Melee gcd: ", melee_gcd)
	
func calc_health(con: float) -> float:
	return 60 * log(pow(con,10) + 3.5) # y=60 ln(x^10+3.5)
	
func calc_move_speed(dex: float) -> float:
	return 20 * log(pow(dex,15.5) + 100) # y=20 ln(x^15.5+100)
	
func calc_speed_cap(con: float) -> float:
	return 40 * log(pow(con,15) + 100) # y=40 ln(x^15+100)
	
func calc_inertia(str: float, con: float) -> float:
	return log(pow(str+con,0.65) + 3) # y=ln(x^0.65+3)
	
func calc_jump_velocity(str: float, dex: float) -> float:
	return -(15 * log(pow(str+dex,11.6) + 500)) # y=ln(x^11.6+500)
	
func calc_double_jump_vel(dex: float) -> float:
	return -(20 * log(pow(dex,12.3) + 70)) # y=ln(x^12.3+70)
	
func calc_slide(dex: float, wis: float) -> float:
	return log(6 * pow(dex+wis, 4) + 3) - 1 # y=ln(6x^4+3)-1
	
func calc_accel(dex: float, con: float) -> float:
	return log(15 * pow(dex+con, 1.43) + 1) # y=ln (15x^1.43+1)
	
func calc_double_jumps(dex: float, inte: float) -> float:
	return floor(log(67 * pow(dex+inte, 1.23))-4) # ln(67x^1.23)-4
	
func calc_shot_spread(wis: float) -> float:
	var retVal: float = -log(2.5 * pow(wis,2.9)) + 16.5 # y=-ln(2.5x^2.9)+15.5
	if retVal < 0:
		retVal = 0
	return retVal
	
func calc_shot_vel(inte: float, wis: float) -> float:
	return 90 * log(pow(inte+wis,3.2)) - 60 # y=90 ln(x^3.2)-60
	
func calc_shot_weight(inte: float) -> float:
	return ((log(pow(inte + 2.4, 3) + 6.62)) / 12) # y=(ln((x+2.4)^3)+6.62)/12
	
func calc_shot_life(wis: float) -> float:
	return log(pow(wis,3)+1)+1 # ln(x^3+1)+1
	
func calc_shot_gcd(inte: float, dex: float) -> float:
	var retVal: float = -(log(pow(inte+dex,5))-23)/10 # y=-(ln(x^5)-23)/10
	if retVal < 0.1:
		retVal = 0.1
	return retVal
	
func calc_melee_velocity(str: float, dex: float) -> float:
	return 50 * log(pow(str+dex,8)+40) # 50 ln(x^8+40)
	
func calc_melee_weight(str: float) -> float:
	return ((log(pow(str + 2.4, 3) + 6.62)) / 11) # y=(ln((x+2.4)^3)+6.62)/11
	
func calc_melee_life(wis: float) -> float:
	return (log(pow(wis,4)+3)) / 38 # y=(ln(x^4+3))/38
	
func calc_melee_gcd(con: float, dex: float) -> float:
	var retVal: float = -(log(pow(con+dex,5))-23)/9 # y=-(ln(x^5)-23)/10
	if retVal < 0.1:
		retVal = 0.1
	return retVal
	
func calc_detection_dist(wis: float) -> float:
	return 50 * log(pow(wis,11.5) + 80)
	
func calc_shot_dist(inte: float, wis: float) -> float:
	return 42 * log(pow(inte+wis+1,7) + 1)
	
func calc_melee_dist(str: float, dex: float) -> float:
	return 30 * log(pow(str+dex+1,5.6) + 1)
	
func calc_move_gcd(dex: float, wis: float) -> float:
	return -(log(pow(wis+dex,5))-23)/9 # y=-(ln(x^5)-23)/10
	
func calc_alert_gcd(inte: float, wis: float) -> float:
	return (4 * log(pow(inte+wis,3)+5)) / 6
	
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
	
func get_mat_val(matrix: Array, index: Vector2) -> int:
	index = safe_index(index)
	return matrix[index.x][index.y]
	
func set_mat_val(matrix: Array, index: Vector2, value: int) -> void:
	index = safe_index(index)
	matrix[index.x][index.y] = value	
		
func pick_spawn(matrix, dist: int) -> Vector2i:
	var found: bool = false	
	var curX: int
	var curY: int
	var tried: int = 0
	
	while !found:
		tried += 1
		curX = randi_range(0,Globals.WIDTH-1)
		curY = randi_range(0,Globals.HEIGHT-1)
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
	
func save_map_file(matrix: Array, name: String): # debug function	
	var file = FileAccess.open(str("user://",name), FileAccess.WRITE)
	for y in Globals.HEIGHT:
		var curline: String = ""
		for x in Globals.WIDTH:
			curline = str(curline, ", ", str(matrix[x][y]).pad_zeros(6))
		curline = str(curline, "\n")
		file.store_string(curline)
	print("Map file saved: ", name)		

# Called when the node enters the scene tree for the first time.
func _ready():	
	init_player()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
