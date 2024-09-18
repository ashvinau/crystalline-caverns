extends Area2D

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

@onready var core_node = $CrystalCore

# Called when the node enters the scene tree for the first time.
func _ready() -> void:		
	core_node.self_modulate = cur_color

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:		
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

func _on_color_timer_timeout() -> void:
	cur_index += 1
	if cur_index > 5:
		cur_index = 0
	cur_color = color_array[cur_index]
