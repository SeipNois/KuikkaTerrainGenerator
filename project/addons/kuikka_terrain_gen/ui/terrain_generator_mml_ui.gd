extends Control

## Terrain generator based on reference terrain type from 
## National Land Survey database instead of user input parameter values.

signal heightmap_changed(hmap: Image)
signal colormap_changed(color_map: Image)
signal maps_changed(maps: Array)
signal input_heightmap_changed(ref: Image)
signal height_range_changed(range: Vector2)

var _selected_hmaps: Array
var _selected_terrain_features: Array
var params = ImageGenParams.new()

## HACK: Avoid directly refer to singleton as it is loaded only after
## script is generated thus raising an error. Use singleton
## [member global_instance] reference instead.
var generator = TerrainServerGD.get_instance()

var image_exports_path = "res://image_exports/"
var export_selection = 0

var heightmap: Image
var _hmap_path : String
var img_name : String = "heightmap_temp"

var in_prof : HeightProfile
var out_prof : HeightProfile

var areas : Dictionary
var terrain_image : TerrainFeatureImage

@onready var _hmap_list = %HeightmapList
@onready var _terrain_data_list = %TerrainDataList

@onready var _hmap_texture_out = %HmapTextureRect
@onready var _hmap_texture_in = %InputHmapTextureRect
@onready var _areas_output = %AreasOverlay
@onready var _terrain_features = %TerrainFeatures
@onready var _agent_areas_text = %AgentAreasContainer
@onready var _comparison = %ResultComparisonUI

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
	_hmap_texture_out.texture = null
	if _selected_hmaps.is_empty() or _selected_terrain_features.is_empty():
		printerr("No reference terrain data selected for terrain generation.
					Terrain can't be generated!")
		return
	else:
		#var stats = KuikkaImgUtil.img_get_stats(_selected_hmaps[0])
		#params.image_height_scale = Vector2(stats.min, stats.max)
		
		# Set height range from separate file.
		var filename = FilePath.get_filename(_selected_hmaps[0]) + "_scale.cfg"
		var path = FilePath.get_directory(_selected_hmaps[0])
		var full_path = path+"/"+filename
		
		if not FileAccess.file_exists(full_path):
			printerr("Could not find paired scale configuration file ", filename, " for heightmap!")
			return
		var config = ConfigFile.new()
		var err = config.load(full_path)
		
		if err:
			printerr("Error loading height scale config: ", err)
			return
		
		params.image_height_scale.x = config.get_value("Scale", "min") - 15
		params.image_height_scale.y = config.get_value("Scale", "max") + 15
		
		var aux = FilePath.get_directory(_selected_hmaps[0]) + "/" + FilePath.get_filename(_selected_hmaps[0]) + ".png.aux.xml"
		var scaling_values = TerrainParser.get_tile_position(aux)
		params.set_height_tile_rect(scaling_values)
		
		_hmap_texture_out.texture = null
		generator.export_map.connect(await_agent_step)
		generator.generate_terrain_from_reference.call_deferred(_selected_hmaps, _selected_terrain_features, params)


func await_agent_step(hmap, areas, timg):
	hmap.save_png("res://result_comparisons/agent_hmap.png")
	var dict = KuikkaImgUtil.terrain_image_to_dict(timg)
	var txt = FileAccess.open("res://result_comparisons/terrain_image.txt", FileAccess.WRITE)
	
	for key in dict.keys():
		txt.store_string("%s\n" % key)
		for val in dict[key].keys():
			txt.store_string("%s : %s\n" % [val, dict[key][val]])
	
	txt.close()


## * * * * * Signal catches * * * * * 

## Callback for generation finished to populate ui with resulting heightmap.
func _on_generation_finished(hmap: Image, agent_travels: Dictionary, terra_img: TerrainFeatureImage, gen_time : Vector2=Vector2(NAN, NAN)):
	# set export path name
	img_name = FilePath.get_filename(_selected_hmaps[0]) + "_" + KuikkaUtils.rand_string(16)
	#var export_path_exr = ProjectSettings.globalize_path(image_exports_path+img_name+".exr")
	var export_path = ProjectSettings.globalize_path(image_exports_path+img_name+".png")
	# var export_path_scaled = ProjectSettings.globalize_path(image_exports_path+img_name+"-scaled.png")
	
	#hmap  = KuikkaImgUtil.image_scale_values(hmap, 0.5)
	hmap.save_png(export_path)
	# hmap.save_exr(export_path_exr)
	
	# Scale images so that current scale max value is white and minimum black.
	var scale_min = params.image_height_scale.x
	var scale_max = params.image_height_scale.y
	
	KuikkaImgUtil.img_magick_execute(["convert", export_path, "-blur", "2x3", export_path], false)
	# KuikkaImgUtil.gdal_execute("gdal_translate.exe", ["-scale", scale_min, scale_max, 0, 255, "-ot", "Int8", export_path, export_path_scaled], false)
	
	# Load scaled image as heightmap
	heightmap = Image.load_from_file(export_path)
	
	_hmap_path = export_path
	
	areas = agent_travels
	terrain_image = terra_img
	_hmap_texture_out.texture = ImageTexture.create_from_image(heightmap)
	_areas_output.draw_areas(agent_travels)
	_terrain_features.update_feature_list(terrain_image)
	#heightmap.resize(256, 256)

	var polygons = areas["KuikkaLakeAgent"]["coast_line"]
	#areas["KuikkaLakeAgent"]["coast_line"] = polygons
	
	#for i in polygons.size():
	#	var p = polygons[i]
	#	polygons[i] = KuikkaUtils.merge_points_by_distance(p, 20)
	
	var maps = [heightmap, areas["KuikkaLakeAgent"]["cover_map"]]
	maps_changed.emit(maps)
	#heightmap_changed.emit(heightmap)
	
	#colormap_changed.emit(areas["KuikkaLakeAgent"]["cover_map"])
	
	# Create smoothed out map from input map to blend in height quantization.
	var ref_path = _selected_hmaps[0]
	var ref_name = FilePath.get_filename(ref_path)
	var ref_export = ProjectSettings.globalize_path(image_exports_path+ref_name+".png")
	#var ref_export_scaled = ProjectSettings.globalize_path(image_exports_path+ref_name+"-scaled.png")
	
	KuikkaImgUtil.img_magick_execute(["convert", ref_path, "-blur", "2x3", "-depth", "16", ref_export], false)
	#KuikkaImgUtil.gdal_execute("gdal_translate.exe", ["-scale", scale_min, scale_max, 0, 255, "-ot", "Int8", ref_export, ref_export_scaled], false)
	
	# Load scaled image
	var refmap = Image.load_from_file(ref_export)
	
	#refmap = Image.load_from_file(ref_export_scaled)
	var dup : Image = refmap.duplicate()
	dup.resize(512, 512, Image.INTERPOLATE_NEAREST)
	_hmap_texture_in.texture = ImageTexture.create_from_image(dup)
	input_heightmap_changed.emit(refmap)
	
	height_range_changed.emit(terra_img.height_profile.represent_range)
	%MapContainer.height_range = terra_img.height_profile.represent_range
	%InputMapContainer.height_range = terra_img.height_profile.represent_range
	_agent_areas_text.set_areas(agent_travels)
	%MapID.text = "Generation ID " + str(img_name)
	
	_comparison.gen_time = gen_time
	generate_result_comparison()
	
	# Export results
	# _on_export_button_pressed()
	_comparison._on_export_stats_pressed()


func generate_result_comparison():
	var istats = KuikkaImgUtil.im_fetch_img_stats(_selected_hmaps[0])
	in_prof = KuikkaImgUtil.dict_to_height_profile(istats)
	
	# if not _hmap_path:
	# _on_export_button_pressed()
	
	var ostats = KuikkaImgUtil.im_fetch_img_stats(_hmap_path)
	out_prof = await  KuikkaImgUtil.dict_to_height_profile(ostats)
	
	#var format = Image.load_from_file(_selected_hmaps[0]).get_format()
	#in_prof = await TerrainParser._heightmap_scale_values(in_prof, params, format)
	#out_prof = TerrainParser._heightmap_scale_values(out_prof, params, format)
	
	# Height range from original [TerrainFeatureImage]
	in_prof.represent_range = params.image_height_scale
	out_prof.represent_range = params.image_height_scale
	
	in_prof.height_range = terrain_image.height_profile.height_range
	out_prof.height_range = terrain_image.height_profile.height_range
	
	update_comparison()
	
	
func update_comparison():
	if in_prof and out_prof:
		#var prefix = FilePath.get_filename(_selected_hmaps[0])
		
		_comparison.set_images(in_prof, out_prof, img_name)
	

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
	
	if not img_name:
		img_name = KuikkaUtils.rand_string(16)
	
	var image : Image = _hmap_texture_out.texture.get_image()
	if image:
		match export_selection:
			# PNG
			0:
				image.save_png(image_exports_path+img_name+".png")
				_hmap_path = image_exports_path+img_name+".png"
			# JPG
			1:
				image.save_jpg(image_exports_path+img_name+".jpg");
				_hmap_path = image_exports_path+img_name+".jpg"
			
	
# Refresh 3D Terrain
func _on_button_pressed():
	heightmap_changed.emit(heightmap)


# Refresh heightmap / overlays drawn
func _on_button_2_pressed():
	_on_generation_finished(heightmap, areas, terrain_image)


func _on_spin_box_gene_size_value_changed(value):
	params.point_size = value


func _on_spin_box_population_value_changed(value):
	params.population = value


func _on_spin_box_generations_value_changed(value):
	params.generations = value

# Refresh comparison
func _on_refresh_pressed():
	update_comparison()


func _on_spin_box_h_scale_min_value_changed(value):
	params.image_height_scale.x = value - 15


func _on_spin_box_h_scale_max_value_changed(value):
	params.image_height_scale.y = value + 15
