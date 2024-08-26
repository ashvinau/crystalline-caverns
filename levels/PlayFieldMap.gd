extends TileMap

const IV = 999 # Ignore value for processing geo_matrix
const AV = 998 # Match any value other than 0 for processing geo_matrix

@onready var perlin_node = $PerlinGraph
@onready var play_field = get_node("..")
@onready var hud = get_node("../../../../HUD")

var hud_scene = preload("res://hud.tscn")
var player_nodes: Array = []
var players: Array = []
var bosses: Array = []
var enemies: Array = []
var perlin_matrix: Array = []
var geo_matrix: Array = []
var spawn_loc: Vector2i

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
	enemies.append(preload("res://enemies/formless_crawler.tscn"))
			
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
		Globals.flood_fill(testMatrix,Globals.pick_spawn(geo_matrix,40),0,255);
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
	
func debug_level():
	for x in Globals.WIDTH:
		for y in range(255, 285):
			geo_matrix[x][y] = 1	
	set_playfield_map(self, 1,0,0)
	
func spawn_entity(entity: PackedScene, position: Vector2i) -> CharacterBody2D:		
	var entity_node = entity.instantiate()
	entity_node.position = position	
	play_field.add_child.call_deferred(entity_node)	
	return entity_node
	
func _ready():
	if (Globals.RAND_SEED == 42): # Debug/Test Level
		print("Debug seed mode.")
		print("Generating perlin matrix...")
		fill_perlin_matrix(perlin_matrix)
		print("Generating test level...")
		debug_level()
		print("Generating player spawn...")
		generate_spawn()
		print("Generating preview...")
		hud.display_preview(geo_matrix, spawn_loc)		
	else:	# Procgen level
		print("Generating perlin matrix...")
		fill_perlin_matrix(perlin_matrix)
		print("Setting geo matrix...")
		set_geo_matrix(Globals.CLAMP, true)
		print("Setting PlayField TileMap...")
		set_playfield_map(self, 1, 0,0)	
		print("Generating player spawn...")
		generate_spawn()	
		print("Generating preview...")
		hud.display_preview(geo_matrix, spawn_loc)
		print("Generating backgrounds...")	
		set_background(10, 0.7, $Background/Parallax1/Layer1,get_node("../BGViewContainer/BGViewport1/BackgroundMap1"),get_node("../BGViewContainer/BGViewport1"))	
		set_background(20, 0.5, $Background/Parallax2/Layer2,get_node("../BGViewContainer/BGViewport2/BackgroundMap2"),get_node("../BGViewContainer/BGViewport2"))	
	set_rear_bg()
	
	print("Test enemies...")
	var enemy_node = spawn_entity(enemies[0], Vector2i(player_nodes[0].position.x + 300,player_nodes[0].position.y))
	enemy_node.set_mob(player_nodes,Color.LAWN_GREEN,5,5,5,5,5)
	
	print("PlayField ready.")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	pass
