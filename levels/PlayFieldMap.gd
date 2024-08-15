extends TileMap

const IV = 999 # Ignore value for processing geomatrix
const AV = 998 # Match any value other than 0 for processing geomatrix

@onready var perlinNode = $PerlinGraph
@onready var playerNode = get_node("../Player")
@onready var collisionNode = get_node("../Player/CollisionShape2D")

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
	flood_fill(testMatrix,pickPlayerSpawn(),0,255);
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
		
	if (n == AV && geoMatrix[x][SafeIndex(Vector2i(x,y-1)).y] != 0):
		pass	
	elif (n != IV && geoMatrix[x][SafeIndex(Vector2i(x,y-1)).y] != n):
		return false
	
	if (ne == AV && geoMatrix[SafeIndex(Vector2i(x+1,y-1)).x][SafeIndex(Vector2i(x+1,y-1)).y] != 0):
		pass
	elif (ne != IV && geoMatrix[SafeIndex(Vector2i(x+1,y-1)).x][SafeIndex(Vector2i(x+1,y-1)).y] != ne):
		return false
	
	if (e == AV && geoMatrix[SafeIndex(Vector2i(x+1,y)).x][y] != 0):
		pass
	elif (e != IV && geoMatrix[SafeIndex(Vector2i(x+1,y)).x][y] != e):
		return false
	
	if (se == AV && geoMatrix[SafeIndex(Vector2i(x+1,y+1)).x][SafeIndex(Vector2i(x+1,y+1)).y] != 0):
		pass
	elif (se != IV && geoMatrix[SafeIndex(Vector2i(x+1,y+1)).x][SafeIndex(Vector2i(x+1,y+1)).y] != se):
		return false
	
	if (s == AV && geoMatrix[x][SafeIndex(Vector2i(x,y+1)).y] != 0):
		pass
	elif (s != IV && geoMatrix[x][SafeIndex(Vector2i(x,y+1)).y] != s):
		return false
	
	if (sw == AV && geoMatrix[SafeIndex(Vector2i(x-1,y+1)).x][SafeIndex(Vector2i(x-1,y+1)).y] != 0):
		pass
	elif (sw != IV && geoMatrix[SafeIndex(Vector2i(x-1,y+1)).x][SafeIndex(Vector2i(x-1,y+1)).y] != sw):
		return false
	
	if (w == AV && geoMatrix[SafeIndex(Vector2i(x-1,y)).x][y] != 0):
		pass
	elif (w != IV && geoMatrix[SafeIndex(Vector2i(x-1,y)).x][y] != w):
		return false
	
	if (nw == AV && geoMatrix[SafeIndex(Vector2i(x-1,y-1)).x][SafeIndex(Vector2i(x-1,y-1)).y] != 0):
		pass
	elif (nw != IV && geoMatrix[SafeIndex(Vector2i(x-1,y-1)).x][SafeIndex(Vector2i(x-1,y-1)).y] != nw):
		return false	
	
	return true
	
func flood_fill(matrix, start_pos: Vector2i, target_value, replacement_value):
	# Check if the target value is the same as the replacement value
	if target_value == replacement_value:
		return

	# Check if start position is within the bounds of the matrix
	if start_pos.x < 0 or start_pos.x >= matrix.size() or start_pos.y < 0 or start_pos.y >= matrix[0].size():
		return

	# Create a stack for positions to visit
	var stack = [start_pos]

	while stack.size() > 0:
		var pos = stack.pop_back()
				
		# Make index positions safe
		var adj_index: Vector2i = SafeIndex(Vector2i(pos.x, pos.y))
		
		# Get the current value at the position
		var current_value = matrix[adj_index.x][adj_index.y]

		# If the current value is not the target value, continue
		if current_value != target_value:
			continue

		# Replace the value at the current position		
		matrix[adj_index.x][adj_index.y] = replacement_value

		# Push neighboring positions to the stack
		stack.append(Vector2i(pos.x + 1, pos.y))
		stack.append(Vector2i(pos.x - 1, pos.y))
		stack.append(Vector2i(pos.x, pos.y + 1))
		stack.append(Vector2i(pos.x, pos.y - 1))

func SafeIndex(index : Vector2i) -> Vector2i:
	var x = index.x % Globals.WIDTH
	var y = index.y % Globals.HEIGHT
	return Vector2i(x,y)	
			
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
	
func displayPreview():
	var perlinImage: Image = Image.create(Globals.WIDTH, Globals.HEIGHT, false, Image.FORMAT_RGBA8)
	var previewNode = $levelPreview
	previewNode.texture = ImageTexture.create_from_image(perlinImage)	
		
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			var gValue = geoMatrix[x][y]
			# Values
			if (gValue == 1):
				gValue = 255
			elif (gValue == 2 || gValue == 3 || gValue == 4 || gValue == 5):
				gValue = 128
			else:
				gValue = 0
			
			var curColor = Color(gValue, gValue, gValue, 1)
			perlinImage.set_pixel(x,y,curColor)	
			
	var pX = spawnLoc.x
	var pY = spawnLoc.y
	var R = 5
	
	for x in range(pX-R, pX+R):
		for y in range(pY-R, pY+R):
			perlinImage.set_pixel(x, y, Color.RED)	
	
	previewNode.texture.update(perlinImage)
	
func I82F(intNum : int) -> float:
	return intNum / 255.0
	
func pickPlayerSpawn() -> Vector2i:
	var found: bool = false
	var spawnDist = 40
	var curX: int
	var curY: int
	
	while !found:
		curX = randi_range(0,Globals.WIDTH)
		curY = randi_range(0,Globals.HEIGHT)
		found = raycastCardinal(curX, curY, spawnDist)		
	
	return Vector2i(curX, curY)	

func raycastCardinal(x: int, y: int, minDist: int) -> bool:
	return raycastUp(x, y, minDist) && raycastDown(x, y, minDist) && raycastLeft(x, y, minDist) && raycastRight(x, y, minDist)
		
func raycastUp(x: int, y: int, minDist: int) -> bool:
	for yi in range(y-1, y-minDist, -1):
		var xs = SafeIndex(Vector2i(x,yi)).x
		var yis = SafeIndex(Vector2i(x,yi)).y
		if (geoMatrix[xs][yis] == 1):
			return false
	return true	
	
func raycastDown(x: int, y: int, minDist: int) -> bool:
	for yi in range(y+1, y+minDist, 1):
		var xs = SafeIndex(Vector2i(x,yi)).x
		var yis = SafeIndex(Vector2i(x,yi)).y
		if (geoMatrix[xs][yis] == 1):
			return false
	return true	
	
func raycastLeft(x: int, y: int, minDist: int) -> bool:
	for xi in range(x-1, x-minDist, -1):
		var xis = SafeIndex(Vector2i(xi,y)).x
		var ys = SafeIndex(Vector2i(xi,y)).y
		if (geoMatrix[xis][ys] == 1):
			return false
	return true	
	
func raycastRight(x: int, y: int, minDist: int) -> bool:
	for xi in range(x+1, x+minDist, 1):
		var xis = SafeIndex(Vector2i(xi,y)).x
		var ys = SafeIndex(Vector2i(xi,y)).y
		if (geoMatrix[xis][ys] == 1):
			return false
	return true	
	
func respawn():
	collisionNode.set_deferred("disabled", true)
	playerNode.position = spawnLoc * 16	
	
func generateSpawn():	
	var previewNode = $levelPreview
	spawnLoc = pickPlayerSpawn()
	print("Spawn Location: ", spawnLoc)	
	var adjSpawnLoc = spawnLoc * 16
	print("Adjusted Spawn: ", adjSpawnLoc)
		
	collisionNode.set_deferred("disabled", true)
	playerNode.position = adjSpawnLoc
	
	previewNode.position = adjSpawnLoc
	previewNode.position.x -= 150	
	
	for xi in range(spawnLoc.x-5, spawnLoc.x+5):
		set_cell(0, Vector2i(xi, spawnLoc.y+22), 1, Vector2i(0,0), 0)	

func tileMapToImage(tilemap: TileMap) -> ViewportTexture:
	var viewport = SubViewport.new()
	viewport.size = Vector2i(Globals.WIDTH * 16, Globals.HEIGHT * 16)
	var holder = Node2D.new()
	holder.position = tilemap.position
	viewport.add_child(tilemap)		
	return viewport.get_texture()	
	
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
	
func invertMonoColor(value: int) -> Color:
	value = 255 - value
	return Color8(value, value, value)
		
func set_rear_bg():	
	var bgImage: Image = Image.create(Globals.WIDTH, Globals.HEIGHT, false, Image.FORMAT_RGBA8)	
	var bgNode: TextureRect = $Background/Parallax3/Layer3		
	
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			var pValue: int = perlinMatrix[x][y]
			var curColor: Color = invertMonoColor(pValue)
			bgImage.set_pixel(x,y,curColor)	
			
	bgImage.resize(Globals.WIDTH * 16, Globals.HEIGHT * 16, Image.INTERPOLATE_LANCZOS)	
	bgImage.adjust_bcs(1.8,1,1)
	bgNode.texture = ImageTexture.create_from_image(bgImage)	
	
func debug_level():
	for x in Globals.WIDTH:
		for y in range(255, 285):
			geoMatrix[x][y] = 1	
	setPlayFieldMap(self, 1,0,0)
	
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
		print("Generating preview...")
		displayPreview()
		print("Generating background...")	
		set_background(10, 0.7, $Background/Parallax1/Layer1,get_node("../BGViewContainer/BGViewport1/BackgroundMap1"),get_node("../BGViewContainer/BGViewport1"))	
		set_background(20, 0.5, $Background/Parallax2/Layer2,get_node("../BGViewContainer/BGViewport2/BackgroundMap2"),get_node("../BGViewContainer/BGViewport2"))	
	set_rear_bg()
	
	print("PlayField ready.")

func checkPlayerLoc():
	collisionNode.set_deferred("disabled", false)
	var locX = playerNode.position.x
	var locY = playerNode.position.y	
	# Wrap around teleports
	if (locX > Globals.WIDTH * 16):
		playerNode.position.x = 0
	elif (locX < 0):
		playerNode.position.x = Globals.WIDTH * 16
	elif (locY > Globals.HEIGHT * 16):
		playerNode.position.y = 0
	elif (locY < 0):
		playerNode.position.y = Globals.HEIGHT * 16
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	pass
