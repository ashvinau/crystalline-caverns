extends CanvasLayer

const HEALTH_BAR_SIZE: Vector2i = Vector2i(600,30)

var bar_image: Image = Image.create(HEALTH_BAR_SIZE.x,HEALTH_BAR_SIZE.y,false, Image.FORMAT_RGBA8)
var player_indicator: AnimatedSprite2D
var boss_indicator: AnimatedSprite2D
@onready var health_text = $Health
@onready var play_field_map = get_node("../CenterViewportContainer/CenterViewport/PlayField/PlayFieldMap")

var bar_color = Color.DARK_RED
#var bar_negative = Color.BLACK
var bar_negative = Color(0.6,0,0,0.3) # Translucent dark red

var indicator_scene = preload("res://indicator.tscn")

func update_hud():
	if Globals.player_health < 0:
		Globals.player_health = 0
	health_text.text = str(Globals.player_health,"/",Globals.player_max_health)	
	var health_percentage: float = (float(Globals.player_health) / float(Globals.player_max_health)) * 100.0
	var health_width: int = int(health_percentage) * 6 # 100 * 6 = 600 px wide	
	for x in HEALTH_BAR_SIZE.x:
		for y in HEALTH_BAR_SIZE.y:
			if x <= health_width:
				bar_image.set_pixel(x,y,bar_color)
			else:
				bar_image.set_pixel(x,y,bar_negative)
				
	$LifeBar.texture.update(bar_image)
	
func display_preview(geo_matrix, spawn_loc: Vector2i):
	var perlinImage: Image = Image.create(Globals.WIDTH, Globals.HEIGHT, false, Image.FORMAT_RGBA8)
	var previewNode = $levelPreview
	previewNode.texture = ImageTexture.create_from_image(perlinImage)	
		
	for x in Globals.WIDTH:
		for y in Globals.HEIGHT:
			var gValue = geo_matrix[x][y]
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
	spawn_indicator.position = spawn_loc / 2
	$levelPreview.add_child.call_deferred(spawn_indicator)
	
	# player position indicator
	player_indicator = indicator_scene.instantiate()
	player_indicator.play("player")
	player_indicator.position = spawn_loc / 2
	player_indicator.modulate = Globals.player_color
	$levelPreview.add_child.call_deferred(player_indicator)
	
	# boss position indicator
	boss_indicator = indicator_scene.instantiate()
	boss_indicator.play("boss")
	boss_indicator.position = spawn_loc / 2	
	$levelPreview.add_child.call_deferred(boss_indicator)	
	
func update_indicators():	
	var player_position: Vector2i = play_field_map.player_nodes[0].position
	player_position = (player_position / 16) / 2
	player_indicator.position = player_position
	if is_instance_valid(play_field_map.boss_nodes[0]):
		var boss_position: Vector2i = play_field_map.boss_nodes[0].position	
		boss_position = (boss_position / 16) / 2
		boss_indicator.position = boss_position	
	else:
		boss_indicator.visible = false

# Called when the node enters the scene tree for the first time.
func _ready():	
	$LifeBar.texture = ImageTexture.create_from_image(bar_image)	
	update_hud()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_indicators()
