extends Area2D

const MIN_SIZE: Vector2i = Vector2i(512,512)
const MAX_SIZE: Vector2i = Vector2i(512,1100)
const BUFFER: int = 175
const TRANSLUCENCY: int = 128
enum CRYSTAL_TYPES {VERMILLION, TITIAN, XANTHOUS, VIRIDIAN, CERULEAN, AMARANTHINE}
var color_array = [CRYSTAL_TYPES.VERMILLION,CRYSTAL_TYPES.TITIAN,CRYSTAL_TYPES.XANTHOUS,CRYSTAL_TYPES.VIRIDIAN,CRYSTAL_TYPES.CERULEAN,CRYSTAL_TYPES.AMARANTHINE]
var color_dict = {
	CRYSTAL_TYPES.VERMILLION: Color8(255,32,41,TRANSLUCENCY),
	CRYSTAL_TYPES.TITIAN: Color8(255,145,36,TRANSLUCENCY),
	CRYSTAL_TYPES.XANTHOUS: Color8(255,248,36,TRANSLUCENCY),
	CRYSTAL_TYPES.VIRIDIAN: Color8(48,255,25,TRANSLUCENCY),
	CRYSTAL_TYPES.CERULEAN: Color8(25,33,255,TRANSLUCENCY),
	CRYSTAL_TYPES.AMARANTHINE: Color8(225,25,228,TRANSLUCENCY)
}

var crystal_location: Vector2
var reeling: bool = false
var BLOOD_COLOR: Color
var crystal_size: Vector2i
var crystal_image: Image
var horiz_nodes: Array = []
var point_selections: Array = []
var cry_geo_matrix: Array = []
var nodes: int
var type: CRYSTAL_TYPES
var spark_scene = preload("res://effects/sparks.tscn")

# Called when the node enters the scene tree for the first time.
func _init() -> void:	
	print("Generating crystal...")	
	# Choose randomized crystal size
	crystal_size.x = randi_range(MIN_SIZE.x, MAX_SIZE.x)
	crystal_size.y = randi_range(MIN_SIZE.y, MAX_SIZE.y)	
	print("Crystal size: ", crystal_size)
	nodes = int(crystal_size.y / 128)
	
	# Create blank image
	crystal_image = Image.create(crystal_size.x,crystal_size.y,false,Image.FORMAT_RGBA8)	
	# Virtually shrink the available coordinates for point selection to allow buffer
	var upper_left: Vector2i = Vector2i(BUFFER, BUFFER)
	var lower_right: Vector2i = Vector2i(crystal_size.x-BUFFER,crystal_size.y-BUFFER)
	
	var division_size: int = (lower_right.y - upper_left.y) / nodes
	# Make the list of segments	
	for i in range(1,nodes):
		horiz_nodes.append((division_size * i) + BUFFER)	
	
	print("Segment division y-coords:")
	for div in horiz_nodes:
		print(div)
	
	# Required: 1 segment
	point_selections.append(Vector2i(randi_range(upper_left.x,lower_right.x),randi_range(upper_left.y,upper_left.y + division_size)))
	# Additional segments
	for cur_div in horiz_nodes:
		var curX = randi_range(upper_left.x,lower_right.x)
		var curY = randi_range(cur_div, cur_div + division_size)
		point_selections.append(Vector2i(curX,curY))
	
	print("Selected nucleation points:")	
	for selection in point_selections:
		print(selection)
		
	print("Growing crystal...")
	grow_crystal(point_selections[0],256)
	
	var type_ord: int = randi_range(0,5)
	type = color_array[type_ord]
	modulate = color_dict[type]
	BLOOD_COLOR = modulate
	print("Crystal type selected: ", str(type))
	
	print("Creating collision boxes...")
	for location in point_selections:
		spawn_coll_diamond(location)	
		
func _ready():
	print("Setting AOE...")
	get_node("AOE/Area").get_shape().radius = nodes * 100
	print("Updating texture...")
	$TextureRect.texture = ImageTexture.create_from_image(crystal_image)
	print("Generating crystal nav map...")
	var play_field_map_node = get_node("../PlayFieldMap")
	cry_geo_matrix = play_field_map_node.unmodified_geo_matrix.duplicate(true)
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			if cry_geo_matrix[x][y] >= 1 && cry_geo_matrix[x][y] <= 13: # Geo matrix from the playfield has 1-13s in spots with terrain, and 0s in open areas
				cry_geo_matrix[x][y] = 999999
	play_field_map_node.flood_fill(cry_geo_matrix,(self.global_position / 16),0,true,false)
	print("Crystal nav map complete.")
	
		
func grow_crystal(start_point: Vector2i, size: int):
	size = (size * size / 2) * nodes
	var target_color: Color = Color(0,0,0,0) # Transparent
	var queue = point_selections.duplicate(true)
	var cur_value: Color
	var rep_val: float = 1 # Monocolor, starting at white
	var cur_iter: int = 0
	
	while cur_iter <= size:
		var pos = queue.pop_front()
		
		if not is_safe_index(Vector2i(pos.x,pos.y)): # Invalid coordinates ignored
			continue
		else:
			cur_value = crystal_image.get_pixel(pos.x, pos.y)
		
		if cur_value != target_color:
			continue
		
		crystal_image.set_pixel(pos.x,pos.y,Color(rep_val,rep_val,rep_val,1.0))
		
		if is_safe_index(Vector2i(pos.x,pos.y-1)) && crystal_image.get_pixel(pos.x,pos.y-1) == target_color:
			queue.append(Vector2i(pos.x, pos.y - 1))
		if is_safe_index(Vector2i(pos.x+1,pos.y)) && crystal_image.get_pixel(pos.x+1,pos.y) == target_color:
			queue.append(Vector2i(pos.x + 1, pos.y))
		if is_safe_index(Vector2i(pos.x,pos.y+1)) && crystal_image.get_pixel(pos.x,pos.y+1) == target_color:
			queue.append(Vector2i(pos.x, pos.y + 1))
		if is_safe_index(Vector2i(pos.x-1,pos.y)) && crystal_image.get_pixel(pos.x-1,pos.y) == target_color:
			queue.append(Vector2i(pos.x - 1, pos.y))
		
		rep_val -= 0.00002 / nodes	
		cur_iter += 1
		
func is_safe_index(index: Vector2i) -> bool:
	return (index.x>=0) && (index.x < crystal_size.x) && (index.y>=0) && (index.y < crystal_size.y)
	
func hit(from_node, magnitude: float):
	if not reeling:
		crystal_location = global_position
		reeling = true
		position.x += from_node.velocity.x / 50
		position.y += from_node.velocity.y / 50
		var spark_inst = spark_scene.instantiate()
		spark_inst.scale *= nodes
		spark_inst.position = from_node.position
		get_parent().add_child(spark_inst)
		spark_inst.modulate = BLOOD_COLOR
		spark_inst.emitting = true
	
	#queue_free()
	
func spawn_coll_diamond(loc: Vector2i):		
	var shape = RectangleShape2D.new()	
	shape.set_size(Vector2(200,200))
	var new_diamond = CollisionShape2D.new()	
	new_diamond.set_shape(shape)
	set_collision_layer_value(12,true)
	set_collision_mask_value(12,true)	
	new_diamond.position.x = loc.x - (crystal_size.x / 2)
	new_diamond.position.y = loc.y - (crystal_size.y / 2)
	new_diamond.rotation_degrees = 45	
	add_child(new_diamond)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if position != crystal_location && reeling:
		position = position.move_toward(crystal_location,delta * 100)
	else:
		reeling = false
