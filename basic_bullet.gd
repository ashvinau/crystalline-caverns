extends Area2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var expiring: bool = false
var velocity: Vector2

func set_bullet(life_time: float, coll_mask: int, color: Color, weight: float, shape: String):
	$LifeTimer.wait_time = life_time
	$LifeTimer.start()
	set_collision_mask_value(coll_mask, true)
	self.scale.x *= weight 
	self.scale.y *= weight	
	$AnimatedSprite2D.material.set_shader_parameter("modulate",Globals.color_to_vector(color))
	modulate = color
	$AnimatedSprite2D.play(shape)

func _physics_process(delta):
	position.x += velocity.x * delta
	position.y += velocity.y * delta	
	velocity.y += (Globals.GRAVITY * delta) * Globals.shot_weight # effect of gravity
	rotation_degrees += 100 * delta
	checkBulletLoc()

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
	if not expiring:
		expire()

func _on_timer_timeout():
	if not expiring:
		expire()		
	
func _on_expiry_finished():	
	queue_free()
	
func checkBulletLoc():
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
