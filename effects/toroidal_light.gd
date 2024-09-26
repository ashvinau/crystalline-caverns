extends Node2D

@export var shadows: bool = false
@export var energy: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CenterLight.shadow_enabled = shadows
	set_energy(energy)
	
func set_energy(new_energy: float):
	$CenterLight.energy = new_energy
	$CenterLight/EntityBackLight.energy = new_energy * 5
	$LeftLight.energy = new_energy
	$LeftLight/EntityBackLight.energy = new_energy * 5
	$RightLight.energy = new_energy
	$RightLight/EntityBackLight.energy = new_energy * 5
	$TopLight.energy = new_energy
	$TopLight/EntityBackLight.energy = new_energy * 5
	$BottomLight.energy = new_energy
	$BottomLight/EntityBackLight.energy = new_energy * 5	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
