extends CharacterBody2D

@export var speed : float = 700.0
@export var jump_velocity : float = -200.0
@export var double_jump_velocity : float = -100.0
@export var slide : float = 10
@export var accel : float = 5
@export var double_jumps : int = 3

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var cur_double_jumps : int = 0
var animation_locked : bool = false
var direction : Vector2 = Vector2.ZERO
var was_in_air : bool = false
var camera

func _ready():
	camera = get_node("/root/PlayField/MainCamera")

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		was_in_air = true
	else:		
		if was_in_air == true:
			land()
		was_in_air = false
		
	# Respawn
	if Input.is_action_pressed("respawn"):
		var playFieldNode = get_node("/root/PlayField/PlayFieldMap")
		playFieldNode.respawn()

	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():			
			jump()
		elif cur_double_jumps < double_jumps:
			double_jump()
			
	if Input.is_action_just_released("jump"):
		if not is_on_floor():
			unjump()			

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_vector("left", "right", "up", "down")	
	# Temporary undo vector normalization for now.
	if direction.x < 0:
		direction.x = -1
	elif direction.x > 0:
		direction.x = 1
		
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * speed, accel)
	else:
		velocity.x = move_toward(velocity.x, 0, slide)
	
	camera.drag_horizontal_offset = velocity.x * 0.001 # Update horizontal lookahead
	#camera.drag_vertical_offset = velocity.y * 0.001 # Update vertical lookahead
	
	move_and_slide()
	update_animation()
	update_facing_direction()	
	
func jump():
	velocity.y = jump_velocity
	animated_sprite.play("jump_start")
	animation_locked = true
	
func unjump():
	velocity.y = jump_velocity / 10
	
func land():
	animated_sprite.play("jump_end")
	animation_locked = true
	cur_double_jumps = 0
	
func double_jump():
	velocity.y = double_jump_velocity
	animated_sprite.play("jump_double")
	animation_locked = true
	cur_double_jumps += 1

func update_facing_direction():
	if direction.x > 0:
		animated_sprite.flip_h = false
	elif direction.x < 0:
		animated_sprite.flip_h = true
	
func update_animation():
	if not animation_locked:
		if not is_on_floor():
			animated_sprite.play("jump_loop")
		else:
			if direction.x != 0:
				animated_sprite.play("run")
			else:
				animated_sprite.play("idle")

func _on_animated_sprite_2d_animation_finished():
	if (["jump_end", "jump_start", "jump_double"].has(animated_sprite.animation)):
		animation_locked = false
