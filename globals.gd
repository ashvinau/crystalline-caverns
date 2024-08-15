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
const SHOT_GCD: float = 0.5
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
	
# Called when the node enters the scene tree for the first time.
func _ready():	
	init_player()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
