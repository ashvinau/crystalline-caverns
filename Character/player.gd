extends CharacterBody2D

@export var speed : float = 500.0
@export var speed_cap: int = 600
@export var jump_velocity : float = -200.0
@export var double_jump_velocity : float = -100.0
@export var slide : float = 10
@export var accel : float = 5
@export var double_jumps : int = 3
@export var shot_velocity : int = 600
@export var shot_weight : float = 0.25

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var cur_double_jumps : int = 0
var animation_locked : bool = false
var orientation_locked : bool = false
var shot_lock : bool = false
var direction : Vector2 = Vector2.ZERO
var was_in_air : bool = false

@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var centerCam = get_node("../../CenterCamera")
@onready var leftCam = get_node("../../../../LeftViewportContainer/LeftViewport/LeftCamera")
@onready var rightCam = get_node("../../../../RightViewportContainer/RightViewport/RightCamera")
@onready var topCam = get_node("../../../../TopViewportContainer/TopViewport/TopCamera")
@onready var bottomCam = get_node("../../../../BottomViewportContainer/BottomViewport/BottomCamera")

@onready var play_field: Node2D = get_node("..") # parent node: PlayField

var basic_bullet = preload("res://basic_bullet.tscn")
var basic_melee = preload("res://basic_melee.tscn")

func _ready():
	pass

func _physics_process(delta):
	# Speed caps
	if (self.velocity.x > speed_cap):
		self.velocity.x = speed_cap
	elif (self.velocity.x < -speed_cap):
		self.velocity.x = -speed_cap
	if (self.velocity.y > speed_cap):
		self.velocity.y = speed_cap
	elif (self.velocity.y < -speed_cap):
		self.velocity.y = -speed_cap	
	
	# Update cameras
	centerCam.global_position = global_position
	leftCam.global_position.x = global_position.x - (Globals.WIDTH * 16)
	leftCam.global_position.y = global_position.y
	rightCam.global_position.x = global_position.x + (Globals.WIDTH * 16) 
	rightCam.global_position.y = global_position.y
	
	topCam.global_position.x = global_position.x
	topCam.global_position.y = global_position.y - (Globals.HEIGHT * 16)
	bottomCam.global_position.x = global_position.x
	bottomCam.global_position.y = global_position.y + (Globals.HEIGHT * 16)	
	
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
		var playFieldNode = get_node("../PlayFieldMap")
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
			
	if Input.is_action_pressed("down"):
		if is_on_floor():
			velocity.y += 200
			
	if Input.is_action_pressed("attack up") && Input.is_action_pressed("attack left"):
		range_attack(Vector2i(-20,-20), Vector2(-1,-1).normalized())	
		
	elif Input.is_action_pressed("attack up") && Input.is_action_pressed("attack right"):
		range_attack(Vector2i(20,-20),Vector2(1,-1).normalized())		
	
	elif Input.is_action_pressed("attack down") && Input.is_action_pressed("attack left"):
		range_attack(Vector2i(-20,20),Vector2(-1,1).normalized())	
		
	elif Input.is_action_pressed("attack down") && Input.is_action_pressed("attack right"):
		range_attack(Vector2i(20,20),Vector2(1,1).normalized())		
			
	elif Input.is_action_pressed("attack up"):
		range_attack(Vector2i(0,-20), Vector2(0,-1))	
		
	elif Input.is_action_pressed("attack down"):
		range_attack(Vector2i(0,20),Vector2(0,1))	
		
	elif Input.is_action_pressed("attack left"):
		range_attack(Vector2i(-20,0),Vector2(-1,0))	
		
	elif Input.is_action_pressed("attack right"):
		range_attack(Vector2i(20,0),Vector2(1,0))		
		
	if Input.is_action_just_released("attack up"):
		pass
	if Input.is_action_just_released("attack down"):
		pass	
	if Input.is_action_just_released("attack left"):			
		pass	
	if Input.is_action_just_released("attack right"):		
		pass
		
	# Get the input direction and handle the movement/deceleration.	
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
	
	#camera.drag_horizontal_offset = velocity.x * 0.001 # Update horizontal lookahead
	#camera.drag_vertical_offset = velocity.y * 0.001 # Update vertical lookahead
	
	move_and_slide()
	update_animation()
	if !orientation_locked:
		update_facing_direction()	
		
	checkPlayerLoc()
		
func range_attack(offset: Vector2i, direction: Vector2):
	if (direction.x > 0):
		animated_sprite.flip_h = false
		animated_sprite.play("atk_h")
	elif (direction.x < 0):
		animated_sprite.flip_h = true
		animated_sprite.play("atk_h")
	elif (direction.y > 0):
		animated_sprite.play("atk_down")
	elif (direction.y < 0):
		animated_sprite.play("atk_up")
		
	animation_locked = true
	orientation_locked = true
	
	if not shot_lock:
		var bullet_inst = basic_bullet.instantiate()	
		bullet_inst.position.x = self.position.x + offset.x
		bullet_inst.position.y = self.position.y + offset.y	
		play_field.add_child(bullet_inst)
		bullet_inst.velocity.x = direction.x * shot_velocity
		self.velocity.x += -direction.x * (shot_weight * shot_velocity)
		bullet_inst.velocity.y = direction.y * shot_velocity
		self.velocity.y += -direction.y * (shot_weight + shot_velocity)
		shot_lock = true

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
	if (["jump_end", "jump_start", "jump_double","atk_down","atk_up","atk_h"].has(animated_sprite.animation)):
		animation_locked = false
		orientation_locked = false
		shot_lock = false		

func _on_animated_sprite_2d_animation_changed():
	shot_lock = false
	
func checkPlayerLoc():
	$CollisionShape2D.set_deferred("disabled", false)
	var locX = self.position.x
	var locY = self.position.y	
	# Wrap around teleports
	if (locX > Globals.WIDTH * 16):
		$CollisionShape2D.set_deferred("disabled", true)
		self.position.x = 0
	elif (locX < 0):
		$CollisionShape2D.set_deferred("disabled", true)
		self.position.x = Globals.WIDTH * 16
	elif (locY > Globals.HEIGHT * 16):
		$CollisionShape2D.set_deferred("disabled", true)
		self.position.y = 0
	elif (locY < 0):
		$CollisionShape2D.set_deferred("disabled", true)
		self.position.y = Globals.HEIGHT * 16
