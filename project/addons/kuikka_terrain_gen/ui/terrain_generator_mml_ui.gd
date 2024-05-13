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

@onready var _hmap_list = %HeightmapList
@onready var _terrain_data_list = %TerrainDataList

# Called when the node enters the scene tree for the first time.
func _ready():
	generator = TerrainServerGD.get_instance()
	
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
		
		generator.generate_terrain_from_reference(_selected_hmaps, _selected_terrain_features, params)

## * * * * * Signal catches * * * * * 

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
	params.start_level = value
