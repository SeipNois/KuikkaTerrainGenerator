extends Control

## Terrain generator based on reference terrain type from 
## National Land Survey database instead of user input parameter values.

var _selected_hmaps: Array
var _selected_terrain_features: Array
var params = ImageGenParams.new()

## HACK: Avoid directly refer to singleton as it is loaded only after
## script is generated thus raising an error. Use singleton
## [member global_instance] reference instead.
var generator = TerrainServerGD.get_instance()

var image_exports_path = "res://image_exports/"
var export_selection = 0

@onready var _hmap_list = %HeightmapList
@onready var _terrain_data_list = %TerrainDataList

@onready var _hmap_texture_out = %HmapTextureRect
@onready var _areas_output = %AreasOverlay

# Called when the node enters the scene tree for the first time.
func _ready():
	generator = TerrainServerGD.get_instance()
	generator.generation_finished.connect(_on_generation_finished)
	
	if not params:
		params = ImageGenParams.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func generate_terrain():
	if _selected_hmaps.is_empty() or _selected_terrain_features.is_empty():
		printerr("No reference terrain data selected for terrain generation.
					Terrain can't be generated!")
		return
	else:
		# TODO: set [ImageGenParams][member params] for generation
		
		generator.generate_terrain_from_reference.call_deferred(_selected_hmaps, _selected_terrain_features, params)


## * * * * * Signal catches * * * * * 

## Callback for generation finished to populate ui with resulting heightmap.
func _on_generation_finished(heightmap: Image, agent_travels):
	_hmap_texture_out.texture = ImageTexture.create_from_image(heightmap)
	_areas_output.draw_areas(agent_travels)

## Open heightmap file selection
func _on_select_height_data_files_pressed():
	%HmapFileDialog.show()

## Open terrain data file selection
func _on_select_terrain_data_files_pressed():
	%TerrainFileDialog.show()

## Heightmaps selected
func _on_hmap_file_dialog_files_selected(paths):
	_hmap_list.text = "; ".join(paths)
	_selected_hmaps = paths

## Terrain files selected
func _on_terrain_file_dialog_files_selected(paths):
	_terrain_data_list.text = "; ".join(paths)
	_selected_terrain_features = paths

## Run generation
func _on_generate_button_pressed():
	generate_terrain()


## Generation seed change
func _on_line_edit_text_changed(new_text):
	var seed = hash(new_text)
	params.seed = seed


func _on_spin_box_map_width_value_changed(value):
	params.width = value


func _on_spin_box_map_height_value_changed(value):
	params.height = value


func _on_spin_box_value_changed(value):
	params.start_level = Color(value, value, value, 1)


## Toggle overlay
func _on_check_button_toggled(toggled_on):
	if toggled_on:
		_areas_output.show() 
	else:
		_areas_output.hide()


func _on_export_button_pressed():
	if not _hmap_texture_out.texture:
		printerr("No heightmap generated. Can not export to image.")
		return
		
	var image : Image = _hmap_texture_out.texture.get_image()
	if image:
		var img_name = KuikkaUtils.rand_string(16)
		match export_selection:
			# PNG
			0:
				image.save_png(image_exports_path+img_name+".png")
			# JPG
			1:
				image.save_jpg(image_exports_path+img_name+".jpg");
