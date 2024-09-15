extends Area2D

const BLOOD_COLOR: Color = Color.YELLOW

var emitter_node: CharacterBody2D
var e_inertia: float
var expiring: bool = false
var slash_color: Color
var transparency: float = 1
var slash_direction: Vector2
var knockback: bool = false
var velocity: Vector2
var slash_weight: float
var hit_list: Array = []
var spark_scene = preload("res://effects/melee_sparks.tscn")
var liquid_scene = preload("res://effects/liquid_splash.tscn")
var smash_scene = preload("res://effects/tilemap_smash.tscn")
var melee_force: float

func set_slash(life_time: float, coll_mask: int, color: Color, weight: float, direction: Vector2, emitter: CharacterBody2D):
	$LifeTimer.wait_time = life_time
	$LifeTimer.start()
	slash_weight = weight
	set_collision_mask_value(coll_mask, true)	
	self.scale.x *= weight 
	self.scale.y *= weight
	slash_color = color
	slash_direction = direction	
	$AnimatedSprite2D.material.set_shader_parameter("modulate",Globals.color_to_vector(color))
	modulate = color	
	emitter_node = emitter
	e_inertia = emitter_node.e_inertia
	
func _physics_process(delta):
	position.x += velocity.x * delta
	position.y += velocity.y * delta
	check_slash_loc()	
	if expiring:
		transparency -= delta * 4		
		modulate = Color(slash_color.r, slash_color.g, slash_color.b, transparency)		
		$AnimatedSprite2D.material.set_shader_parameter("modulate",Globals.color_to_vector(modulate))
				
func _on_area_entered(area: Area2D) -> void:
	melee_force = (velocity.length() * slash_weight) / e_inertia
	if (not knockback) && (is_instance_valid(emitter_node)):
		if abs(slash_direction.x) > abs(slash_direction.y):
			emitter_node.velocity.x = -(slash_direction.x * melee_force)	
		else:
			emitter_node.velocity.y = -(slash_direction.y * melee_force)
		
		if emitter_node.cur_double_jumps > 0:
			emitter_node.cur_double_jumps -= 1
		knockback = true
	area.hit(self,melee_force)
		
func hit(from_node, magnitude: float):
	var spark_inst = spark_scene.instantiate()
	spark_inst.scale *= slash_weight
	spark_inst.position = self.position
	get_parent().add_child(spark_inst)
	spark_inst.modulate = BLOOD_COLOR
	spark_inst.emitting = true	
	queue_free()

func _on_body_entered(body):	
	melee_force = (velocity.length() * slash_weight) / e_inertia
	if (not knockback) && (is_instance_valid(emitter_node)):
		if abs(slash_direction.x) > abs(slash_direction.y):
			emitter_node.velocity.x = -(slash_direction.x * melee_force)	
		else:
			emitter_node.velocity.y = -(slash_direction.y * melee_force)
		
		if emitter_node.cur_double_jumps > 0:
			emitter_node.cur_double_jumps -= 1
		knockback = true
			
	if not hit_list.has(body.name):			
		if body is TileMap:
			var smash_inst = smash_scene.instantiate()
			smash_inst.scale *= slash_weight
			smash_inst.position = self.position
			get_parent().add_child(smash_inst)
			smash_inst.modulate = body.BLOOD_COLOR
			smash_inst.emitting = true		
		elif body is CharacterBody2D:
			var liquid_inst = liquid_scene.instantiate()
			liquid_inst.scale *= slash_weight
			apply_melee_force(body, melee_force)		
			liquid_inst.position = Vector2.ZERO
			body.add_child(liquid_inst)
			liquid_inst.modulate = body.BLOOD_COLOR
			liquid_inst.emitting = true
			body.hit(self, velocity.length() * slash_weight)			
		hit_list.append(body.name)
	
func apply_melee_force(target_node, melee_force: float):
		target_node.velocity.y = (slash_direction.y * melee_force)
		target_node.velocity.x = (slash_direction.x * melee_force)

func check_slash_loc():
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

func _on_life_timer_timeout():
	expiring = true		
	$CollisionShape2D.set_deferred("disabled", true)
	$ExpiryTimer.start()

func _on_expiry_timer_timeout():
	queue_free()
