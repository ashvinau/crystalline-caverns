extends RigidBody2D

const TRANSLUCENCY: int = 128
var color_array: Array = [
Globals.color_dict[Globals.CRYSTAL_TYPES.VERMILLION],
Globals.color_dict[Globals.CRYSTAL_TYPES.TITIAN],
Globals.color_dict[Globals.CRYSTAL_TYPES.XANTHOUS],
Globals.color_dict[Globals.CRYSTAL_TYPES.VIRIDIAN],
Globals.color_dict[Globals.CRYSTAL_TYPES.CERULEAN],
Globals.color_dict[Globals.CRYSTAL_TYPES.AMARANTHINE]
]
var cur_index: int = randi_range(0,5)
var cur_color: Color = color_array[cur_index]
var expiring: bool = false

@onready var collision_node = $CrystalCollision
@onready var core_node = $CrystalCore
@onready var core_collect_scene = preload("res://effects/core_collect.tscn")
@onready var hud_node = get_node("/root/GameCanvas/HUD")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	set_linear_velocity(Vector2(randf_range(-20,20),randf_range(-300,-200)))
	set_angular_velocity(randf_range(-8*PI,8*PI))
	core_node.self_modulate = cur_color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:	
	check_core_loc()
	if expiring:
		core_node.self_modulate.a -= delta * 4	
		
	if core_node.self_modulate.r > cur_color.r:
		core_node.self_modulate.r -= delta
	elif core_node.self_modulate.r < cur_color.r:
		core_node.self_modulate.r += delta
	
	if core_node.self_modulate.g > cur_color.g:
		core_node.self_modulate.g -= delta
	elif core_node.self_modulate.g < cur_color.g:
		core_node.self_modulate.g += delta
		
	if core_node.self_modulate.b > cur_color.b:
		core_node.self_modulate.b -= delta
	elif core_node.self_modulate.b < cur_color.b:
		core_node.self_modulate.b += delta	
	
func check_core_loc():	
	var locX = self.position.x
	var locY = self.position.y	
	var lin_vel: Vector2
	var ang_vel: float
	freeze_mode = FREEZE_MODE_STATIC	
	# Wrap around teleports
	if (locX > Globals.WIDTH * 16):		
		lin_vel = get_linear_velocity()
		ang_vel = get_angular_velocity()
		freeze = true	
		global_position.x = 0
		freeze = false
		set_linear_velocity(lin_vel)
		set_angular_velocity(ang_vel)				
	elif (locX < 0):			
		lin_vel = get_linear_velocity()
		ang_vel = get_angular_velocity()
		freeze = true	
		global_position.x = Globals.WIDTH * 16
		freeze = false
		set_linear_velocity(lin_vel)
		set_angular_velocity(ang_vel)		
	elif (locY > Globals.HEIGHT * 16):		
		lin_vel = get_linear_velocity()
		ang_vel = get_angular_velocity()
		freeze = true		
		global_position.y = 0		
		freeze = false
		set_linear_velocity(lin_vel)
		set_angular_velocity(ang_vel)		
	elif (locY < 0):		
		lin_vel = get_linear_velocity()
		ang_vel = get_angular_velocity()
		freeze = true	
		global_position.y = Globals.HEIGHT * 16
		freeze = false
		set_linear_velocity(lin_vel)
		set_angular_velocity(ang_vel)

func _on_color_timer_timeout() -> void:
	cur_index += 1
	if cur_index > 5:
		cur_index = 0
	cur_color = color_array[cur_index]

func _on_expiry_timer_timeout() -> void:
	call_deferred("queue_free")

func _on_pickup_collision_body_entered(body: Node2D) -> void:
	if body.has_method("set_player") && not expiring:
		Globals.cores += 1
		hud_node.update_hud()
		expiring = true
		$GPUParticles2D.emitting = false
		var collect_inst = Globals.spawn_entity(core_collect_scene,body,Vector2.ZERO)
		collect_inst.emitting = true
		$ExpiryTimer.start()
				
