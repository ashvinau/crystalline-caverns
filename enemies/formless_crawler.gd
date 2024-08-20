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

var basic_bullet = preload("res://attacks/basic_bullet.tscn")
var basic_melee = preload("res://attacks/basic_melee.tscn")

func set_mob(color: Color, health: int, speed: int, cap: int, jump: int, moveCD: float, rangeCD: float, meleeCD: float):
	mob_health = health
	move_speed = speed
	speed_cap = cap
	jump_height = jump
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

func _on_move_timer_timeout() -> void:
	pass # Replace with function body.


func _on_range_timer_timeout() -> void:
	pass # Replace with function body.	


func _on_melee_timer_timeout() -> void:
	pass # Replace with function body.
