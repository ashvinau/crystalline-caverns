extends CharacterBody2D

const LOOKAHEAD_LIMIT: int = 300
const LOOKAHEAD_SPEED: float = 0.17 # proportion

var cur_double_jumps: int = 0
var animation_locked: bool = false
var orientation_locked: bool = false
var shot_lock: bool = false
var melee_lock: bool = false
var direction: Vector2 = Vector2.ZERO
var was_in_air: bool = false
var crouched: bool = false
var camera_offset_x: int = 0
var lookahead_adjust: float = 1
var attack_direction: Vector2 = Vector2.ZERO
var e_inertia: float = Globals.inertia

@onready var hud_node = get_node("../../../../HUD")
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var centerCam = get_node("../../CenterCamera")
@onready var leftCam = get_node("../../../../LeftViewportContainer/LeftViewport/LeftCamera")
@onready var rightCam = get_node("../../../../RightViewportContainer/RightViewport/RightCamera")
@onready var topCam = get_node("../../../../TopViewportContainer/TopViewport/TopCamera")
@onready var bottomCam = get_node("../../../../BottomViewportContainer/BottomViewport/BottomCamera")
@onready var ULCam = get_node("../../../../ULViewportContainer/ULViewport/ULCamera")
@onready var URCam = get_node("../../../../URViewportContainer/URViewport/URCamera")
@onready var LLCam = get_node("../../../../LLViewportContainer/LLViewport/LLCamera")
@onready var LRCam = get_node("../../../../LRViewportContainer/LRViewport/LRCamera")
@onready var play_field: Node2D = get_node("..") # parent node: PlayField

var spark_scene = preload("res://effects/sparks.tscn")
var basic_bullet = preload("res://attacks/basic_bullet.tscn")
var basic_melee = preload("res://attacks/basic_melee.tscn")

func set_player(color: Color):
	$AnimatedSprite2D.material.set_shader_parameter("modulate",Globals.color_to_vector(color))
	modulate = color
	$RangeCDTimer.wait_time = Globals.shot_gcd
	$MeleeCDTimer.wait_time = Globals.melee_gcd

func _ready():
	pass	
	
func _physics_process(delta):
	# Speed caps
	if (self.velocity.x > Globals.speed_cap):
		self.velocity.x = Globals.speed_cap
	elif (self.velocity.x < -Globals.speed_cap):
		self.velocity.x = -Globals.speed_cap
	if (self.velocity.y > Globals.speed_cap):
		self.velocity.y = Globals.speed_cap
	elif (self.velocity.y < -Globals.speed_cap):
		self.velocity.y = -Globals.speed_cap	
	
	# Update offset	- this can probably be refactored - resets to lookahead adjust on keypress/release below
	var lookahead_slow: int = LOOKAHEAD_LIMIT / 2
	
	# Clamp the min and max camera speed
	if (lookahead_adjust < 1):
		lookahead_adjust = 1
	if (lookahead_adjust > 8):
		lookahead_adjust = 8
		
	if direction.x == 0 && attack_direction.x == 0:
		camera_offset_x = move_toward(camera_offset_x, 0, delta)
		lookahead_adjust = 0	
	
	elif (attack_direction.x > 0): 		
		if (camera_offset_x < LOOKAHEAD_LIMIT):
			camera_offset_x += lookahead_adjust
			if (camera_offset_x < lookahead_slow):
				lookahead_adjust += delta + LOOKAHEAD_SPEED
			else:
				lookahead_adjust -= delta + LOOKAHEAD_SPEED
	
	elif (attack_direction.x < 0):
		if (camera_offset_x > -LOOKAHEAD_LIMIT):
			camera_offset_x -= lookahead_adjust
			if (camera_offset_x > -lookahead_slow):
				lookahead_adjust += delta + LOOKAHEAD_SPEED
			else:
				lookahead_adjust -= delta + LOOKAHEAD_SPEED
	
	elif (direction.x > 0): 
		if (camera_offset_x < LOOKAHEAD_LIMIT):
			camera_offset_x += lookahead_adjust
			if (camera_offset_x < lookahead_slow):
				lookahead_adjust += delta + LOOKAHEAD_SPEED
			else:
				lookahead_adjust -= delta + LOOKAHEAD_SPEED
	
	elif (direction.x < 0):
		if (camera_offset_x > -LOOKAHEAD_LIMIT):
			camera_offset_x -= lookahead_adjust
			if (camera_offset_x > -lookahead_slow):
				lookahead_adjust += delta + LOOKAHEAD_SPEED
			else:
				lookahead_adjust -= delta + LOOKAHEAD_SPEED
	
	# Update cameras	
	var offset_position: Vector2i = global_position #.round() # Trying to fix scaling jitter
	offset_position.x = global_position.x + camera_offset_x
	offset_position.y = global_position.y	
	
	centerCam.global_position = offset_position	
	
	leftCam.global_position.x = offset_position.x - (Globals.WIDTH * 16)
	leftCam.global_position.y = offset_position.y
	rightCam.global_position.x = offset_position.x + (Globals.WIDTH * 16) 
	rightCam.global_position.y = offset_position.y
	
	topCam.global_position.x = offset_position.x
	topCam.global_position.y = offset_position.y - (Globals.HEIGHT * 16)
	bottomCam.global_position.x = offset_position.x
	bottomCam.global_position.y = offset_position.y + (Globals.HEIGHT * 16)	
	
	ULCam.global_position.x = offset_position.x - (Globals.WIDTH * 16)
	ULCam.global_position.y = offset_position.y - (Globals.HEIGHT * 16)
	URCam.global_position.x = offset_position.x + (Globals.WIDTH * 16) 
	URCam.global_position.y = offset_position.y - (Globals.HEIGHT * 16)
	
	LLCam.global_position.x = offset_position.x - (Globals.WIDTH * 16)
	LLCam.global_position.y = offset_position.y + (Globals.HEIGHT * 16)
	LRCam.global_position.x = offset_position.x + (Globals.WIDTH * 16)
	LRCam.global_position.y = offset_position.y + (Globals.HEIGHT * 16)	
	
	# Add the gravity.
	if not is_on_floor():		
		velocity.y += Globals.GRAVITY * delta
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
		elif cur_double_jumps < Globals.double_jumps:
			double_jump()
			
	if Input.is_action_just_released("jump"):
		if not is_on_floor():
			unjump()
			
	if Input.is_action_pressed("down"):
		if is_on_floor():				
			if not crouched:
				animated_sprite.play("crouch")
				animation_locked = true				
				crouched = true
			velocity.x = 0
			velocity.y += 200
	
	if Input.is_action_just_released("down"):
		orientation_locked = false
		animation_locked = false
		crouched = false
		
	if Input.is_action_just_pressed("attack left"):
		lookahead_adjust = 0
		
	if Input.is_action_just_pressed("attack right"):
		lookahead_adjust = 0	
			
	if Input.is_action_pressed("attack up") && Input.is_action_pressed("attack left"):
		attack_direction = Vector2(-1,-1)
		if Input.is_action_pressed("alternate attack"):
			melee_attack(Vector2i(-20,-20), Vector2(-1,-1).normalized())
		else:
			range_attack(Vector2i(-20,-20), Vector2(-1,-1).normalized())	
		
	elif Input.is_action_pressed("attack up") && Input.is_action_pressed("attack right"):
		attack_direction = Vector2(1,-1)
		if Input.is_action_pressed("alternate attack"):
			melee_attack(Vector2i(20,-20),Vector2(1,-1).normalized())	
		else:
			range_attack(Vector2i(20,-20),Vector2(1,-1).normalized())		
	
	elif Input.is_action_pressed("attack down") && Input.is_action_pressed("attack left"):
		attack_direction = Vector2(-1,1)
		if Input.is_action_pressed("alternate attack"):
			melee_attack(Vector2i(-20,20),Vector2(-1,1).normalized())	
		else:
			range_attack(Vector2i(-20,20),Vector2(-1,1).normalized())	
		
	elif Input.is_action_pressed("attack down") && Input.is_action_pressed("attack right"):
		attack_direction = Vector2(1,1)
		if Input.is_action_pressed("alternate attack"):
			melee_attack(Vector2i(20,20),Vector2(1,1).normalized())
		else:
			range_attack(Vector2i(20,20),Vector2(1,1).normalized())		
			
	elif Input.is_action_pressed("attack up"):
		attack_direction = Vector2(0,-1)
		if Input.is_action_pressed("alternate attack"):
			melee_attack(Vector2i(0,-20), Vector2(0,-1))
		else:
			range_attack(Vector2i(0,-20), Vector2(0,-1))	
		
	elif Input.is_action_pressed("attack down"):
		attack_direction = Vector2(0,1)
		if Input.is_action_pressed("alternate attack"):
			melee_attack(Vector2i(0,20),Vector2(0,1))	
		else:
			range_attack(Vector2i(0,20),Vector2(0,1))	
		
	elif Input.is_action_pressed("attack left"):
		attack_direction = Vector2(-1,0)
		if Input.is_action_pressed("alternate attack"):
			melee_attack(Vector2i(-20,0),Vector2(-1,0))	
		else:
			range_attack(Vector2i(-20,0),Vector2(-1,0))	
		
	elif Input.is_action_pressed("attack right"):
		attack_direction = Vector2(1,0)
		if Input.is_action_pressed("alternate attack"):
			melee_attack(Vector2i(20,0),Vector2(1,0))	
		else:
			range_attack(Vector2i(20,0),Vector2(1,0))		
		
	if Input.is_action_just_released("attack up"):
		attack_direction = Vector2.ZERO		
		
	if Input.is_action_just_released("attack down"):
		attack_direction = Vector2.ZERO
			
	if Input.is_action_just_released("attack left"):			
		attack_direction = Vector2.ZERO
		lookahead_adjust = 0
		
	if Input.is_action_just_released("attack right"):		
		attack_direction = Vector2.ZERO
		lookahead_adjust = 0

	# Get the input direction and handle the movement/deceleration.	
	direction = Input.get_vector("left", "right", "up", "down")	
	# Temporary undo vector normalization for now.			
	if direction.x < 0:
		direction.x = -1
	elif direction.x > 0:
		direction.x = 1
		
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * Globals.move_speed, Globals.accel)
	else:
		velocity.x = move_toward(velocity.x, 0, Globals.slide)
	
	move_and_slide()
	update_animation()
	if !orientation_locked:
		update_facing_direction()
	check_player_loc()
	
func align_attack(direction: Vector2):
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

func melee_attack(offset: Vector2i, direction: Vector2):
	if not melee_lock:
		align_attack(direction)
		animation_locked = true
		orientation_locked = true
		
		var slash_inst = basic_melee.instantiate()
		slash_inst.position.x = self.position.x + offset.x
		slash_inst.position.y = self.position.y + offset.y
		play_field.add_child(slash_inst)
		slash_inst.look_at(Vector2(self.position.x + direction.x * 50, self.position.y + direction.y * 50))
		
		slash_inst.set_slash(Globals.melee_life,2,Globals.melee_color,Globals.melee_weight, direction, self)
		slash_inst.velocity.x = (direction.x * Globals.melee_velocity) # + velocity.x <- inherit velocity
		slash_inst.velocity.y = (direction.y * Globals.melee_velocity) # + velocity.y	
		melee_lock = true
		$MeleeCDTimer.start()

func hit(magnitude: float):
	Globals.player_health -= abs(magnitude) / float(Globals.inertia)
	hud_node.update_hud()
	if Globals.player_health <= 0:
		Globals.player_health = 0
		expire()
	
func expire():
	var spark_inst = spark_scene.instantiate()
	spark_inst.scale *= 4
	spark_inst.position = self.global_position
	play_field.add_child(spark_inst)
	spark_inst.modulate = Color.DARK_RED
	spark_inst.emitting = true
	get_node("../PlayFieldMap").respawn()
	#$AnimatedSprite2D.visible = false
	#$CollisionShape2D.set_deferred("disabled", true)
	#$ExpiryTimer.start()
	
func range_attack(offset: Vector2i, direction: Vector2):
	if not shot_lock:
		align_attack(direction)
		animation_locked = true
		orientation_locked = true	
		
		var bullet_inst = basic_bullet.instantiate()
		bullet_inst.position.x = self.position.x + offset.x
		bullet_inst.position.y = self.position.y + offset.y
		play_field.add_child(bullet_inst)
		bullet_inst.set_bullet(Globals.shot_life,2,Globals.shot_color,Globals.shot_weight,"diamond",self)
		bullet_inst.velocity.x = (direction.x * Globals.shot_velocity) + randi_range(-Globals.shot_spread,Globals.shot_spread) # + velocity.x <- inherit velocity
		self.velocity.x += -direction.x * ((Globals.shot_weight * Globals.shot_velocity) / Globals.inertia)
		bullet_inst.velocity.y = (direction.y * Globals.shot_velocity) + randi_range(-Globals.shot_spread,Globals.shot_spread) # + velocity.y
		self.velocity.y += -direction.y * ((Globals.shot_weight * Globals.shot_velocity) / Globals.inertia)
		shot_lock = true
		$RangeCDTimer.start()

func jump():
	velocity.y = Globals.jump_velocity
	animated_sprite.play("jump_start")
	animation_locked = true
	
func unjump():
	if (cur_double_jumps < Globals.double_jumps) && (velocity.y < 0):
		velocity.y = Globals.jump_velocity / 10
	
func land():
	animated_sprite.play("jump_end")
	animation_locked = true
	cur_double_jumps = 0
	
func double_jump():
	velocity.y = Globals.dbl_jump_velocity
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
		crouched = false

func _on_animated_sprite_2d_animation_changed():
	pass
	
func _on_range_cd_timer_timeout():
	shot_lock = false

func _on_melee_cd_timer_timeout():
	melee_lock = false
		
func check_player_loc():
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

func _on_expiry_timer_timeout() -> void:
	pass	
