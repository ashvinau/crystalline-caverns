extends CharacterBody2D

var animation_locked: bool = false
var shot_lock: bool = false
var melee_lock: bool = false
var was_in_air: bool = false
var direction: Vector2 = Vector2.ZERO
var mob_health: float = 1
var move_speed: int
var accel: float = 5
var slide: float = 10
var speed_cap: int
var jump_height: int
var detection_dist: int
var shot_dist: int
var melee_dist: int
var player_nodes: Array = []
var mob_color: Color
var mob_level: int

var cur_double_jumps: int # Required for compatibility with basic_melee.gd - not used

var basic_bullet = preload("res://attacks/basic_bullet.tscn")
var basic_melee = preload("res://attacks/basic_melee.tscn")
@onready var play_field: Node2D = get_node("..") # parent node: PlayField

func set_mob(level: int, players: Array, color: Color, health: int, speed: int, cap: int, jump: int, moveCD: float, rangeCD: float, meleeCD: float, detect_d: int, shot_d: int, melee_d: int):
	player_nodes = players
	mob_health = health
	move_speed = speed
	speed_cap = cap
	jump_height = jump
	detection_dist = detect_d
	shot_dist = shot_d
	melee_dist = melee_d
	mob_color = color
	mob_level = level	
	$AnimatedSprite2D.material.set_shader_parameter("modulate",Globals.color_to_vector(color))
	modulate = color
	$MoveTimer.wait_time = moveCD
	$RangeTimer.wait_time = rangeCD
	$MeleeTimer.wait_time = meleeCD
	$AnimatedSprite2D.play("walking")

func _ready():
	pass
	
func _physics_process(delta):
	# Speed Caps
	if velocity.x > speed_cap:
		velocity.x = speed_cap
	elif velocity.x < -speed_cap:
		velocity.x = -speed_cap
	elif velocity.y > speed_cap:
		velocity.y = speed_cap
	elif velocity.y < -speed_cap:
		velocity.y = -speed_cap
		
	#Gravity
	if not is_on_floor():
		velocity.y += Globals.GRAVITY * delta
		was_in_air = true
	else:
		if was_in_air:
			land()
		was_in_air = false
		
	# acceleration and friction deceleration
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * move_speed, accel)
	else:
		velocity.x = move_toward(velocity.x, 0, slide)
		
	move_and_slide()
	update_animation()
	update_facing_direction()
	check_mob_loc()
		
func jump():
	velocity.y = jump_height
	$AnimatedSprite2D.play("jump")
	animation_locked = true

func land():
	$AnimatedSprite2D.play("land")
	animation_locked = true
	
func update_facing_direction():
	if direction.x > 0:
		$AnimatedSprite2D.flip_h = false
	elif direction.x < 0:
		$AnimatedSprite2D.flip_h = true
		
func update_animation():
	if !animation_locked:
		if !is_on_floor():
			$AnimatedSprite2D.play("idle") # jump animation
		else:
			if direction.x != 0:
				$AnimatedSprite2D.play("walking")
			else:
				$AnimatedSprite2D.play("idle")

func _on_animated_sprite_2d_animation_finished():
	if (["attack", "hit", "jump", "land"].has($AnimatedSprite2D.animation)):
		animation_locked = false
		
func hit(magnitude: float):	
	mob_health -= abs(magnitude) / float(Globals.INERTIA)	
	if mob_health > 0:
		mob_health = 0
	
func check_mob_loc():
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
		
func align_attack(direction: Vector2):
	if (direction.x > 0):
		$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D.play("attack")
	elif (direction.x < 0):
		$AnimatedSprite2D.flip_h = true
		$AnimatedSprite2D.play("attack")
		
func range_attack(offset: Vector2i, direction: Vector2):
	if not shot_lock:
		align_attack(direction)
		animation_locked = true		
		var bullet_inst = basic_bullet.instantiate()
		bullet_inst.position.x = self.position.x + offset.x
		bullet_inst.position.y = self.position.y + offset.y
		play_field.add_child(bullet_inst)
		bullet_inst.set_bullet(Globals.SHOT_LIFE,1,mob_color,Globals.SHOT_WEIGHT,"oval",self)
		bullet_inst.velocity.x = (direction.x * Globals.SHOT_VELOCITY) + randi_range(-Globals.SHOT_SPREAD,Globals.SHOT_SPREAD) 
		self.velocity.x += -direction.x * ((Globals.SHOT_WEIGHT * Globals.shot_velocity) / Globals.INERTIA)
		bullet_inst.velocity.y = (direction.y * Globals.SHOT_VELOCITY) + randi_range(-Globals.SHOT_SPREAD,Globals.SHOT_SPREAD)
		self.velocity.y += -direction.y * ((Globals.SHOT_WEIGHT * Globals.SHOT_VELOCITY) / Globals.INERTIA)
		shot_lock = true
		$RangeTimer.start()
		
func melee_attack(offset: Vector2i, direction: Vector2):
	if not melee_lock:
		align_attack(direction)
		animation_locked = true		
		var melee_inst = basic_melee.instantiate()
		melee_inst.position.x = self.position.x + offset.x
		melee_inst.position.y = self.position.y + offset.y
		play_field.add_child(melee_inst)
		melee_inst.look_at(Vector2(self.position.x + direction.x * 50, self.position.y + direction.y * 50))		
		melee_inst.set_slash(Globals.MELEE_LIFE,1,mob_color,Globals.MELEE_WEIGHT,direction,self)		
		melee_inst.velocity.x = (direction.x * Globals.melee_velocity) # + velocity.x <- inherit velocity
		melee_inst.velocity.y = (direction.y * Globals.melee_velocity) # + velocity.y	
		melee_lock = true
		$MeleeTimer.start()
	
func _on_move_timer_timeout() -> void:
	direction = Vector2.ZERO # Reset movement direction
	#identify the closest player in range
	var closest_player: CharacterBody2D
	var closest_dist: float = 999999 # Max float?
	for player in player_nodes:
		var cur_dist: float = Globals.toroidal_matrix_dist(Globals.WIDTH*16,Globals.HEIGHT*16,self.position,player.position)
		if cur_dist < closest_dist:
			closest_player = player
			closest_dist = cur_dist
				
	var tgt_player_loc: Vector2i = Vector2i(closest_player.position)
	# We need to adjust tgt_player_loc x (and y?) values if there is a difference of over half the width of the playfield
	if abs(tgt_player_loc.x - self.position.x) > ((Globals.WIDTH*16)/2):
		if (self.position.x < tgt_player_loc.x):
			tgt_player_loc.x -= Globals.WIDTH*16
		else:
			tgt_player_loc.x += Globals.WIDTH*16
	
	if (closest_dist < detection_dist): # Within detection range
		if (tgt_player_loc.x < self.position.x): # Choose movement direction
			direction = Vector2(-1,0)
		else:
			direction = Vector2(1,0)
			
	if (closest_dist < shot_dist): # Within projectile range
		var shot_direction: Vector2 = self.position.direction_to(tgt_player_loc)
		shot_direction.y -= closest_dist * 0.00033 # aim up a bit for distant targets
		range_attack(shot_direction * 20, shot_direction)
		
	if (closest_dist < melee_dist): # Within melee range
		var slash_direction: Vector2 = self.position.direction_to(tgt_player_loc)
		melee_attack(slash_direction * 20, slash_direction)		
		
	if is_on_wall() && is_on_floor():
		jump()

func _on_range_timer_timeout() -> void:
	shot_lock = false

func _on_melee_timer_timeout() -> void:
	melee_lock = false
