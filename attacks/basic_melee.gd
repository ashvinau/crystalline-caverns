extends Area2D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var player_node: CharacterBody2D
var expiring: bool = false
var slash_color: Color
var transparency: float = 1
var slash_direction: Vector2
var knockback: bool = false
var velocity: Vector2

func set_slash(life_time: float, coll_mask: int, color: Color, weight: float, direction: Vector2, player: CharacterBody2D):
	$LifeTimer.wait_time = life_time
	$LifeTimer.start()
	set_collision_mask_value(coll_mask, true)
	self.scale.x *= weight 
	self.scale.y *= weight
	slash_color = color
	slash_direction = direction
	$AnimatedSprite2D.material.set_shader_parameter("modulate",Globals.color_to_vector(color))
	modulate = color	
	player_node = player
	
func _physics_process(delta):	
	position.x += velocity.x * delta
	position.y += velocity.y * delta
	checkSlashLoc()	
	if expiring:
		transparency -= delta * 4		
		modulate = Color(slash_color.r, slash_color.g, slash_color.b, transparency)		
		$AnimatedSprite2D.material.set_shader_parameter("modulate",Globals.color_to_vector(modulate))				
				
func _on_body_entered(body):
	if (not knockback):
		knockback = true
		var melee_force = (Globals.melee_velocity * Globals.melee_weight) * 6
		player_node.velocity -= slash_direction * ((melee_force * Globals.melee_life) / Globals.inertia)
		if player_node.cur_double_jumps > 0:
			player_node.cur_double_jumps -= 1
		_on_life_timer_timeout()

func checkSlashLoc():
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
