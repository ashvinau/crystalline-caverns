extends CharacterBody2D

signal process_more_nav_map
const BLOOD_COLOR: Color = Color8(255,20,20,128)

var animation_locked: bool = false
var shot_lock: bool = false
var melee_lock: bool = false
var navigating: bool = false
var navigation_ready = false
var direction: Vector2 = Vector2.ZERO
var tgt_player_loc: Vector2i
var bar_image: Image = Image.create(64,8,false, Image.FORMAT_RGBA8)
var minions: Array = []
var map_loc: Vector2i
var tgt_map_loc: Vector2i
var target_crystal: Area2D
var fleeing: bool = false
var mob_geo_matrix_original: Array = []
var mob_geo_matrix: Array = []
var invalid_crystals: Array = []

var STR: float
var CON: float
var DEX: float
var INT: float
var WIS: float

var add_STR: float
var add_CON: float
var add_DEX: float
var add_INT: float
var add_WIS: float

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
var inertia: float
var faith: float
var shot_life: float
var shot_weight: float
var shot_velocity: float
var shot_spread: float
var melee_life: float
var melee_weight: float
var melee_velocity: float
var bonus_stat: int
var bonus_amount: int

var basic_bullet = preload("res://attacks/basic_bullet.tscn")
var basic_melee = preload("res://attacks/basic_melee.tscn")
var chunk_scene = preload("res://effects/tilemap_smash.tscn")
var dmg_scene = preload("res://damage_display.tscn")

@onready var play_field: Node2D = get_node("..") # parent node: PlayField
@onready var play_field_map: Node2D = get_node("../PlayFieldMap") # parent node: PlayField
@onready var hud_node = get_node("../../../../HUD")

func set_mob(players: Array, color: Color, str: float, con: float, dex: float, inte: float, wis: float):
	bonus_stat = randi_range(0,4)
	bonus_amount = randi_range(1,min(str,con,dex,inte,wis))
	
	STR = str
	CON = con
	DEX = dex
	INT = inte
	WIS = wis	
	add_STR = str
	add_CON = con
	add_DEX = dex
	add_INT = inte
	add_WIS = wis
	
	if bonus_stat == 0:
		STR += bonus_amount
		add_STR += bonus_amount / 2
		color = Globals.color_dict[Globals.CRYSTAL_TYPES.VERMILLION]		
	elif bonus_stat == 1:
		CON += bonus_amount
		add_CON += bonus_amount / 2
		color = Globals.color_dict[Globals.CRYSTAL_TYPES.TITIAN]
	elif bonus_stat == 2:
		DEX += bonus_amount
		add_DEX += bonus_amount / 2
		color = Globals.color_dict[Globals.CRYSTAL_TYPES.XANTHOUS]
	elif bonus_stat == 3:
		INT += bonus_amount
		add_INT += bonus_amount / 2
		color = Globals.color_dict[Globals.CRYSTAL_TYPES.CERULEAN]
	elif bonus_stat == 4:
		WIS += bonus_amount
		add_WIS += bonus_amount / 2
		color = Globals.color_dict[Globals.CRYSTAL_TYPES.AMARANTHINE]
	
	color.a = 1	
	minions.append(preload("res://enemies/formless_crawler.tscn"))
	minions.append(preload("res://enemies/formless_flyer.tscn"))	
	player_nodes = players
	mob_color = color
	
	calculate_stats()	
	mob_health = max_health
	
	$AnimatedSprite2D.material.set_shader_parameter("modulate",Globals.color_to_vector(color))
	self_modulate = color	
	$AnimatedSprite2D.play("idle")
	$NavTimer.wait_time = 15
	$AddTimer.wait_time = $MoveTimer.wait_time * 25
	
func calculate_stats():
	shot_life = Globals.calc_shot_life(WIS)
	shot_weight = Globals.calc_shot_weight(INT)
	shot_velocity = Globals.calc_shot_vel(INT,WIS)
	shot_spread = Globals.calc_shot_spread(WIS)
	melee_life = Globals.calc_melee_life(WIS)
	melee_weight = Globals.calc_melee_weight(STR)
	melee_velocity = Globals.calc_melee_velocity(STR,DEX)
	max_health = Globals.calc_health(CON) * 3	
	move_speed = Globals.calc_move_speed(DEX)
	speed_cap = Globals.calc_speed_cap(CON)	
	detection_dist = Globals.calc_detection_dist(WIS) # ref value 900	
	shot_dist = Globals.calc_shot_dist(INT,WIS) * 1.5# ref value 700	
	melee_dist = Globals.calc_melee_dist(STR,DEX) # ref value 400	
	accel = Globals.calc_accel(DEX,CON)
	slide = Globals.calc_slide(DEX,WIS)
	inertia = Globals.calc_defense(STR,CON) * 2
	faith = Globals.calc_defense(WIS, INT) * 2
	$MoveTimer.wait_time = Globals.calc_move_gcd(DEX,WIS) # ref value 1	
	$RangeTimer.wait_time = Globals.calc_shot_gcd(INT,DEX)	
	$MeleeTimer.wait_time = Globals.calc_melee_gcd(CON,DEX)	
	$AlertTimer.wait_time = Globals.calc_alert_gcd(INT,WIS)# ref value 5
	var scale_fac = inertia / 2
	self.scale = Vector2(scale_fac,scale_fac)
	var hb_scale_fac = 1 / scale_fac
	$HealthBar.scale = Vector2(hb_scale_fac,hb_scale_fac)
	
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
	if amount > 0:
		fleeing = false # Fleeing boss has reached a node that is not a healing crystal, this should recalc furthest crystal
		print("FungusLord has reached a crystal, no longer fleeing.")
	
func update_health_bar():	
	var health_proportion: float = (float(mob_health) / float(max_health)) * 64.0
	for x in 64:
		for y in 8:
			if x <= health_proportion:
				bar_image.set_pixel(x,y,Color(1,0.1,0.1,0.8))	
			else:
				bar_image.set_pixel(x,y,Color(1,1,1,0))
	if health_proportion == 64:
		$HealthBar.visible = false
	else:
		$HealthBar.visible = true
	$HealthBar.texture.update(bar_image)

func _ready():	
	mob_geo_matrix_original = play_field_map.unmodified_geo_matrix.duplicate(true)
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			if mob_geo_matrix_original[x][y] >= 1 && mob_geo_matrix_original[x][y] <= 13: # Geo matrix from the playfield has 1-13s in spots with terrain, and 0s in open areas
				mob_geo_matrix_original[x][y] = 999999
	play_field_map.navigation_map_complete.connect(_on_navigation_map_complete)
	$HealthBar.texture = ImageTexture.create_from_image(bar_image)	
	update_health_bar()
	$NavTimer.start()
	$AddTimer.start()
	
	
func _process(delta):
	for i in 256:
		process_more_nav_map.emit()

func _physics_process(delta):	
	map_loc = global_position / 16
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
	
	#if is_on_wall() || is_on_ceiling() || is_on_floor(): # unstucker
	#	_on_move_timer_timeout()
		
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
	animation_locked = true
	$AnimatedSprite2D.play("hit")	
	var damage: float = 0
	if (from_node.has_method("set_slash")):
		damage = abs(magnitude) / float(inertia)
	elif (from_node.has_method("set_bullet")):
		damage = abs(magnitude) / float(faith)	
	mob_health -= damage
	if mob_health <= 0:
		mob_health = 0
		expire()
	detection_mult = 4
	update_health_bar()
	$AlertTimer.start()
	print("FungusLord health: ", mob_health, "/", max_health)
	# Damage number display
	var dmg_inst = dmg_scene.instantiate()
	dmg_inst.position.x = self.position.x - 64
	dmg_inst.position.y = self.position.y - 55	
	play_field.add_child(dmg_inst)
	dmg_inst.set_dmg_disp(damage, Globals.DAMAGE_COLOR)
	
func expire():
	var chunk_inst = chunk_scene.instantiate()
	chunk_inst.scale *= 4
	chunk_inst.position = self.global_position
	play_field.add_child(chunk_inst)
	chunk_inst.modulate = BLOOD_COLOR
	chunk_inst.emitting = true
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
		bullet_inst.set_bullet(shot_life,1,self_modulate,shot_weight,"oval",self)
		bullet_inst.velocity.x = (direction.x * shot_velocity) + randi_range(-shot_spread,shot_spread) 
		self.velocity.x += -direction.x * ((shot_weight * shot_velocity) / inertia)
		bullet_inst.velocity.y = (direction.y * shot_velocity) + randi_range(-shot_spread,shot_spread)
		self.velocity.y += -direction.y * ((shot_weight * shot_velocity) / inertia)
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
		melee_inst.set_slash(melee_life,1,self_modulate,melee_weight,direction,self)
		melee_inst.velocity.x = (direction.x * melee_velocity) # + velocity.x <- inherit velocity
		melee_inst.velocity.y = (direction.y * melee_velocity) # + velocity.y
		melee_lock = true
		$MeleeTimer.start()
	
func _on_move_timer_timeout() -> void:
	direction = Vector2.ZERO # Reset movement direction	
		
	#Enable / Disable fleeing mode, find the furthest crystal location
	if (mob_health <= max_health / 2) && (not fleeing) && (play_field_map.crystals.size() - invalid_crystals.size() > 0):
		fleeing = true
		print(name, " is fleeing.")
		# Find furthest crystal location
		var furthest_crystal: Area2D
		var furthest_dist: float = 0		
		for crystal in play_field_map.crystals:			
			if (crystal.cry_geo_matrix[map_loc.x][map_loc.y] != 0):
				if crystal.type == Globals.CRYSTAL_TYPES.VIRIDIAN:
					print("Viridian crystal found.")
					furthest_crystal = crystal
					break
				var cur_dist: float = Globals.toroidal_matrix_dist(Globals.WIDTH*16,Globals.HEIGHT*16,self.global_position,crystal.global_position)						
				if (cur_dist > furthest_dist):
					furthest_dist = cur_dist
					furthest_crystal = crystal
			else:
				print("Crystal inaccessable, skipping.")
				if not invalid_crystals.has(crystal):
					invalid_crystals.append(crystal)
		
		target_crystal = furthest_crystal
	elif (mob_health > (max_health * 0.75)) && fleeing:
		print(name, " has healed and is no longer fleeing.")
		fleeing = false
	
	#identify the closest player in range
	var closest_player: CharacterBody2D
	var closest_dist: float = 999999 # Max float?
	for player in player_nodes:
		var cur_dist: float = Globals.toroidal_matrix_dist(Globals.WIDTH*16,Globals.HEIGHT*16,self.position,player.position)
		if cur_dist < closest_dist:
			closest_player = player
			closest_dist = cur_dist
				
	if is_instance_valid(closest_player):
		tgt_player_loc = Vector2i(closest_player.position)
		tgt_map_loc = tgt_player_loc / 16
	
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
	
	if $ClearShot.is_colliding() || closest_dist >= detection_dist * detection_mult || fleeing:
		if (navigation_ready) && (not (is_on_wall() || is_on_ceiling() || is_on_floor())):
			# Query map for values						
			print("Following map...")
			var nav_map: Array = []
			var nav_array: Array = []
			var nav_offset: int = 3
			
			if fleeing && is_instance_valid(target_crystal):
				nav_map = target_crystal.cry_geo_matrix				
			else:
				nav_map = mob_geo_matrix
			nav_array.append(Globals.get_mat_val(nav_map, Vector2i(map_loc.x, map_loc.y - nav_offset)))	# [0] North
			nav_array.append(Globals.get_mat_val(nav_map, Vector2i(map_loc.x + nav_offset, map_loc.y - nav_offset))) # [1] Northeast
			nav_array.append(Globals.get_mat_val(nav_map, Vector2i(map_loc.x + nav_offset, map_loc.y))) # [2] East
			nav_array.append(Globals.get_mat_val(nav_map, Vector2i(map_loc.x + nav_offset, map_loc.y + nav_offset))) # [3] Southeast
			nav_array.append(Globals.get_mat_val(nav_map, Vector2i(map_loc.x, map_loc.y + nav_offset))) # [4] South
			nav_array.append(Globals.get_mat_val(nav_map, Vector2i(map_loc.x - nav_offset, map_loc.y + nav_offset))) # [5] Southwest
			nav_array.append(Globals.get_mat_val(nav_map, Vector2i(map_loc.x - nav_offset, map_loc.y))) # [6] West
			nav_array.append(Globals.get_mat_val(nav_map, Vector2i(map_loc.x - nav_offset, map_loc.y - nav_offset))) # [7] Northwest
			
			# Find the index of the lowest value
			var lowest_value: int = 999999
			var lowest_index: int	
			
			for i in 8:
				if nav_array[i] < lowest_value:
					lowest_value = nav_array[i]
					lowest_index = i
					
			print("Lowest value: ", lowest_value, " in index: ", lowest_index)
						
			# Choose a direction based on the lowest index		
			if lowest_value == 999999:				
				navigation_ready = false
			elif lowest_index == 0: # N
				direction = Vector2(0,-Globals.NAV_SPEED)
			elif lowest_index == 1: # NE
				direction = Vector2(Globals.NAV_SPEED,-Globals.NAV_SPEED)
			elif lowest_index == 2: # E
				direction = Vector2(Globals.NAV_SPEED,0)
			elif lowest_index == 3: # SE
				direction = Vector2(Globals.NAV_SPEED,Globals.NAV_SPEED)
			elif lowest_index == 4: # S
				direction = Vector2(0,Globals.NAV_SPEED)
			elif lowest_index == 5: # SW
				direction = Vector2(-Globals.NAV_SPEED,Globals.NAV_SPEED)
			elif lowest_index == 6: # W
				direction = Vector2(-Globals.NAV_SPEED,0)
			elif lowest_index == 7: # NW
				direction = Vector2(-Globals.NAV_SPEED,-Globals.NAV_SPEED)
			
		else:
			direction.x = randf_range(-0.5,0.5) # random movement with no line of sight
			direction.y = randf_range(-0.5,0.5)
		if not navigating:
			navigating = true
	else:		
		# Range state machine
		if (closest_dist < (detection_dist * detection_mult)) && (closest_dist >= shot_dist): # Within detection range, but not too close
			direction = self.position.direction_to(tgt_player_loc).normalized() # move toward
		elif (closest_dist < shot_dist): # if we are too close
			direction = -self.position.direction_to(tgt_player_loc).normalized() # move back
			
	if (closest_dist < shot_dist) && not $ClearShot.is_colliding(): # Within projectile range
		var shot_direction: Vector2 = self.position.direction_to(tgt_player_loc)
		shot_direction.y -= closest_dist * 0.00033 # aim up a bit for distant targets - replace with correct math later
		range_attack(shot_direction * 20, shot_direction)
		shot_lock = false
		range_attack(shot_direction * 20, shot_direction.rotated(PI / 16))
		shot_lock = false
		range_attack(shot_direction * 20, shot_direction.rotated(-(PI / 16)))
			
	if (closest_dist < melee_dist): # Within melee range
		var slash_direction: Vector2 = self.position.direction_to(tgt_player_loc)
		melee_attack((slash_direction * 200), slash_direction)
		melee_lock = false
		melee_attack((slash_direction * 200).rotated(PI / 8), slash_direction.rotated(PI / 8))
		melee_lock = false
		melee_attack((slash_direction * 200).rotated(-PI / 8), slash_direction.rotated(-(PI / 8)))

func _on_range_timer_timeout() -> void:
	shot_lock = false

func _on_melee_timer_timeout() -> void:
	melee_lock = false

func _on_alert_timer_timeout() -> void:
	detection_mult = 2

func _on_nav_timer_timeout() -> void:	
	if navigating:
		print("Navigation map computing...")
		navigation_ready = false
		mob_geo_matrix.clear()
		mob_geo_matrix = mob_geo_matrix_original.duplicate(true)
		var adjusted_loc: Vector2i = tgt_map_loc
		if mob_geo_matrix[tgt_map_loc.x][tgt_map_loc.y] == 0:
			adjusted_loc = Globals.safe_index(Vector2i(tgt_map_loc.x,tgt_map_loc.y))
		elif mob_geo_matrix[tgt_map_loc.x][tgt_map_loc.y-1] == 0:
			adjusted_loc = Globals.safe_index(Vector2i(tgt_map_loc.x,tgt_map_loc.y-1))
		elif mob_geo_matrix[tgt_map_loc.x][tgt_map_loc.y+1] == 0:
			adjusted_loc = Globals.safe_index(Vector2i(tgt_map_loc.x,tgt_map_loc.y+1))
		elif mob_geo_matrix[tgt_map_loc.x-1][tgt_map_loc.y] == 0:
			adjusted_loc = Globals.safe_index(Vector2i(tgt_map_loc.x-1,tgt_map_loc.y))
		elif mob_geo_matrix[tgt_map_loc.x+1][tgt_map_loc.y] == 0:
			adjusted_loc = Globals.safe_index(Vector2i(tgt_map_loc.x+1,tgt_map_loc.y))
		else:
			print("Navigation failed, cannot reach destination.")			
		
		play_field_map.flood_fill(mob_geo_matrix,adjusted_loc,0,true,true)		
		
func _on_navigation_map_complete():
	navigating = false
	navigation_ready = true
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			if mob_geo_matrix[x][y] == 0:
				mob_geo_matrix[x][y] = 999999
	print("Navigation map complete.")
	$NavTimer.start()

func _on_add_timer_timeout() -> void:
	print("Fungus lord spawning add...")
	var minion_idx = randi_range(0,minions.size()-1)
	var minion_inst = minions[minion_idx].instantiate()
	var tgt_direction = self.position.direction_to(tgt_player_loc)
	animation_locked = true
	$AnimatedSprite2D.play("hit")
	minion_inst.position.x = self.position.x + (tgt_direction.x * 32)
	minion_inst.position.y = self.position.y + (tgt_direction.y * 32)
	play_field.add_child(minion_inst)
	minion_inst.set_mob(player_nodes,mob_color,add_STR,add_CON,add_DEX,add_INT,add_WIS)
	$AddTimer.start()
	
