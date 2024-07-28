extends TileMap

const RAND_SEED = 16384
const IGNORE_VAL = 42

@onready var perlinNode = $PerlinGraph
@onready var playerNode = get_node("../Player")
@onready var collisionNode = get_node("../Player/CollisionShape2D")

var perlinMatrix : Array = []
var geoMatrix : Array = []
# Perlin matrix dimensions
var width = 512
var height = 512

var spawnLoc: Vector2i

# Called when the node enters the scene tree for the first time.
func _init():			
	var tile_set = self.tile_set
	seed(RAND_SEED)
		
	# Initialize perlin matrix	
	for x in width:
		perlinMatrix.append([])
		for y in height:
			perlinMatrix[x].append(0)
	# Copy perlin matrix for modification		
	geoMatrix = perlinMatrix.duplicate(true)
			
func setGeoMatrix():
	for x in width:
		for y in height:
			if (perlinMatrix[x][y] <= 130):
				geoMatrix[x][y] = 1 # Solid square tile
	
	for x in width:
		for y in height:
			# Fill in single block potholes
			if (checkGeoIndex(Vector2i(x,y),0,IGNORE_VAL,IGNORE_VAL,1,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,1,IGNORE_VAL)):
				geoMatrix[x][y] = 1
			elif (checkGeoIndex(Vector2i(x,y),0,1,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,1,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL)):
				geoMatrix[x][y] = 1
			# Remove single block protrusions
			elif (checkGeoIndex(Vector2i(x,y),1,IGNORE_VAL,IGNORE_VAL,0,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,0,IGNORE_VAL)):
				geoMatrix[x][y] = 0
			elif (checkGeoIndex(Vector2i(x,y),1,0,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,0,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL)):
				geoMatrix[x][y] = 0
			# Adding block id 2, lower right triangle
			elif (checkGeoIndex(Vector2i(x,y),1,0,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,0,0)):
				geoMatrix[x][y] = 2
			# Adding block id 3, lower left triangle
			elif (checkGeoIndex(Vector2i(x,y),1,0,0,0,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL)):
				geoMatrix[x][y] = 3
			# Adding block id 4, upper left triangle
			elif (checkGeoIndex(Vector2i(x,y),1,IGNORE_VAL,IGNORE_VAL,0,0,0,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL)):
				geoMatrix[x][y] = 4
			# Adding block id 5, upper right triangle
			elif (checkGeoIndex(Vector2i(x,y),1,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,0,0,0,IGNORE_VAL)):
				geoMatrix[x][y] = 5
			# Second pass for inner corners
			# Adding block id 2, lower right triangle
			elif (checkGeoIndex(Vector2i(x,y),0,IGNORE_VAL,IGNORE_VAL,1,1,1,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL)):
				geoMatrix[x][y] = 2
			# Adding block id 3, lower left triangle
			elif (checkGeoIndex(Vector2i(x,y),0,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,1,1,1,IGNORE_VAL)):
				geoMatrix[x][y] = 3
			# Adding block id 4, upper left triangle
			elif (checkGeoIndex(Vector2i(x,y),0,1,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,1,1)):
				geoMatrix[x][y] = 4
			# Adding block id 5, upper right triangle
			elif (checkGeoIndex(Vector2i(x,y),0,1,1,1,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL,IGNORE_VAL)):
				geoMatrix[x][y] = 5
			
			
			

func checkGeoIndex(index : Vector2i, target, n, ne, e, se, s, sw, w, nw) -> bool:	
	var x = index.x
	var y = index.y
	
	if geoMatrix[x][y] != target:
		return false
	if n != IGNORE_VAL && geoMatrix[x][SafeIndex(Vector2i(x,y-1)).y] != n:
		return false
	if ne != IGNORE_VAL && geoMatrix[SafeIndex(Vector2i(x+1,y-1)).x][SafeIndex(Vector2i(x+1,y-1)).y] != ne:
		return false
	if e != IGNORE_VAL && geoMatrix[SafeIndex(Vector2i(x+1,y)).x][y] != e:
		return false
	if se != IGNORE_VAL && geoMatrix[SafeIndex(Vector2i(x+1,y+1)).x][SafeIndex(Vector2i(x+1,y+1)).y] != se:
		return false
	if s != IGNORE_VAL && geoMatrix[x][SafeIndex(Vector2i(x,y+1)).y] != s:
		return false
	if sw != IGNORE_VAL && geoMatrix[SafeIndex(Vector2i(x-1,y+1)).x][SafeIndex(Vector2i(x-1,y+1)).y] != sw:
		return false
	if w != IGNORE_VAL && geoMatrix[SafeIndex(Vector2i(x-1,y)).x][y] != w:
		return false
	if nw != IGNORE_VAL && geoMatrix[SafeIndex(Vector2i(x-1,y-1)).x][SafeIndex(Vector2i(x-1,y-1)).y] != nw:
		return false	
	
	return true
	

func SafeIndex(index : Vector2i) -> Vector2i:
	var x = index.x
	var y = index.y
	
	if (x < 0):
		x = x + width
	elif (x >= width):
		x = x - width
	elif (y < 0):
		y = y + height
	elif (y >= height):
		y = y - height
		
	return Vector2i(x,y)	
			
func setPlayFieldMap(offsetX, offsetY):
		for x in width:
			for y in height:
				if (geoMatrix[x][y] == 1): # Solid block
					set_cell(0, Vector2i(x+offsetX,y+offsetY), 1, Vector2i(0,0), 0)	
				elif (geoMatrix[x][y] == 2): # LR triangle
					set_cell(0, Vector2i(x+offsetX,y+offsetY), 1, Vector2i(1,0), 0)
				elif (geoMatrix[x][y] == 3): # LL triangle
					set_cell(0, Vector2i(x+offsetX,y+offsetY), 1, Vector2i(2,0), 0)
				elif (geoMatrix[x][y] == 4): # UL triangle
					set_cell(0, Vector2i(x+offsetX,y+offsetY), 1, Vector2i(4,0), 0)
				elif (geoMatrix[x][y] == 5): # UR triangle
					set_cell(0, Vector2i(x+offsetX,y+offsetY), 1, Vector2i(3,0), 0)
			
func fillPerlinMatrix():
	perlinNode.CPerlinGraph(width, height, RAND_SEED, 0.1, 2, 6, 0.4)
	var flatPerlinMatrix = perlinNode.getPerlinMatrix()		
	var curIndex = 0;
	for x in width:
		for y in height:			
			perlinMatrix[x][y] = flatPerlinMatrix[curIndex]
			curIndex += 1
	print("Debug indexes: ", curIndex)
	
func displayPreview():
	var perlinImage: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var previewNode = $levelPreview
	previewNode.texture = ImageTexture.create_from_image(perlinImage)	
		
	for x in width:
		for y in height:
			var pValue = I82F(perlinMatrix[x][y])
			# Clamp
			if (pValue <= I82F(130)):
				pValue = 255
			else:
				pValue = 0
			
			var curColor = Color(pValue, pValue, pValue, 1)
			perlinImage.set_pixel(x,y,curColor)	
			
	var pX = spawnLoc.x
	var pY = spawnLoc.y
	var R = 5
	
	for x in range(pX-R, pX+R):
		for y in range(pY-R, pY+R):
			perlinImage.set_pixel(x, y, Color.RED)	
	
	previewNode.texture.update(perlinImage)
	
func I82F(intNum : int):
	return intNum / 255.0
	
func pickPlayerSpawn() -> Vector2i:
	var found: bool = false
	var spawnDist = 30
	var curX: int
	var curY: int
	
	while !found:
		curX = randi_range(0,width)
		curY = randi_range(0,height)
		found = raycastCardinal(curX, curY, spawnDist)		
	
	return Vector2i(curX, curY)	

func raycastCardinal(x: int, y: int, minDist: int) -> bool:
	return raycastUp(x, y, minDist) && raycastDown(x, y, minDist) && raycastLeft(x, y, minDist) && raycastRight(x, y, minDist)
		
func raycastUp(x: int, y: int, minDist: int) -> bool:
	for yi in range(y-1, y-minDist, -1):
		if (yi >= 0) && (perlinMatrix[x][yi] <= 130):
			return false
	return true	
	
func raycastDown(x: int, y: int, minDist: int) -> bool:
	for yi in range(y+1, y+minDist, 1):
		if (yi < height) && (perlinMatrix[x][yi] <= 130):
			return false
	return true	
	
func raycastLeft(x: int, y: int, minDist: int) -> bool:
	for xi in range(x-1, x-minDist, -1):
		if (xi >= 0) && (perlinMatrix[xi][y] <= 130):
			return false
	return true	
	
func raycastRight(x: int, y: int, minDist: int) -> bool:
	for xi in range(x+1, x+minDist, 1):
		if (xi < width) && (perlinMatrix[xi][y] <= 130):
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

func _ready():
	fillPerlinMatrix()	
	setGeoMatrix()
	setPlayFieldMap(0,0)
	setPlayFieldMap(width,height)
	setPlayFieldMap(-width,-height)
	setPlayFieldMap(width,-height)
	setPlayFieldMap(-width,height)
	generateSpawn()	
	displayPreview()	

func checkPlayerLoc():
	collisionNode.set_deferred("disabled", false)
	var locX = playerNode.position.x
	var locY = playerNode.position.y	
	# Wrap around teleports
	if (locX > width * 16):
		playerNode.position.x = 0
	elif (locX < 0):
		playerNode.position.x = width * 16
	elif (locY > height * 16):
		playerNode.position.y = 0
	elif (locY < 0):
		playerNode.position.y = height * 16
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	checkPlayerLoc()
