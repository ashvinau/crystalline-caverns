extends GPUParticles2D

var expiring: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if expiring && self_modulate.a > 0: 
		$ToroidalLight.energy -= delta
		$ToroidalLight.update_params()
		self.self_modulate.a -= delta

func _on_finished() -> void:
	queue_free()
