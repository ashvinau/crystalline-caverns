extends TileMap

signal navigation_map_complete

const BLOOD_COLOR: Color = Color.DARK_GRAY
const IV = 999 # Ignore value for processing geo_matrix
const AV = 998 # Match any value other than 0 for processing geo_matrix

@onready var perlin_node = $PerlinGraph
@onready var play_field = get_node("..")
@onready var hud = get_node("../../../../HUD")
@onready var crystal_scene = preload("res://levels/crystal.tscn")

var hud_scene = preload("res://hud.tscn")
var players: Array = []
var player_nodes: Array = []
var boss_nodes: Array = []
var bosses: Array = []
var perlin_matrix: Array = []
var geo_matrix: Array = []
var unmodified_geo_matrix: Array = []
var spawn_loc: Vector2i
var crystals: Array = []

func save_boss_map():
	Globals.save_map_file(boss_nodes[0].mob_geo_matrix, "boss_nav_map.csv")	
	#Globals.save_map_file(crystals[0].cry_geo_matrix, "crystal_nav_map.csv")

# Called when the node enters the scene tree for the first time.
func _init():	
	seed(Globals.RAND_SEED)	
		
	# Initialize perlin matrix	
	for x in Globals.WIDTH:
		perlin_matrix.append([])
		for y in Globals.HEIGHT:
			perlin_matrix[x].append(0)
	# Copy perlin matrix for modification		
	geo_matrix = perlin_matrix.duplicate(true)
	
	#Load entities into memory		
	players.append(preload("res://character/player.tscn"))
	bosses.append(preload("res://enemies/fungus_lord.tscn"))
	
func set_geo_matrix(clamp: int, test: bool):	
	var invalid: int = 0
	
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			if (perlin_matrix[x][y] <= clamp):
				geo_matrix[x][y] = 1 # Solid square tile
	
	if test:
		# Test validity of initial geo_matrix if requested - rejection logic later
		var testMatrix = geo_matrix.duplicate(true)
		# Fill empty space starting at the spawn point
		flood_fill(testMatrix,Globals.pick_spawn(testMatrix,40),255,false,false);
		# Check for remaining 0 values
		for x in Globals.WIDTH:
			for y in Globals.HEIGHT:
				if (testMatrix[x][y] == 0):
					invalid += 1
		
		print(invalid," invalid with clamp ", clamp, ".")			
	
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			# Fill in single block potholes
			if (check_geo_index(Vector2i(x,y),0,IV,IV,1,IV,IV,IV,1,IV)):
				geo_matrix[x][y] = 1
			elif (check_geo_index(Vector2i(x,y),0,1,IV,IV,IV,1,IV,IV,IV)):
				geo_matrix[x][y] = 1
			# Remove single block protrusions
			elif (check_geo_index(Vector2i(x,y),1,IV,IV,0,IV,IV,IV,0,IV)):
				geo_matrix[x][y] = 0
			elif (check_geo_index(Vector2i(x,y),1,0,IV,IV,IV,0,IV,IV,IV)):
				geo_matrix[x][y] = 0
			
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			# inner corners
			# Adding block id 2, lower right triangle
			if (check_geo_index(Vector2i(x,y),0,IV,IV,1,1,1,IV,IV,IV)):
				geo_matrix[x][y] = 2
			# Adding block id 3, lower left triangle
			elif (check_geo_index(Vector2i(x,y),0,IV,IV,IV,IV,1,1,1,IV)):
				geo_matrix[x][y] = 3
			# Adding block id 4, upper left triangle
			elif (check_geo_index(Vector2i(x,y),0,1,IV,IV,IV,IV,IV,1,1)):
				geo_matrix[x][y] = 4
			# Adding block id 5, upper right triangle
			elif (check_geo_index(Vector2i(x,y),0,1,1,1,IV,IV,IV,IV,IV)):
				geo_matrix[x][y] = 5
	
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:	
			# outer corners
			# Adding block id 2, lower right triangle
			if (check_geo_index(Vector2i(x,y),1,0,IV,IV,IV,IV,IV,0,0)):
				geo_matrix[x][y] = 2
			# Adding block id 3, lower left triangle
			elif (check_geo_index(Vector2i(x,y),1,0,0,0,IV,IV,IV,IV,IV)):
				geo_matrix[x][y] = 3
			# Adding block id 4, upper left triangle
			elif (check_geo_index(Vector2i(x,y),1,IV,IV,0,0,0,IV,IV,IV)):
				geo_matrix[x][y] = 4
			# Adding block id 5, upper right triangle
			elif (check_geo_index(Vector2i(x,y),1,IV,IV,IV,IV,0,0,0,IV)):
				geo_matrix[x][y] = 5
				
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			# Flat decoratives
			# Adding block id 6, top
			if (check_geo_index(Vector2i(x,y),0,1,IV,IV,IV,IV,IV,IV,IV)):
				geo_matrix[x][y] = 6
			# Adding block id 7, bottom
			elif (check_geo_index(Vector2i(x,y),0,IV,IV,IV,IV,1,IV,IV,IV)):
				geo_matrix[x][y] = 7
			# Adding block id 8, left
			elif (check_geo_index(Vector2i(x,y),0,IV,IV,IV,IV,IV,IV,1,IV)):
				geo_matrix[x][y] = 8
			# Adding block id 9, right
			elif (check_geo_index(Vector2i(x,y),0,IV,IV,1,IV,IV,IV,IV,IV)):
				geo_matrix[x][y] = 9
				
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			# corner decoratives
			# Adding block id 10, LR
			if (check_geo_index(Vector2i(x,y),0,IV,IV,AV,1,AV,IV,IV,IV)):
				geo_matrix[x][y] = 10
			# Adding block id 11, LL
			elif (check_geo_index(Vector2i(x,y),0,IV,IV,IV,IV,AV,1,AV,IV)):
				geo_matrix[x][y] = 11
			# Adding block id 12, UR
			elif (check_geo_index(Vector2i(x,y),0,AV,1,AV,IV,IV,IV,IV,IV)):
				geo_matrix[x][y] = 12
			# Adding block id 13, UL
			elif (check_geo_index(Vector2i(x,y),0,AV,IV,IV,IV,IV,IV,AV,1)):
				geo_matrix[x][y] = 13

func check_geo_index(index : Vector2i, target, n, ne, e, se, s, sw, w, nw) -> bool:	
	var x = index.x
	var y = index.y
	
	if geo_matrix[x][y] != target:
		return false
		
	if (n == AV && geo_matrix[x][Globals.safe_index(Vector2i(x,y-1)).y] != 0):
		pass	
	elif (n != IV && geo_matrix[x][Globals.safe_index(Vector2i(x,y-1)).y] != n):
		return false
	
	if (ne == AV && geo_matrix[Globals.safe_index(Vector2i(x+1,y-1)).x][Globals.safe_index(Vector2i(x+1,y-1)).y] != 0):
		pass
	elif (ne != IV && geo_matrix[Globals.safe_index(Vector2i(x+1,y-1)).x][Globals.safe_index(Vector2i(x+1,y-1)).y] != ne):
		return false
	
	if (e == AV && geo_matrix[Globals.safe_index(Vector2i(x+1,y)).x][y] != 0):
		pass
	elif (e != IV && geo_matrix[Globals.safe_index(Vector2i(x+1,y)).x][y] != e):
		return false
	
	if (se == AV && geo_matrix[Globals.safe_index(Vector2i(x+1,y+1)).x][Globals.safe_index(Vector2i(x+1,y+1)).y] != 0):
		pass
	elif (se != IV && geo_matrix[Globals.safe_index(Vector2i(x+1,y+1)).x][Globals.safe_index(Vector2i(x+1,y+1)).y] != se):
		return false
	
	if (s == AV && geo_matrix[x][Globals.safe_index(Vector2i(x,y+1)).y] != 0):
		pass
	elif (s != IV && geo_matrix[x][Globals.safe_index(Vector2i(x,y+1)).y] != s):
		return false
	
	if (sw == AV && geo_matrix[Globals.safe_index(Vector2i(x-1,y+1)).x][Globals.safe_index(Vector2i(x-1,y+1)).y] != 0):
		pass
	elif (sw != IV && geo_matrix[Globals.safe_index(Vector2i(x-1,y+1)).x][Globals.safe_index(Vector2i(x-1,y+1)).y] != sw):
		return false
	
	if (w == AV && geo_matrix[Globals.safe_index(Vector2i(x-1,y)).x][y] != 0):
		pass
	elif (w != IV && geo_matrix[Globals.safe_index(Vector2i(x-1,y)).x][y] != w):
		return false
	
	if (nw == AV && geo_matrix[Globals.safe_index(Vector2i(x-1,y-1)).x][Globals.safe_index(Vector2i(x-1,y-1)).y] != 0):
		pass
	elif (nw != IV && geo_matrix[Globals.safe_index(Vector2i(x-1,y-1)).x][Globals.safe_index(Vector2i(x-1,y-1)).y] != nw):
		return false	
	
	return true
	
func set_playfield_map(curMap: TileMap, source, offsetX, offsetY):
		for x in Globals.WIDTH:
			for y in Globals.HEIGHT:
				if (geo_matrix[x][y] == 1): # Solid block
					var randY = randi_range(0,1)
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(0,randY), 0)	
				elif (geo_matrix[x][y] == 2): # LR triangle
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(1,0), 0)
				elif (geo_matrix[x][y] == 3): # LL triangle
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(2,0), 0)
				elif (geo_matrix[x][y] == 4): # UL triangle
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(4,0), 0)
				elif (geo_matrix[x][y] == 5): # UR triangle
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(3,0), 0)
				elif (geo_matrix[x][y] == 6): # top
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(1,1), 0)
				elif (geo_matrix[x][y] == 7): # bottom
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(2,1), 0)
				elif (geo_matrix[x][y] == 8): # left
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(3,1), 0)
				elif (geo_matrix[x][y] == 9): # right
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(4,1), 0)
				elif (geo_matrix[x][y] == 10): # LR
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(0,2), 0)
				elif (geo_matrix[x][y] == 11): # LL
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(1,2), 0)
				elif (geo_matrix[x][y] == 12): # UR
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(2,2), 0)
				elif (geo_matrix[x][y] == 13): # UL
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(3,2), 0)
			
func fill_perlin_matrix(matrix):
	perlin_node.CPerlinGraph(Globals.WIDTH, Globals.HEIGHT, Globals.RAND_SEED, 0.1, 2, 6, 0.4)
	var flatperlin_matrix = perlin_node.getPerlinMatrix()
	var curIndex = 0;
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:			
			matrix[x][y] = flatperlin_matrix[curIndex]
			curIndex += 1
	print("Debug indexes: ", curIndex)
	
func flood_fill(matrix, start_pos: Vector2i, replacement_value, sniff_map: bool, thread: bool):
	var target_value = matrix[start_pos.x][start_pos.y]
	if sniff_map:
		replacement_value = 1
	
	# Create a stack for positions to visit
	var stack = [start_pos]

	while stack.size() > 0:
		var pos = stack.pop_front()
				
		# Make index positions safe
		var adj_index: Vector2i = Globals.safe_index(Vector2i(pos.x, pos.y))
		
		# Get the current value at the position
		var current_value = matrix[adj_index.x][adj_index.y]

		# If the current value is not the target value, continue
		if current_value != target_value:
			continue

		# Replace the value at the current position		
		matrix[adj_index.x][adj_index.y] = replacement_value

		# Push neighboring positions to the stack
		if (Globals.get_mat_val(matrix, Vector2(pos.x, pos.y - 1)) == target_value):
			stack.append(Globals.safe_index(Vector2i(pos.x, pos.y - 1)))
		if (Globals.get_mat_val(matrix, Vector2(pos.x + 1, pos.y)) == target_value):
			stack.append(Globals.safe_index(Vector2i(pos.x + 1, pos.y)))
		if (Globals.get_mat_val(matrix, Vector2(pos.x, pos.y + 1)) == target_value):
			stack.append(Globals.safe_index(Vector2i(pos.x, pos.y + 1)))
		if (Globals.get_mat_val(matrix, Vector2(pos.x - 1, pos.y)) == target_value):
			stack.append(Globals.safe_index(Vector2i(pos.x - 1, pos.y)))
			
		if sniff_map:
			replacement_value += 1
			if thread:
				await boss_nodes[0].process_more_nav_map
		
	if thread:
		navigation_map_complete.emit()	
	
func respawn():
	player_nodes[0].queue_free()
	player_nodes[0] = spawn_entity(players[0], spawn_loc * 16)
	player_nodes[0].set_player(Globals.player_color)
	player_nodes[0].name = "Player"
	Globals.player_health = Globals.player_max_health
	hud.update_hud()
	
func generate_spawn():	
	print("Building Spawn Point...")
	spawn_loc = Globals.pick_spawn(geo_matrix,40)
	print("Spawn Location: ", spawn_loc)	
	var adj_spawn_loc = spawn_loc * 16
	print("Adjusted Spawn: ", adj_spawn_loc)
	#Build spawn structure
	for xi in range(spawn_loc.x-5, spawn_loc.x+5):
		set_cell(0, Globals.safe_index(Vector2i(xi, spawn_loc.y+22)), 1, Vector2i(0,0), 0)	
	
	player_nodes.append(spawn_entity(players[0], adj_spawn_loc))
	player_nodes[0].set_player(Globals.player_color)
	
func spawn_boss(boss_scene: PackedScene):
	print("Choosing boss spawn...")
	var boss_spawn_loc: Vector2i = Globals.pick_spawn(geo_matrix,40)
	
	var tries: int = 0
	var distance: float = 0
	while distance < 256:
		tries += 1
		boss_spawn_loc = Globals.pick_spawn(geo_matrix,40)
		distance = Globals.toroidal_matrix_dist(Globals.WIDTH,Globals.HEIGHT,spawn_loc,boss_spawn_loc)		
		
	print("Boss spawn location found at ", boss_spawn_loc, " in ", tries, " tries, ", distance, " cells from the player spawn at: ", spawn_loc)
	
	boss_nodes.append(spawn_entity(boss_scene, Vector2i(boss_spawn_loc.x*16,boss_spawn_loc.y*16)))
	boss_nodes[0].set_mob(player_nodes,Color.LAWN_GREEN,3,3,3,3,3)
	boss_nodes[0].process_more_nav_map.connect(_on_process_more_nav)
		
func spawn_entity(entity: PackedScene, e_position: Vector2i):
	var entity_node = entity.instantiate()
	entity_node.position = e_position	
	play_field.add_child.call_deferred(entity_node)
	return entity_node

func set_background(pOffset: int, darken: float, layerNode: TextureRect, bgMap: TileMap, bgViewport: SubViewport):
	set_geo_matrix(Globals.CLAMP + pOffset, false)		
	var bgImage: Image = Image.create(Globals.WIDTH * 16, Globals.HEIGHT * 16, false, Image.FORMAT_RGBA8)	
	set_playfield_map(bgMap, 0,  0, 0)	
	await RenderingServer.frame_post_draw
	bgImage = bgViewport.get_texture().get_image()
	bgImage.adjust_bcs(darken,1,1)
	layerNode.texture = ImageTexture.create_from_image(bgImage)
	bgMap.visible = false
	bgMap.set_deferred("disabled", true)	
	
func set_rear_bg():	
	var bgImage: Image = Image.create(Globals.WIDTH, Globals.HEIGHT, false, Image.FORMAT_RGBA8)	
	var bgNode: TextureRect = $Background/Parallax3/Layer3		
	
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			var pValue: int = perlin_matrix[x][y]
			var curColor: Color = Globals.invert_mono_color(pValue)
			bgImage.set_pixel(x,y,curColor)	
			
	bgImage.resize(Globals.WIDTH * 16, Globals.HEIGHT * 16, Image.INTERPOLATE_LANCZOS)	
	bgImage.adjust_bcs(1.7,1,1)
	bgNode.texture = ImageTexture.create_from_image(bgImage)	

func place_crystals():	
	var edge_offset: int = 75
	var num_crystals: int = randi_range(3,5)
	print("Placing ", num_crystals, " crystals.")
	for i in num_crystals:
		crystals.append(spawn_entity(crystal_scene,Vector2i(0,0)))
		
	for crystal in crystals:		
		var cry_spawn: Vector2i
		var offset_const = crystal.nodes * 30
		var spawn_offset: Vector2i
		var spawn_found: bool
		var tries: int = 0
		while not spawn_found:
			tries += 1			
			var curX = randi_range(edge_offset,Globals.WIDTH-edge_offset)
			var curY = randi_range(edge_offset,Globals.HEIGHT-edge_offset)
			var cur_index: Vector2i = Vector2i(curX,curY)
			if check_geo_index(cur_index,1,6,6,1,1,1,1,1,6): # on the floor, pointed upward
				crystal.set_rotation(randf_range(-PI/6,PI/6))
				cry_spawn = Vector2i(curX,curY)
				spawn_offset = Vector2i(0,-offset_const)
				spawn_found = true
			elif check_geo_index(cur_index,1,1,1,1,7,7,7,1,1): # on the ceiling, pointed downward
				crystal.set_rotation(randf_range(-PI/6,PI/6))
				cry_spawn = Vector2i(curX,curY)
				spawn_offset = Vector2i(0,offset_const)
				spawn_found = true
			elif check_geo_index(cur_index,1,1,8,8,8,1,1,1,1): # on the left wall, pointed rightward
				crystal.set_rotation(randf_range(-PI/6,PI/6)+PI/2)
				cry_spawn = Vector2i(curX,curY)
				spawn_offset = Vector2i(offset_const,0)
				spawn_found = true
			elif check_geo_index(cur_index,1,1,1,1,1,1,9,9,9): # on the right wall, pointed leftward
				crystal.set_rotation(randf_range(-PI/6,PI/6)-PI/2)
				cry_spawn = Vector2i(curX,curY)
				spawn_offset = Vector2i(-offset_const,0)
				spawn_found = true
			
		print("Crystal spawn found in ",tries," tries at: ", cry_spawn)		
		cry_spawn *= 16 # Convert from map to screen space
		cry_spawn.x = cry_spawn.x + spawn_offset.x
		cry_spawn.y = cry_spawn.y + spawn_offset.y
		crystal.set_position(cry_spawn)
		
func debug_level():
	for x in Globals.WIDTH:
		for y in range(255, 285):
			geo_matrix[x][y] = 1	
	set_playfield_map(self, 1,0,0)
	
func _ready():
	if (Globals.RAND_SEED == 42): # Debug/Test Level
		print("Debug seed mode.")
		print("Generating perlin matrix...")
		fill_perlin_matrix(perlin_matrix)
		print("Generating test level...")
		debug_level()
		unmodified_geo_matrix = geo_matrix.duplicate(true)
		print("Generating player spawn...")
		generate_spawn()
		print("Generating preview...")
		hud.display_preview(geo_matrix, spawn_loc)		
		# Test code here	
		
	else:	# Procgen level
		print("Generating perlin matrix...")
		fill_perlin_matrix(perlin_matrix)
		print("Setting geo matrix...")
		set_geo_matrix(Globals.CLAMP, true)
		unmodified_geo_matrix = geo_matrix.duplicate(true)		
		print("Setting PlayField TileMap...")
		set_playfield_map(self, 1, 0,0)	
		print("Generating player spawn...")
		generate_spawn()		
		print("Spawning boss...")		
		spawn_boss(bosses[0])
		print("Spawning crystals...")
		place_crystals()
		print("Generating preview...")
		hud.display_preview(geo_matrix, spawn_loc)
		print("Generating backgrounds...")	
		set_background(10, 0.7, $Background/Parallax1/Layer1,get_node("../BGViewContainer/BGViewport1/BackgroundMap1"),get_node("../BGViewContainer/BGViewport1"))	
		set_background(20, 0.5, $Background/Parallax2/Layer2,get_node("../BGViewContainer/BGViewport2/BackgroundMap2"),get_node("../BGViewContainer/BGViewport2"))
				
	set_rear_bg()	
	print("PlayField ready.")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	pass
	
func _on_process_more_nav():
	pass
