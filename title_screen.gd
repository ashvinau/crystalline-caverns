extends Node2D

@onready var background_node = $TitleBackground
@onready var title_text_node = $TitleBackground/TitleText
@onready var menu_node = $TitleBackground/MainMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	background_node.modulate.a = 0
	title_text_node.modulate.a = 0
	menu_node.modulate.a = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if background_node.modulate.a <= 1:
		background_node.modulate.a += delta
	else:
		if title_text_node.modulate.a <= 1:
			title_text_node.modulate.a += delta
		else:
			if menu_node.modulate.a <= 1:
				menu_node.modulate.a += delta
