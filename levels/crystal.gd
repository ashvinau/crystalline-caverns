extends Area2D

const MIN_SIZE: Vector2i = Vector2i(512,512)
const MAX_SIZE: Vector2i = Vector2i(512,1100)
const BUFFER: int = 175

var str_mod: int = 0
var con_mod: int = 0
var dex_mod: int = 0
var int_mod: int = 0
var wis_mod: int = 0
var crystal_hp: float
var crystal_location: Vector2
var reeling: bool = false
var BLOOD_COLOR: Color
var crystal_size: Vector2i
var crystal_image: Image
var horiz_nodes: Array = []
var point_selections: Array = []
var cry_geo_matrix: Array = []
var nodes: int
var type: Globals.CRYSTAL_TYPES
var aura_inst: Node2D
var aoe_range: float
var char_aura
var expiring: bool = false
var chunk_scene = preload("res://effects/tilemap_smash.tscn")
var aura_scene = preload("res://effects/aura.tscn")
var shatter_scene = preload("res://effects/crystal_shatter.tscn")
var dmg_scene = preload("res://damage_display.tscn")
var core_scene = preload("res://levels/crystal_core.tscn")

@onready var play_field_map_node = get_node("../PlayFieldMap")
@onready var hud_node = get_node("../../../../HUD")

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
	type = Globals.color_array[type_ord]
	var name: String
	modulate = Globals.color_dict[type]
	BLOOD_COLOR = modulate	
	if type == 0:
		name = "Vermillion"
		str_mod += 5
	elif type == 1:
		name = "Titian"
		con_mod += 5
	elif type == 2:
		name = "Xanthous"	
		dex_mod += 5
	elif type == 3:	
		name = "Viridian"
	elif type == 4:
		name = "Cerulean"
		int_mod += 5
	elif type == 5:
		name = "Amaranthine"
		wis_mod += 5
	print("Crystal type selected: ", name)
	print("Creating collision boxes...")
	for location in point_selections:
		spawn_coll_diamond(location)
		
func _ready():
	print("Setting AOE...")
	aoe_range = pow(nodes * 100,1.01)
	get_node("AOE/Area").get_shape().radius = aoe_range
	crystal_hp = nodes * 500	
	print("Updating texture...")
	$TextureRect.texture = ImageTexture.create_from_image(crystal_image)
	print("Generating crystal nav map...")	
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
		
		if is_safe_index(Vector2i(pos.x,pos.y - 1)) && crystal_image.get_pixel(pos.x,pos.y - 1) == target_color:
			queue.append(Vector2i(pos.x, pos.y - 1))
		if is_safe_index(Vector2i(pos.x + 1,pos.y)) && crystal_image.get_pixel(pos.x + 1,pos.y) == target_color:
			queue.append(Vector2i(pos.x + 1, pos.y))
		if is_safe_index(Vector2i(pos.x,pos.y+1)) && crystal_image.get_pixel(pos.x,pos.y + 1) == target_color:
			queue.append(Vector2i(pos.x, pos.y + 1))
		if is_safe_index(Vector2i(pos.x - 1,pos.y)) && crystal_image.get_pixel(pos.x - 1,pos.y) == target_color:
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
		var chunk_inst = chunk_scene.instantiate()		
		chunk_inst.position = from_node.position
		get_parent().add_child(chunk_inst)
		chunk_inst.modulate = BLOOD_COLOR
		chunk_inst.emitting = true
		
		var dmg_inst = dmg_scene.instantiate()
		dmg_inst.position.x = from_node.position.x - 32
		dmg_inst.position.y = from_node.position.y - 55
		play_field_map_node.get_parent().add_child(dmg_inst)
		dmg_inst.set_dmg_disp(magnitude,BLOOD_COLOR)
		crystal_hp -= magnitude
		print("Remaining HP: ", crystal_hp)
		if crystal_hp <= 0 && not expiring:
			expire()

func expire():
	expiring = true
	for location in point_selections:
		var shatter_inst = shatter_scene.instantiate()
		shatter_inst.position.x = location.x - (crystal_size.x / 2)
		shatter_inst.position.y = location.y - (crystal_size.y / 2)		
		self.add_child(shatter_inst)
		shatter_inst.modulate = BLOOD_COLOR
	var child_nodes = get_children()
	for child in child_nodes:
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	for i in nodes:
		var core_inst = core_scene.instantiate()
		core_inst.position = global_position
		play_field_map_node.call_deferred("add_child",core_inst)
	hud_node.add_map_indicator("destroyed", position / 16)
	$ExpiryTimer.start()	
	
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
	if expiring && $TextureRect.self_modulate.a > 0:
		$TextureRect.self_modulate.a -= delta * 8
	if position != crystal_location && reeling:
		position = position.move_toward(crystal_location,delta * 100)
	else:
		reeling = false

func _on_aoe_body_entered(body: Node2D) -> void:	
	print(body.name, " entered a crystal aoe.")
	char_aura = aura_scene.instantiate()
	body.call_deferred("add_child", char_aura)	
	
	if body is CharacterBody2D:		
		if type == 0:
			body.change_stat("STR",nodes)
		elif type == 1:
			body.change_stat("CON",nodes)
		elif type == 2:
			body.change_stat("DEX",nodes)
		elif type == 3:
			start_heal_timer()
		elif type == 4:
			body.change_stat("INT",nodes)
		elif type == 5:
			body.change_stat("WIS",nodes)		
		
		char_aura.from_crystal = self
		char_aura.emitting = true
		char_aura.modulate = BLOOD_COLOR
		
func start_heal_timer():
	var heal_node = char_aura.get_node("HealTimer")
	heal_node.call_deferred("start")

func _on_expiry_timer_timeout() -> void:
	call_deferred("queue_free")
