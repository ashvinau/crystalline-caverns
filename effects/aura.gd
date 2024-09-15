extends GPUParticles2D

var from_crystal
var expiring: bool = false
var num_nodes: int
var crystal_type: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Aura spawned for: ", self.get_parent().name)
	num_nodes = from_crystal.nodes
	crystal_type = from_crystal.type
	amount = num_nodes * 25

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:	
	if ((not is_instance_valid(from_crystal)) || (not $ConnectionArea.overlaps_area(from_crystal.get_node("AOE")))) && (not expiring):		
		expiring = true
		emitting = false
		one_shot = true
		emitting = true
		if crystal_type == 0:
			get_parent().change_stat("STR",-num_nodes)
		elif crystal_type == 1:
			get_parent().change_stat("CON",-num_nodes)
		elif crystal_type == 2:		
			get_parent().change_stat("DEX",-num_nodes)
		elif crystal_type == 3:
			$HealTimer.stop()
		elif crystal_type == 4:
			get_parent().change_stat("INT",-num_nodes)
		elif crystal_type == 5:
			get_parent().change_stat("WIS",-num_nodes)	

func _on_finished() -> void:
	print("Aura freed.")
	call_deferred("queue_free")

func _on_heal_timer_timeout() -> void:
	get_parent().heal(self, num_nodes * 5)
