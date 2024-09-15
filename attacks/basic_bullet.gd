extends Area2D

var player_node: CharacterBody2D
var expiring: bool = false
var velocity: Vector2
var bullet_weight: float
var hit_list: Array = []
var spark_scene = preload("res://effects/sparks.tscn")

func set_bullet(life_time: float, coll_mask: int, color: Color, weight: float, shape: String, player: CharacterBody2D):
	$LifeTimer.wait_time = life_time
	$LifeTimer.start()
	set_collision_mask_value(coll_mask, true)
	self.scale.x *= weight 
	self.scale.y *= weight	
	$AnimatedSprite2D.material.set_shader_parameter("modulate",Globals.color_to_vector(color))
	modulate = color
	player_node = player
	bullet_weight = weight
	$AnimatedSprite2D.play(shape)

func _physics_process(delta):
	position.x += velocity.x * delta
	position.y += velocity.y * delta	
	velocity.y += (Globals.GRAVITY * delta) * bullet_weight # effect of gravity
	rotation_degrees += 100 * delta
	check_bullet_loc()

func expire():
	expiring = true	
	$AnimatedSprite2D.visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	$ExpiryTimer.start()
	$Aura.emitting = false
	$Expiry.emitting = false
	$Expiry.one_shot = true
	$Expiry.emitting = true		

func _on_body_entered(body):
	if (not expiring) && (not hit_list.has(body.name)):
		hit_list.append(body.name)
		var spark_inst = spark_scene.instantiate()
		spark_inst.scale *= bullet_weight
		if body is TileMap:
			spark_inst.position = self.position
			get_parent().add_child(spark_inst)
			spark_inst.modulate = body.BLOOD_COLOR
			spark_inst.emitting = true	
		elif body is CharacterBody2D:
			apply_shot_force(body)		
			spark_inst.position = Vector2.ZERO
			body.add_child(spark_inst)
			spark_inst.modulate = body.BLOOD_COLOR
			spark_inst.emitting = true
			body.hit(self, velocity.length() * bullet_weight)
		expire()
		
func apply_shot_force(target_node):		
	target_node.velocity.y = velocity.y * bullet_weight
	target_node.velocity.x = velocity.x * bullet_weight

func _on_timer_timeout():
	if not expiring:
		expire()		
	
func _on_expiry_finished():	
	call_deferred("queue_free")
	
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
