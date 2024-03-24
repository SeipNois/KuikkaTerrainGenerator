@tool
class_name KuikkaTerrainGenUI extends Control


## [Control] UI Element for generating heightmaps.

## HACK: Avoid directly refer to singleton as it is loaded only after
## script is generated thus raising an error. Use singleton
## [member global_instance] reference instead.
var generator = TerrainServerGD.get_instance()
var image_exports_path = "res://image_exports/"
var export_selection = 0

## Generation parameters from user input
var parameters : KuikkaTerrainGenParams = KuikkaTerrainGenParams.new()

@onready var hmap_display = %HmapTextureRect
@onready var area_overlay = %AreasOverlay


# Called when the node enters the scene tree for the first time.
func _ready():
	generator = TerrainServerGD.get_instance()
	
	hmap_display.custom_minimum_size = Vector2(parameters.width, parameters.height)
	area_overlay.custom_minimum_size = Vector2(parameters.width, parameters.height)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


## Generate terrain
func _on_generate_button_pressed():
	hmap_display.texture = null
	# Debug
	var result : Array = await generator.generate_terrain(parameters)
	hmap_display.texture = result[0]
	var img = Image.create(parameters.width, parameters.height, 
							false, parameters.image_format)
	area_overlay.draw_areas(result[1])


func _on_export_button_pressed():
	if not hmap_display.texture:
		printerr("No heightmap generated. Can not export to image.")
		return
		
	var image : Image = hmap_display.texture.get_image()
	if image:
		var img_name = KuikkaUtils.rand_string(16)
		match export_selection:
			# PNG
			0:
				image.save_png(image_exports_path+img_name+".png")
			# JPG
			1:
				image.save_jpg(image_exports_path+img_name+".jpg");


## * * * * * * * * * * * * * * 
## 	UI Signal catches
## * * * * * * * * * * * * * * 

func _on_seed_spin_box_value_changed(value):
	# Set generation seed for process.
	parameters.generation_seed = value


func _on_tokens_spin_box_value_changed(value):
	# TODO: Set initial tokens separately for each agent.
	for a in parameters.agents:
		parameters.agents[a].initial_tokens = value


## Toggle visibility of areas of effect
func _on_effect_area_check_button_toggled(toggled_on):
	%AreasOverlay.visible = toggled_on
	

func _on_move_speed_min_spin_box_value_changed(value):
	# TODO: Set separately for each agent.
	for a in parameters.agents:
		parameters.agents[a].move_speed.x = value


func _on_move_speed_max_spin_box_value_changed(value):
	# TODO: Set separately for each agent.
	for a in parameters.agents:
		parameters.agents[a].move_speed.y = value
