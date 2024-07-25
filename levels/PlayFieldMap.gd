extends TileMap

const RAND_SEED = 16384

@onready var perlinNode = $PerlinGraph
@onready var playerNode = get_node("/root/PlayField/Player")

var perlinMatrix : Array = []
# Perlin matrix dimensions
var width = 512
var height = 512

var mapLocX = 0
var mapLocY = 0

var spawnedMaps: Array
var spawnLoc: Vector2i

# Called when the node enters the scene tree for the first time.
func _init():			
	var tile_set = self.tile_set
	seed(RAND_SEED)
		
	# Initialize blank matrix	
	for x in width:
		perlinMatrix.append([])
		for y in height:
			perlinMatrix[x].append(0)
			
func setPlayFieldMap(offsetx: int, offsety: int):
	if (!spawnedMaps.has(Vector2i(offsetx, offsety))):
		for x in width:
			for y in height:
				if (perlinMatrix[x][y] <= 130):
					set_cell(0, Vector2i(x+offsetx,y+offsety), 1, Vector2i(0,0), 0)		
		spawnedMaps.append(Vector2i(offsetx, offsety))
		print("Spawned map: ", Vector2i(offsetx, offsety))
			
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
	playerNode.position = spawnLoc * 16
	var cameraNode = get_node("/root/PlayField/MainCamera")
	cameraNode.position = spawnLoc * 16
	
func generateSpawn():	
	var previewNode = $levelPreview
	spawnLoc = pickPlayerSpawn()
	print("Spawn Location: ", spawnLoc)	
	var adjSpawnLoc = spawnLoc * 16
	print("Adjusted Spawn: ", adjSpawnLoc)
	playerNode.position = adjSpawnLoc
	previewNode.position = adjSpawnLoc
	previewNode.position.x -= 150
	for xi in range(spawnLoc.x-5, spawnLoc.x+5):
		set_cell(0, Vector2i(xi, spawnLoc.y+22), 1, Vector2i(0,0), 0)	

func _ready():
	fillPerlinMatrix()	
	setPlayFieldMap(0,0)
	generateSpawn()	
	displayPreview()

func checkPlayerLoc():
	var locX = int(playerNode.position.x / 16)
	var locY = int(playerNode.position.y / 16)	
	var modLocX = locX % width
	if (modLocX >= width - 50):
		mapLocX += width
		setPlayFieldMap(mapLocX, 0)	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	checkPlayerLoc()
