extends CanvasLayer

const HEALTH_BAR_SIZE: Vector2i = Vector2i(600,30)

var bar_image: Image = Image.create(HEALTH_BAR_SIZE.x,HEALTH_BAR_SIZE.y,false, Image.FORMAT_RGBA8)
var player_indicator: AnimatedSprite2D
@onready var health_text = $Health

var bar_color = Color.DARK_RED
var bar_negative = Color.BLACK
#var bar_negative = Color(1,1,1,0) # Transparent

var indicator_scene = preload("res://indicator.tscn")

func update_hud():
	health_text.text =  str(Globals.player_health,"/",Globals.player_max_health)
	if Globals.player_health < 0:
		Globals.player_health = 0
	var health_percentage: float = (Globals.player_health / Globals.player_max_health) * 100
	var health_width: int = int(health_percentage) * 6 # 100 * 6 = 600 px wide	
	for x in HEALTH_BAR_SIZE.x:
		for y in HEALTH_BAR_SIZE.y:
			if x <= health_width:
				bar_image.set_pixel(x,y,bar_color)
			else:
				bar_image.set_pixel(x,y,bar_negative)
				
	$LifeBar.texture.update(bar_image)
	
func display_preview(geoMatrix, spawnLoc: Vector2i):
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
			
			var curColor = Color(gValue, gValue, gValue, 0.5)
			perlinImage.set_pixel(x,y,curColor)	
			
	previewNode.texture.update(perlinImage)
	
	# spawn point indicator
	var spawn_indicator = indicator_scene.instantiate()
	spawn_indicator.play("spawn")
	spawn_indicator.position = spawnLoc / 2
	$levelPreview.add_child.call_deferred(spawn_indicator)
	
	# player position indicator
	player_indicator = indicator_scene.instantiate()
	player_indicator.play("player")
	player_indicator.position = spawnLoc / 2
	player_indicator.modulate = Globals.player_color
	$levelPreview.add_child.call_deferred(player_indicator)
	
func update_player_indicator():
	var player_node = get_node("../CenterViewportContainer/CenterViewport/PlayField/PlayFieldMap")
	var player_position: Vector2i = player_node.player_nodes[0].position
	player_position = (player_position / 16) / 2
	player_indicator.position = player_position

# Called when the node enters the scene tree for the first time.
func _ready():	
	$LifeBar.texture = ImageTexture.create_from_image(bar_image)	
	update_hud()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_player_indicator()
