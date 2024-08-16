extends CharacterBody2D

var animation_locked: bool = false
var shot_lock: bool = false
var melee_lock: bool = false
var was_in_air: bool = false
var direction: Vector2 = Vector2.ZERO

var basic_bullet = preload("res://attacks/basic_bullet.tscn")
var basic_melee = preload("res://attacks/basic_melee.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
