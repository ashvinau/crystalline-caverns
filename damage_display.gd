extends Label

var r: float
var g: float
var b: float
var a: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	
func set_dmg_disp(amount: int, color: Color):
	self.text = str(amount)
	r = color.r
	g = color.g
	b = color.b
	a = 1
	modulate = Color(r,g,b,a)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:	
	a -= delta
	if a <= 0:
		queue_free()
	else:
		modulate = Color(r,g,b,a)
		position.y -= delta
	
