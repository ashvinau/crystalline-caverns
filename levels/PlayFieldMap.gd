extends TileMap

const IV = 999 # Ignore value for processing geomatrix
const AV = 998 # Match any value other than 0 for processing geomatrix

@onready var perlinNode = $PerlinGraph
@onready var play_field = get_node("..")
@onready var hud = get_node("../../../../HUD")
var playerNode: CharacterBody2D

var player_scene = preload("res://character/player.tscn")
var hud_scene = preload("res://hud.tscn")

var perlinMatrix : Array = []
var geoMatrix : Array = []
var spawnLoc: Vector2i

# Called when the node enters the scene tree for the first time.
func _init():	
	seed(Globals.RAND_SEED)	
		
	# Initialize perlin matrix	
	for x in Globals.WIDTH:
		perlinMatrix.append([])
		for y in Globals.HEIGHT:
			perlinMatrix[x].append(0)
	# Copy perlin matrix for modification		
	geoMatrix = perlinMatrix.duplicate(true)
			
func setGeoMatrix(clamp: int):	
	var invalid: int = 0
	
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			if (perlinMatrix[x][y] <= clamp):
				geoMatrix[x][y] = 1 # Solid square tile	
				
	# Test validity of generated geomatrix
	var testMatrix = geoMatrix.duplicate(true)	
	# Fill empty space starting at the spawn point		
	Globals.flood_fill(testMatrix,Globals.pickPlayerSpawn(geoMatrix),0,255);
	# Check for remaining 0 values
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			if (testMatrix[x][y] == 0):				
				invalid += 1
	
	print(invalid," invalid with clamp ", clamp, ".")	
	
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			# Fill in single block potholes
			if (checkGeoIndex(Vector2i(x,y),0,IV,IV,1,IV,IV,IV,1,IV)):
				geoMatrix[x][y] = 1
			elif (checkGeoIndex(Vector2i(x,y),0,1,IV,IV,IV,1,IV,IV,IV)):
				geoMatrix[x][y] = 1
			# Remove single block protrusions
			elif (checkGeoIndex(Vector2i(x,y),1,IV,IV,0,IV,IV,IV,0,IV)):
				geoMatrix[x][y] = 0
			elif (checkGeoIndex(Vector2i(x,y),1,0,IV,IV,IV,0,IV,IV,IV)):
				geoMatrix[x][y] = 0
			
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			# inner corners
			# Adding block id 2, lower right triangle
			if (checkGeoIndex(Vector2i(x,y),0,IV,IV,1,1,1,IV,IV,IV)):
				geoMatrix[x][y] = 2
			# Adding block id 3, lower left triangle
			elif (checkGeoIndex(Vector2i(x,y),0,IV,IV,IV,IV,1,1,1,IV)):
				geoMatrix[x][y] = 3
			# Adding block id 4, upper left triangle
			elif (checkGeoIndex(Vector2i(x,y),0,1,IV,IV,IV,IV,IV,1,1)):
				geoMatrix[x][y] = 4
			# Adding block id 5, upper right triangle
			elif (checkGeoIndex(Vector2i(x,y),0,1,1,1,IV,IV,IV,IV,IV)):
				geoMatrix[x][y] = 5
	
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:	
			# outer corners
			# Adding block id 2, lower right triangle
			if (checkGeoIndex(Vector2i(x,y),1,0,IV,IV,IV,IV,IV,0,0)):
				geoMatrix[x][y] = 2
			# Adding block id 3, lower left triangle
			elif (checkGeoIndex(Vector2i(x,y),1,0,0,0,IV,IV,IV,IV,IV)):
				geoMatrix[x][y] = 3
			# Adding block id 4, upper left triangle
			elif (checkGeoIndex(Vector2i(x,y),1,IV,IV,0,0,0,IV,IV,IV)):
				geoMatrix[x][y] = 4
			# Adding block id 5, upper right triangle
			elif (checkGeoIndex(Vector2i(x,y),1,IV,IV,IV,IV,0,0,0,IV)):
				geoMatrix[x][y] = 5
				
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			# Flat decoratives
			# Adding block id 6, top
			if (checkGeoIndex(Vector2i(x,y),0,1,IV,IV,IV,IV,IV,IV,IV)):
				geoMatrix[x][y] = 6
			# Adding block id 7, bottom
			elif (checkGeoIndex(Vector2i(x,y),0,IV,IV,IV,IV,1,IV,IV,IV)):
				geoMatrix[x][y] = 7
			# Adding block id 8, left
			elif (checkGeoIndex(Vector2i(x,y),0,IV,IV,IV,IV,IV,IV,1,IV)):
				geoMatrix[x][y] = 8
			# Adding block id 9, right
			elif (checkGeoIndex(Vector2i(x,y),0,IV,IV,1,IV,IV,IV,IV,IV)):
				geoMatrix[x][y] = 9
				
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			# corner decoratives
			# Adding block id 10, LR
			if (checkGeoIndex(Vector2i(x,y),0,IV,IV,AV,1,AV,IV,IV,IV)):
				geoMatrix[x][y] = 10
			# Adding block id 11, LL
			elif (checkGeoIndex(Vector2i(x,y),0,IV,IV,IV,IV,AV,1,AV,IV)):
				geoMatrix[x][y] = 11
			# Adding block id 12, UR
			elif (checkGeoIndex(Vector2i(x,y),0,AV,1,AV,IV,IV,IV,IV,IV)):
				geoMatrix[x][y] = 12
			# Adding block id 13, UL
			elif (checkGeoIndex(Vector2i(x,y),0,AV,IV,IV,IV,IV,IV,AV,1)):
				geoMatrix[x][y] = 13

func checkGeoIndex(index : Vector2i, target, n, ne, e, se, s, sw, w, nw) -> bool:	
	var x = index.x
	var y = index.y
	
	if geoMatrix[x][y] != target:
		return false
		
	if (n == AV && geoMatrix[x][Globals.SafeIndex(Vector2i(x,y-1)).y] != 0):
		pass	
	elif (n != IV && geoMatrix[x][Globals.SafeIndex(Vector2i(x,y-1)).y] != n):
		return false
	
	if (ne == AV && geoMatrix[Globals.SafeIndex(Vector2i(x+1,y-1)).x][Globals.SafeIndex(Vector2i(x+1,y-1)).y] != 0):
		pass
	elif (ne != IV && geoMatrix[Globals.SafeIndex(Vector2i(x+1,y-1)).x][Globals.SafeIndex(Vector2i(x+1,y-1)).y] != ne):
		return false
	
	if (e == AV && geoMatrix[Globals.SafeIndex(Vector2i(x+1,y)).x][y] != 0):
		pass
	elif (e != IV && geoMatrix[Globals.SafeIndex(Vector2i(x+1,y)).x][y] != e):
		return false
	
	if (se == AV && geoMatrix[Globals.SafeIndex(Vector2i(x+1,y+1)).x][Globals.SafeIndex(Vector2i(x+1,y+1)).y] != 0):
		pass
	elif (se != IV && geoMatrix[Globals.SafeIndex(Vector2i(x+1,y+1)).x][Globals.SafeIndex(Vector2i(x+1,y+1)).y] != se):
		return false
	
	if (s == AV && geoMatrix[x][Globals.SafeIndex(Vector2i(x,y+1)).y] != 0):
		pass
	elif (s != IV && geoMatrix[x][Globals.SafeIndex(Vector2i(x,y+1)).y] != s):
		return false
	
	if (sw == AV && geoMatrix[Globals.SafeIndex(Vector2i(x-1,y+1)).x][Globals.SafeIndex(Vector2i(x-1,y+1)).y] != 0):
		pass
	elif (sw != IV && geoMatrix[Globals.SafeIndex(Vector2i(x-1,y+1)).x][Globals.SafeIndex(Vector2i(x-1,y+1)).y] != sw):
		return false
	
	if (w == AV && geoMatrix[Globals.SafeIndex(Vector2i(x-1,y)).x][y] != 0):
		pass
	elif (w != IV && geoMatrix[Globals.SafeIndex(Vector2i(x-1,y)).x][y] != w):
		return false
	
	if (nw == AV && geoMatrix[Globals.SafeIndex(Vector2i(x-1,y-1)).x][Globals.SafeIndex(Vector2i(x-1,y-1)).y] != 0):
		pass
	elif (nw != IV && geoMatrix[Globals.SafeIndex(Vector2i(x-1,y-1)).x][Globals.SafeIndex(Vector2i(x-1,y-1)).y] != nw):
		return false	
	
	return true
	
func setPlayFieldMap(curMap: TileMap, source, offsetX, offsetY):
		for x in Globals.WIDTH:
			for y in Globals.HEIGHT:
				if (geoMatrix[x][y] == 1): # Solid block
					var randY = randi_range(0,1)
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(0,randY), 0)	
				elif (geoMatrix[x][y] == 2): # LR triangle
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(1,0), 0)
				elif (geoMatrix[x][y] == 3): # LL triangle
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(2,0), 0)
				elif (geoMatrix[x][y] == 4): # UL triangle
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(4,0), 0)
				elif (geoMatrix[x][y] == 5): # UR triangle
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(3,0), 0)
				elif (geoMatrix[x][y] == 6): # top
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(1,1), 0)
				elif (geoMatrix[x][y] == 7): # bottom
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(2,1), 0)
				elif (geoMatrix[x][y] == 8): # left
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(3,1), 0)
				elif (geoMatrix[x][y] == 9): # right
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(4,1), 0)
				elif (geoMatrix[x][y] == 10): # LR
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(0,2), 0)
				elif (geoMatrix[x][y] == 11): # LL
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(1,2), 0)
				elif (geoMatrix[x][y] == 12): # UR
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(2,2), 0)
				elif (geoMatrix[x][y] == 13): # UL
					curMap.set_cell(0, Vector2i(x+offsetX,y+offsetY), source, Vector2i(3,2), 0)
			
func fillPerlinMatrix(matrix):
	perlinNode.CPerlinGraph(Globals.WIDTH, Globals.HEIGHT, Globals.RAND_SEED, 0.1, 2, 6, 0.4)
	var flatPerlinMatrix = perlinNode.getPerlinMatrix()		
	var curIndex = 0;
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:			
			matrix[x][y] = flatPerlinMatrix[curIndex]
			curIndex += 1
	print("Debug indexes: ", curIndex)
	
func respawn():
	playerNode.queue_free()
	spawn_character(spawnLoc * 16, Globals.player_color)
	
func generateSpawn():	
	print("Building Spawn Point...")	
	spawnLoc = Globals.pickPlayerSpawn(geoMatrix)
	print("Spawn Location: ", spawnLoc)	
	var adjSpawnLoc = spawnLoc * 16
	print("Adjusted Spawn: ", adjSpawnLoc)
	#Build spawn
	for xi in range(spawnLoc.x-5, spawnLoc.x+5):
		set_cell(0, Globals.SafeIndex(Vector2i(xi, spawnLoc.y+22)), 1, Vector2i(0,0), 0)	
	
	spawn_character(adjSpawnLoc, Globals.player_color)	

func set_background(pOffset: int, darken: float, layerNode: TextureRect, bgMap: TileMap, bgViewport: SubViewport):
	setGeoMatrix(Globals.CLAMP + pOffset)		
	var bgImage: Image = Image.create(Globals.WIDTH * 16, Globals.HEIGHT * 16, false, Image.FORMAT_RGBA8)	
	setPlayFieldMap(bgMap, 0,  0, 0)	
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
			var pValue: int = perlinMatrix[x][y]
			var curColor: Color = Globals.invertMonoColor(pValue)
			bgImage.set_pixel(x,y,curColor)	
			
	bgImage.resize(Globals.WIDTH * 16, Globals.HEIGHT * 16, Image.INTERPOLATE_LANCZOS)	
	bgImage.adjust_bcs(1.8,1,1)
	bgNode.texture = ImageTexture.create_from_image(bgImage)	
	
func debug_level():
	for x in Globals.WIDTH:
		for y in range(255, 285):
			geoMatrix[x][y] = 1	
	setPlayFieldMap(self, 1,0,0)
	
func spawn_character(position: Vector2i, color: Color):	
	playerNode = player_scene.instantiate()
	playerNode.position = position	
	play_field.add_child.call_deferred(playerNode)
	playerNode.set_player(color)	
	
func _ready():
	if (Globals.RAND_SEED == 42):
		print("Debug seed mode.")
		print("Generating perlin matrix...")
		fillPerlinMatrix(perlinMatrix)
		print("Generating test level...")
		debug_level()
		print("Generating player spawn...")
		generateSpawn()	
	else:	
		print("Generating perlin matrix...")
		fillPerlinMatrix(perlinMatrix)
		print("Setting geo matrix...")
		setGeoMatrix(Globals.CLAMP)
		print("Setting PlayField TileMap...")
		setPlayFieldMap(self, 1, 0,0)	
		print("Generating player spawn...")
		generateSpawn()	
		print("Generating backgrounds...")	
		set_background(10, 0.7, $Background/Parallax1/Layer1,get_node("../BGViewContainer/BGViewport1/BackgroundMap1"),get_node("../BGViewContainer/BGViewport1"))	
		set_background(20, 0.5, $Background/Parallax2/Layer2,get_node("../BGViewContainer/BGViewport2/BackgroundMap2"),get_node("../BGViewContainer/BGViewport2"))	
	set_rear_bg()
	print("Generating preview...")		
	hud.displayPreview(geoMatrix, spawnLoc)
	print("PlayField ready.")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	pass
