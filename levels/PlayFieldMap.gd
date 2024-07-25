extends TileMap

@onready var perlinNode = $PerlinGraph
var perlinMatrix : Array = []
# Perlin matrix dimensions
var width = 512;
var height = 512;

# Called when the node enters the scene tree for the first time.
func _init():			
	var tile_set = self.tile_set
	
	# Initialize blank matrix	
	for x in width:
		perlinMatrix.append([])
		for y in height:
			perlinMatrix[x].append(0)
			
func setPlayFieldMap():
	for x in width:
		for y in height:
			if (perlinMatrix[x][y] > 130):
				set_cell(0, Vector2i(x,y), 1, Vector2i(0,0), 0)	
			
func fillPerlinMatrix():
	perlinNode.CPerlinGraph(width, height, 16384, 0.1, 2, 6, 0.4)
	var flatPerlinMatrix = perlinNode.getPerlinMatrix()		
	var curIndex = 0;
	for x in width:
		for y in height:			
			perlinMatrix[x][y] = flatPerlinMatrix[curIndex]			
			curIndex += 1
	print("Debug indexes: ", curIndex)	
	
func _ready():
	fillPerlinMatrix()	
	setPlayFieldMap()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
