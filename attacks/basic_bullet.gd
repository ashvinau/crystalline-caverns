extends Area2D

var player_node: CharacterBody2D
var expiring: bool = false
var velocity: Vector2
var bullet_weight: float
var hit_list: Array = []
var spark_scene = preload("res://effects/sparks.tscn")
var liquid_scene = preload("res://effects/liquid_splash.tscn")
var smash_scene = preload("res://effects/tilemap_smash.tscn")

@onready var aura_node = get_node("Expiry/Aura")
@onready var expiry_node = get_node("Expiry")	

func set_bullet(life_time: float, coll_mask: int, color: Color, weight: float, shape: String, player: CharacterBody2D):
	$LifeTimer.wait_time = life_time
	$LifeTimer.start()
	set_collision_mask_value(coll_mask, true)
	self.scale.x *= weight 
	self.scale.y *= weight	
	$AnimatedSprite2D.material.set_shader_parameter("modulate",Globals.color_to_vector(color))
	$AnimatedSprite2D.modulate = color	
	$Expiry/ToroidalLight.color = color # update light size here?
	$Expiry/ToroidalLight.update_params()
	expiry_node.modulate = color	
	player_node = player
	bullet_weight = weight
	$AnimatedSprite2D.play(shape)
	remove_child(expiry_node)
	get_parent().add_child(expiry_node)	

func _physics_process(delta):
	if not expiring:
		expiry_node.position = global_position
	position.x += velocity.x * delta
	position.y += velocity.y * delta	
	velocity.y += (Globals.GRAVITY * delta) * bullet_weight # effect of gravity
	rotation_degrees += 100 * delta	
	check_bullet_loc()

func expire():
	expiring = true	
	$AnimatedSprite2D.visible = false
	$CollisionShape2D.set_deferred("disabled", true)	
	aura_node.emitting = false	
	aura_node.one_shot = true
	aura_node.emitting = true
	expiry_node.one_shot = true
	expiry_node.emitting = true		
	expiry_node.expiring = true
	call_deferred("queue_free")	

func _on_body_entered(body):
	if (not expiring) && (not hit_list.has(body.name)):
		hit_list.append(body.name)		
		if body is TileMap:
			var smash_inst = smash_scene.instantiate()
			smash_inst.scale *= bullet_weight
			smash_inst.position = self.position
			get_parent().add_child(smash_inst)
			smash_inst.modulate = body.BLOOD_COLOR
			smash_inst.emitting = true	
		elif body is CharacterBody2D:
			var liquid_inst = liquid_scene.instantiate()
			liquid_inst.scale *= bullet_weight
			apply_shot_force(body)		
			liquid_inst.position = Vector2.ZERO
			body.add_child(liquid_inst)
			liquid_inst.modulate = body.BLOOD_COLOR
			liquid_inst.emitting = true
			body.hit(self, velocity.length() * bullet_weight)
		expire()
		
func apply_shot_force(target_node):		
	target_node.velocity.y = velocity.y * bullet_weight
	target_node.velocity.x = velocity.x * bullet_weight

func _on_timer_timeout():
	if not expiring:
		expire()		
	
func check_bullet_loc():
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
