# @tool
class_name KuikkaTerrainGenUI extends Control


## [Control] UI Element for generating heightmaps.

@export var GDAL_SOURCE = "res://addons/kuikka_terrain_gen/height_samples/SAMPLES_GEOTIFF"
@export var HEIGHT_SAMPLE_PATH = "res://addons/kuikka_terrain_gen/height_samples/SAMPLES_PNG"
@export var PROCESSED_SAMPLE_PATH = "res://addons/kuikka_terrain_gen/height_samples/split_samples"

var agent_ui_element = preload("res://addons/kuikka_terrain_gen/ui/agent_options_ui.tscn")
var gene_ui_element = preload("res://addons/kuikka_terrain_gen/ui/agent_fitness_settings.tscn")

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

@onready var agent_elements_list = %AgentOptionContainer
@onready var gene_element_list = %GeneOptionContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	generator = TerrainServerGD.get_instance()
	
	hmap_display.custom_minimum_size = Vector2(parameters.width, parameters.height)
	area_overlay.custom_minimum_size = Vector2(parameters.width, parameters.height)
	
	if not Engine.is_editor_hint():
		create_ui_elements()
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
	
func create_ui_elements():
	
	# Create agent behaviour related ui elements
	# NOTE: size of [parameters.agents] and [parameters.area_fitness]
	# should match with definition of each agent.
	for a in parameters.agents:
		var element : AgentOptionsUI = agent_ui_element.instantiate()
		element.agent_name = a
		agent_elements_list.add_child(element)
		
		element.value_changed.connect(_on_agent_options_value_changed)
	
		# Create agent specific ui elements for genetic operation control
		var gene_element : AgentFitnessUI = gene_ui_element.instantiate()
		gene_element.agent_name = a
		gene_element_list.add_child(gene_element)
		
		# TODO: Add signal connections
		gene_element.fitness_min_height_changed.connect(_on_fitness_min_height_changed)
		gene_element.fitness_max_height_changed.connect(_on_fitness_max_height_changed)
		gene_element.fitness_mean_height_changed.connect(_on_fitness_mean_height_changed)
		gene_element.fitness_variance_changed.connect(_on_fitness_variance_changed)
		gene_element.fitness_frequency_changed.connect(_on_fitness_frequency_changed)


## Generate terrain
func _on_generate_button_pressed():
	generate.call_deferred()

func generate():
		if not parameters.database:
			parameters.database = preload("res://addons/kuikka_terrain_gen/db/height_db.tres")
		
		if parameters.database.unsorted_samples.is_empty():
			parameters.database.unsorted_samples = KuikkaUtils.parse_image_path_batch(PROCESSED_SAMPLE_PATH, 1000)
		
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
	# Set generation s	eed for process.
	parameters.generation_seed = hash(value)


func _on_agent_options_value_changed(value, val_type: AgentOptionsUI.ValueType, agent: String):
	# TODO: Set initial tokens separately for each agent.
	match val_type:
		AgentOptionsUI.ValueType.TOKENS:
			parameters.agents[agent].initial_tokens = value
		AgentOptionsUI.ValueType.SPEED_MIN:
			parameters.agents[agent].move_speed.x = value
		AgentOptionsUI.ValueType.SPEED_MAX:
			parameters.agents[agent].move_speed.y = value
		AgentOptionsUI.ValueType.JUMP_TR:
			if parameters.agents[agent].get("jump_treshold"):
				parameters.agents[agent].jump_treshold = value
		AgentOptionsUI.ValueType.GEN_TR:
			if parameters.agents[agent].get("generation_treshold"):
				parameters.agents[agent].generation_treshold = value
		AgentOptionsUI.ValueType.GEN_TYPE:
			parameters.agents[agent].gene_placement = value


## Toggle visibility of areas of effect
func _on_effect_area_check_button_toggled(toggled_on):
	%AreasOverlay.visible = toggled_on


func _on_fitness_min_height_changed(value, agent: String):
	parameters.area_fitness[agent].min_height = value

func _on_fitness_max_height_changed(value, agent: String):
	parameters.area_fitness[agent].max_height = value

func _on_fitness_mean_height_changed(value, agent: String):
	parameters.area_fitness[agent].mean = value

func _on_fitness_variance_changed(value, agent: String):
	parameters.area_fitness[agent].variance = value


func _on_fitness_frequency_changed(value, agent: String):
	parameters.area_fitness[agent].hill_frequency = value


func _on_generations_slider_value_changed(value):
	parameters.generations = value


func _on_population_slider_value_changed(value):
	parameters.population_size = value


func _on_file_dialog_file_selected(path):
	var item = load(path)
	if item is HeightSampleDB:	
		%ImgSamplesPath.text = path
		parameters.database = item
	else:
		printerr("Invalid file. Target should be a [HeightSampleDB] resource.")
	return


func _on_height_spin_box_value_changed(value):
	var level = clampf(value, 0, 1)
	parameters.start_level = Color(level, level, level)


## Generate heightsamples and initialize database with unsorted samples.
func _on_gen_samples_button_pressed():
	if not parameters.database:
		parameters.database = preload("res://addons/kuikka_terrain_gen/db/height_db.tres")
	var samples = []
	# Create new samples if not created.
	if DirAccess.open(HEIGHT_SAMPLE_PATH).get_files().size() == 0:
		samples = KuikkaUtils.sample_images(HEIGHT_SAMPLE_PATH, parameters.height_sample_size,
												parameters.image_pool_size, PROCESSED_SAMPLE_PATH)
	else:
		print_debug("Samples already created. Skipping.")
		samples = KuikkaUtils.parse_image_path_batch(PROCESSED_SAMPLE_PATH)
	parameters.database.unsorted_samples = samples
	generator.update_height_sample_db(parameters)


## NOTE: Height images used are 3000x3000 tiles. With certain sample size 
## and image pool settings this might generate big amount of split height
## sample images.
## e.g. pool of 15 and sample size of 100 --> 15 * 30^2 = 13 500 samples.

## Change the size of single height sample.
func _on_sample_size_spin_box_value_changed(value):
	parameters.height_sample_size = value


## Change size of image pool to use for sampling height samples.
func _on_image_pool_spin_box_value_changed(value):
	parameters.image_pool_size = value


func _on_sort_height_samples_pressed():
	generator.resort_height_samples(parameters)


