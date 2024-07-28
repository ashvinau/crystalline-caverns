extends CanvasLayer

@onready var centerViewport = $CenterViewportContainer/CenterViewport

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node("/root/GameCanvas/LeftViewportContainer/LeftViewport").world_2d = centerViewport.world_2d
	get_node("/root/GameCanvas/RightViewportContainer/RightViewport").world_2d = centerViewport.world_2d
	get_node("/root/GameCanvas/TopViewportContainer/TopViewport").world_2d = centerViewport.world_2d
	get_node("/root/GameCanvas/BottomViewportContainer/BottomViewport").world_2d = centerViewport.world_2d

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
