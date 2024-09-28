extends Node2D

@export var shadows: bool = false
@export var energy: float = 1.0
@export var tex_scale: float = 20
@export var color: Color = Color.WHITE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	update_params()
	
func update_params():
	$CenterLight.shadow_enabled = shadows
	set_energy(energy)
	set_tex_scale(tex_scale)
	set_color(color)
		
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
	
func set_tex_scale(new_scale: float):
	$CenterLight.texture_scale = new_scale
	$CenterLight/EntityBackLight.texture_scale = new_scale
	$LeftLight.texture_scale = new_scale
	$LeftLight/EntityBackLight.texture_scale = new_scale
	$RightLight.texture_scale = new_scale
	$RightLight/EntityBackLight.texture_scale = new_scale
	$TopLight.texture_scale = new_scale
	$TopLight/EntityBackLight.texture_scale = new_scale
	$BottomLight.texture_scale = new_scale
	$BottomLight/EntityBackLight.texture_scale = new_scale
	
func set_color(new_color: Color):
	$CenterLight.color = new_color
	$CenterLight/EntityBackLight.color = new_color
	$LeftLight.color = new_color
	$LeftLight/EntityBackLight.color = new_color
	$RightLight.color = new_color
	$RightLight/EntityBackLight.color = new_color
	$TopLight.color = new_color
	$TopLight/EntityBackLight.color = new_color
	$BottomLight.color = new_color
	$BottomLight/EntityBackLight.color = new_color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
