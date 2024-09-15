extends CharacterBody2D

const BLOOD_COLOR: Color = Color.RED

var animation_locked: bool = false
var shot_lock: bool = false
var melee_lock: bool = false
var direction: Vector2 = Vector2.ZERO
var bar_image: Image = Image.create(32,8,false, Image.FORMAT_RGBA8)
var cur_double_jumps: int # Required for compatibility with basic_melee.gd - not used

var STR: float
var CON: float
var DEX: float
var INT: float
var WIS: float

var max_health: float = 1
var mob_health: float = 1
var move_speed: int
var accel: float
var slide: float
var speed_cap: int
var detection_dist: int
var detection_mult: int = 2
var shot_dist: int
var melee_dist: int
var player_nodes: Array = []
var mob_color: Color
var e_inertia: float
var shot_life: float
var shot_weight: float
var shot_velocity: float
var shot_spread: float
var melee_life: float
var melee_weight: float
var melee_velocity: float

var basic_bullet = preload("res://attacks/basic_bullet.tscn")
var basic_melee = preload("res://attacks/basic_melee.tscn")
var spark_scene = preload("res://effects/sparks.tscn")
var dmg_scene = preload("res://damage_display.tscn")

@onready var play_field: Node2D = get_node("..") # parent node: PlayField

func set_mob(players: Array, color: Color, str: float, con: float, dex: float, inte: float, wis: float):	
	player_nodes = players
	mob_color = color
	
	STR = str
	CON = con
	DEX = dex
	INT = inte
	WIS = wis
	
	calculate_stats()	
	mob_health = max_health
	
	$AnimatedSprite2D.material.set_shader_parameter("modulate",Globals.color_to_vector(color))
	self_modulate = color
	$AnimatedSprite2D.play("idle")
	
func calculate_stats():
	shot_life = Globals.calc_shot_life(WIS)
	shot_weight = Globals.calc_shot_weight(INT)
	shot_velocity = Globals.calc_shot_vel(INT,WIS)
	shot_spread = Globals.calc_shot_spread(WIS)
	melee_life = Globals.calc_melee_life(WIS)
	melee_weight = Globals.calc_melee_weight(STR)
	melee_velocity = Globals.calc_melee_velocity(STR,DEX)
	max_health = Globals.calc_health(CON) / 2	
	move_speed = Globals.calc_move_speed(DEX)
	speed_cap = Globals.calc_speed_cap(CON)	
	detection_dist = Globals.calc_detection_dist(WIS) # ref value 900	
	shot_dist = Globals.calc_shot_dist(INT,WIS) # ref value 700	
	melee_dist = Globals.calc_melee_dist(STR,DEX) # ref value 400	
	accel = Globals.calc_accel(DEX,CON)
	slide = Globals.calc_slide(DEX,WIS)
	e_inertia = Globals.calc_defense(STR,CON)
	$MoveTimer.wait_time = Globals.calc_move_gcd(DEX,WIS) # ref value 1	
	$RangeTimer.wait_time = Globals.calc_shot_gcd(INT,DEX)
	$MeleeTimer.wait_time = Globals.calc_melee_gcd(CON,DEX)
	$AlertTimer.wait_time = Globals.calc_alert_gcd(INT,WIS)# ref value 5
	
func change_stat(stat: String, amount: float):
	if stat == "STR":
		STR += amount
	elif stat == "CON":
		CON += amount
	elif stat == "DEX":
		DEX += amount
	elif stat == "INT":
		INT += amount
	elif stat == "WIS":
		WIS += amount
	else:
		print("Invalid stat.")
	print("STR: ", STR, " CON: ", CON, " DEX: ", DEX, " INT: ", INT, " WIS: ", WIS)
	calculate_stats()
	update_health_bar()
	
func update_health_bar():	
	var health_proportion: float = (float(mob_health) / float(max_health)) * 32.0	
	for x in 32:
		for y in 8:
			if x <= health_proportion:
				bar_image.set_pixel(x,y,Color(1,0.1,0.1,0.8))	
			else:
				bar_image.set_pixel(x,y,Color(1,1,1,0))
	if health_proportion == 32:
		$HealthBar.visible = false
	else:
		$HealthBar.visible = true
		$HealthBar.texture.update(bar_image)	

func _ready():
	$HealthBar.texture = ImageTexture.create_from_image(bar_image)	
	update_health_bar()
	
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
		
		# acceleration and friction deceleration
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, direction.x * move_speed, accel)
	else:
		velocity.x = move_toward(velocity.x, 0, slide)
		
	if direction.y != 0:
		velocity.y = move_toward(velocity.y, direction.y * move_speed, accel)
	else:
		velocity.y = move_toward(velocity.y, 0, slide)
		
	if is_on_wall() || is_on_ceiling() || is_on_floor(): # unstucker
		_on_move_timer_timeout()
		
	move_and_slide()
	update_animation()
	update_facing_direction()
	check_mob_loc()
	
func update_facing_direction():
	if direction.x > 0:
		$AnimatedSprite2D.flip_h = false
	elif direction.x < 0:
		$AnimatedSprite2D.flip_h = true
		
func update_animation():
	if !animation_locked:
		if direction.x != 0 || direction.y != 0:
			$AnimatedSprite2D.play("walking")
		else:
			$AnimatedSprite2D.play("idle")

func _on_animated_sprite_2d_animation_finished():
	if (["attack", "hit"].has($AnimatedSprite2D.animation)):
		animation_locked = false
		
func heal(from_node, magnitude: float):
	var cured = abs(magnitude) * WIS
	mob_health += cured
	if mob_health > max_health:
		mob_health = max_health
	update_health_bar()
	var cure_inst = dmg_scene.instantiate()
	cure_inst.position.x = self.position.x - 32
	cure_inst.position.y = self.position.y - 55	
	play_field.add_child(cure_inst)
	cure_inst.set_dmg_disp(cured, Color.GREEN)	
		
func hit(from_node, magnitude: float):	
	$AnimatedSprite2D.play("hit")
	animation_locked = true
	var damage = abs(magnitude) / float(e_inertia)	
	mob_health -= damage
	if mob_health <= 0:
		mob_health = 0
		expire()
	detection_mult = 4
	update_health_bar()
	$AlertTimer.start()
	# Damage number display
	var dmg_inst = dmg_scene.instantiate()
	dmg_inst.position.x = self.position.x - 32
	dmg_inst.position.y = self.position.y - 55	
	play_field.add_child(dmg_inst)
	dmg_inst.set_dmg_disp(damage, Globals.DAMAGE_COLOR)
	
func expire():
	var spark_inst = spark_scene.instantiate()
	spark_inst.scale *= 4
	spark_inst.position = self.global_position
	play_field.add_child(spark_inst)
	spark_inst.modulate = BLOOD_COLOR
	spark_inst.emitting = true
	queue_free()
	
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
	else:
		$AnimatedSprite2D.play("attack")
		
func range_attack(offset: Vector2i, direction: Vector2):
	if not shot_lock:
		align_attack(direction)
		animation_locked = true		
		var bullet_inst = basic_bullet.instantiate()
		bullet_inst.position.x = self.position.x + offset.x
		bullet_inst.position.y = self.position.y + offset.y
		play_field.add_child(bullet_inst)
		bullet_inst.set_bullet(shot_life,1,mob_color,shot_weight,"oval",self)
		bullet_inst.velocity.x = (direction.x * shot_velocity) + randi_range(-shot_spread,shot_spread) 
		self.velocity.x += -direction.x * ((shot_weight * shot_velocity) / e_inertia)
		bullet_inst.velocity.y = (direction.y * shot_velocity) + randi_range(-shot_spread,shot_spread)
		self.velocity.y += -direction.y * ((shot_weight * shot_velocity) / e_inertia)
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
		melee_inst.set_slash(melee_life,1,mob_color,melee_weight,direction,self)		
		melee_inst.velocity.x = (direction.x * melee_velocity) # + velocity.x <- inherit velocity
		melee_inst.velocity.y = (direction.y * melee_velocity) # + velocity.y	
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
	
	# We need to adjust tgt_player_loc x and y values if there is a difference of over half the width of the playfield
	if abs(tgt_player_loc.x - self.position.x) > ((Globals.WIDTH*16)/2):
		if (self.position.x < tgt_player_loc.x):
			tgt_player_loc.x -= Globals.WIDTH*16
		else:
			tgt_player_loc.x += Globals.WIDTH*16
			
	if abs(tgt_player_loc.y - self.position.y) > ((Globals.HEIGHT*16)/2):
		if (self.position.y < tgt_player_loc.y):
			tgt_player_loc.y -= Globals.HEIGHT*16
		else:
			tgt_player_loc.y += Globals.HEIGHT*16
	
	# Update the raycast
	$ClearShot.target_position.x = tgt_player_loc.x - $ClearShot.global_position.x
	$ClearShot.target_position.y = tgt_player_loc.y - $ClearShot.global_position.y
	
	if $ClearShot.is_colliding() || closest_dist >= detection_dist * detection_mult:
		direction.x = randf_range(-1,1) # random movement with no line of sight
		direction.y = randf_range(-1,1)
	else:
		# Range state machine
		if (closest_dist < (detection_dist * detection_mult)) && (closest_dist >= shot_dist): # Within detection range, but not too close
			direction = self.position.direction_to(tgt_player_loc) # move toward
		elif (closest_dist < shot_dist): # if we are too close
			direction = -self.position.direction_to(tgt_player_loc) # move back		
			
		if (closest_dist < shot_dist): # Within projectile range
			var shot_direction: Vector2 = self.position.direction_to(tgt_player_loc)
			shot_direction.y -= closest_dist * 0.00033 # aim up a bit for distant targets - replace with correct math later
			range_attack(shot_direction * 20, shot_direction)
			
		if (closest_dist < melee_dist): # Within melee range
			var slash_direction: Vector2 = self.position.direction_to(tgt_player_loc)
			melee_attack(slash_direction * 20, slash_direction)	

func _on_range_timer_timeout() -> void:
	shot_lock = false

func _on_melee_timer_timeout() -> void:
	melee_lock = false

func _on_alert_timer_timeout() -> void:
	detection_mult = 2
