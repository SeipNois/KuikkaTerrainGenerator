class_name TerrainServerGD extends Node

## * * * * * * * * * * * * * * * * * * * * * * * * 
##	Auto-load (singleton) class to define API to terrain generation 
##	processes. API can be used on runtime to generate with parameters
##	loaded from configuration file or in editor through related editor tab. 
##	Generation produces image file that can then be saved on disk or
##	used as heightmap for supporting terrain.
## * * * * * * * * * * * * * * * * * * * * * * * * 

## Instance representing currently loaded singleton instance if any
## (help to avoid errors referring to singleton directly if plugin is
## not loaded.)

signal generation_step_completed
signal agent_generation_finished
signal genetic_operations_finished
signal generation_finished(heightmap, areas, terr_img)


var _instance: TerrainServerGD
static var global_instance: TerrainServerGD

@export var terrain_parser : TerrainParser
var terrain_image : TerrainFeatureImage

## RNG to set starting states for different agent RNGs in deterministic way.
var rng : RandomNumberGenerator = RandomNumberGenerator.new()

## Heightmap [Image] to generate terrain to.
var heightmap : Image

## [Array] of [TerrainAgent] instances to use to generate terrain features.
var agents : Array[KuikkaTerrainAgent]

var evolution_handler : EvolutionHandler = EvolutionHandler.new()

## Agents that are actively editing terrain
var _active_agents : Array[KuikkaTerrainAgent]

var agent_areas : Dictionary


func _enter_tree():
	# Already loaded
	if (_instance != null):
		self.queue_free()
		return
	
	self._instance = self
	global_instance = self._instance


# Called when the node enters the scene tree for the first time.
func _ready():
	terrain_parser = TerrainParser.new()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


static func get_instance() -> TerrainServerGD:
	return global_instance


## * * * * * * * * * * 
##		Interface
## * * * * * * * * * * 

## Generate terrain heightmap texture with 
## given [KuikkaTerrainGenParams] [param parameters].
func generate_terrain(parameters: KuikkaTerrainGenParams) -> Array:
	var _start_ticks = Time.get_ticks_msec()
	print_debug("Started terrain generation ", _start_ticks)
	
	var result : Texture2D
	await _generate_heightmap(parameters)
	
	# Wait for agent generation to finish
	# await agent_generation_finished
	# print_debug(agent_areas)
	# print_debug("Terrain generation finished.")
		
	result = ImageTexture.create_from_image(heightmap)
	
	var _end_ticks = Time.get_ticks_msec()
	print_debug("Finished terrain generation ", _end_ticks, "\nTook: ",
	str(_end_ticks-_start_ticks))
	
	generation_finished.emit(heightmap, agent_areas, terrain_image)
	return [result, agent_areas]


## Generate terrain using heightmaps and gml formatted feature data of
## certain region as reference.
func generate_terrain_from_reference(heightmaps: Array, gml: Array, parameters: ImageGenParams):
	var _start_ticks = Time.get_ticks_msec()
	print_debug("Started terrain generation ", _start_ticks)
	# Create reference TerrainImage
	heightmap = Image.create(parameters.width, 
						parameters.height,
						false,
						parameters.image_format)
	
	terrain_image = terrain_parser.parse_data(heightmaps, gml, parameters)
	terrain_image.generation_seed = parameters.seed
	terrain_image.evolution.gene_point_size = parameters.point_size
	terrain_image.evolution.generations = parameters.generations
	terrain_image.evolution.population_size = parameters.population

	var rang = terrain_image.height_profile.height_range
	var level = terrain_image.height_profile.mean + parameters.start_level
	level = clampf(level, 0.0, 1.0)
	
	var color = Color(level, level, level, 1)
	heightmap.fill(color)
	
	rng.set_seed(parameters.seed)
	# rng.set_state(parameters.seed)
	
	# Run agent generation process.
	print_debug("Setting up agents.")
	_setup_agents_image(terrain_image, heightmap)
	print_debug("Starting agent run.")
	_start_agent_generation()
	
	# Wait for agent generation to finish
	await agent_generation_finished
	
	# FIXME: DEBUG REMOVE to allow agent output
	# heightmap.fill(parameters.start_level)
	# print_debug("agent areas ", agent_areas)
	
	## FIXME: Uncomment to activate evolution.
	print_debug("Sample heightmap images.")
	terrain_image.database = HeightSampleDB.new()
	terrain_image.database.unsorted_samples = await KuikkaUtils.sample_images_array(heightmaps, 300, 
		"res://addons/kuikka_terrain_gen/height_samples/gene_samples")
	
	print_debug("Setting up evolutionary process.")
	_setup_evolution_process_image(terrain_image, heightmap)
	
	print_debug("Starting evolution.")
	_run_evolution_process_image(terrain_image)
	
	await evolution_handler.heightmap_completed
	## * * * * * * * * *
	
	var _end_ticks = Time.get_ticks_msec()
	print_debug("Finished generation ", _end_ticks, "\nTook: ",
	str(_end_ticks-_start_ticks))
	
	generation_finished.emit(heightmap, agent_areas, terrain_image)
	

## Update heightsamples sorting based on new parameters.
func resort_height_samples(parameters: KuikkaTerrainGenParams):
	evolution_handler.sort_height_samples(parameters)


## Update heightsamples sorting based on new parameters.
func update_height_sample_db(parameters: KuikkaTerrainGenParams):
	evolution_handler.setup_database(parameters)


func _generate_heightmap(parameters: KuikkaTerrainGenParams):
	heightmap = Image.create(parameters.width, 
							parameters.height,
							false,
							parameters.image_format)
	heightmap.fill(parameters.start_level)
	_setup_agents(parameters, heightmap)
	
	# Start generation for each agent to run in idle loop.
	_start_agent_generation()
	
	# Wait for agent generation to finish
	await agent_generation_finished
	
	# Setup genetic process
	await _setup_evolution_process(parameters)
	
	_run_evolution_process(parameters)
	
	# Wait for genetic process to finish
	await genetic_operations_finished
	
	return


## Start generation loop for each agent.
func _start_agent_generation():
	for agent in _active_agents:
		agent.start_generation.call_deferred()
	return

## * * * * * * * * * * * * * * * * * * * *
## Terrain Image based setup


func _setup_evolution_process_image(terrain_image, heightmap):
	evolution_handler.seed = rng.randi()# terrain_image.generation_seed
	#evolution_handler.state = rng.randi()
	
	# Setup image samples and heightmap.
	evolution_handler.setup_handler_from_image(terrain_image, heightmap)
	
	evolution_handler.initialize_populations_from_image(terrain_image, agent_areas)
	
	# evolution_handler.heightmap_completed.connect(func(hmap): 
	# 	print_debug("Genetic processes finished.")
	# 	genetic_operations_finished.emit())
	return


## Setup agents using parameters saved as TerrainFeatureImage.
func _setup_agents_image(terrain_image: TerrainFeatureImage, heightmap: Image):
	rng.set_seed(terrain_image.generation_seed)
	# rng.set_state(terrain_image.generation_seed)
	
	# print_debug(parameters.generation_seed, " ", rng.seed)
	
	# Create new agent instances
	agents.clear()
	for c in get_children():
		remove_child(c)
		c.queue_free()
	agents.append_array([KuikkaLakeAgent.new(), KuikkaHillAgent.new(), KuikkaMeadowAgent.new()])
	
	for agent in agents:
		agent.heightmap = heightmap
		agent.seed = rng.randi()
		#agent.state = rng.randi()
		
		print_debug(agent.agent_type)
		agent.terrain_image = terrain_image
		# Add as child to enable _ready and _process loop for agent Nodes.
		add_child(agent, true)
		
		# Remove agent from active when tokens are spent and generation finishes.
		agent.generation_finished.connect(
				(func(a): 
					if a in _active_agents: 
						# print_debug("Agent ", a, "finished generation.")
						agent_areas[a.agent_type] = a.area_silhouette
						_active_agents.erase(a)
					# Consider finished if all agents have finished.
					if _active_agents.size() == 0:
						# print_debug("Generation finished.")
						agent_generation_finished.emit()))
	
	# FIXME: Activate all agents
	_active_agents = agents
	# _active_agents = [agents[0]]
	return


func _run_evolution_process_image(terrain_image: TerrainFeatureImage):
	evolution_handler.run_evolution_process_image.call_deferred(terrain_image)


## * * * * * * * * * * * * * * * * * * * *
## Parameters based setup

## Setup agents for generating heightmap
func _setup_agents(parameters: KuikkaTerrainGenParams, heightmap: Image):
	rng.set_seed(parameters.generation_seed)
	# rng.set_state(parameters.generation_seed)
	
	# print_debug(parameters.generation_seed, " ", rng.seed)
	
	# Create new agent instances
	agents.clear()
	for c in get_children():
		remove_child(c)
		c.queue_free()
	agents.append_array([KuikkaLakeAgent.new(), KuikkaHillAgent.new()])
	
	for agent in agents:
		agent.heightmap = heightmap
		agent.seed = rng.randi()
		# agent.state = rng.randi()
		print_debug(agent.agent_type)
		agent.parameters = parameters.agents[agent.agent_type]
		# Add as child to enable _ready and _process loop for agent Nodes.
		add_child(agent, true)
		
		# Remove agent from active when tokens are spent and generation finishes.
		agent.generation_finished.connect(
				(func(a): 
					if a in _active_agents: 
						# print_debug("Agent ", a, "finished generation.")
						agent_areas[a.agent_type] = a.area_silhouette
						_active_agents.erase(a)
					# Consider finished if all agents have finished.
					if _active_agents.size() == 0:
						# print_debug("Generation finished.")
						agent_generation_finished.emit()))
	
	# Start with every agent unfinished
	_active_agents = agents
	return


## Setup rng settings, fitness references, chromosomes and height samples for
## genetic generation process.
func _setup_evolution_process(parameters: KuikkaTerrainGenParams):
	evolution_handler.seed = rng.randi()
	# evolution_handler.state = rng.randi()
	
	# Setup image samples and heightmap.
	evolution_handler.setup_evolution_handler.call_deferred(parameters, heightmap)
	await evolution_handler.setup_completed
	
	evolution_handler.initialize_populations.call_deferred(parameters, agent_areas)
	await  evolution_handler.populations_generated
	
	evolution_handler.heightmap_completed.connect(func(hmap): genetic_operations_finished.emit())
	return
	

func _run_evolution_process(parameters: KuikkaTerrainGenParams):
	evolution_handler.run_evolution_process.call_deferred(parameters)
	return
	

func _test_generate(parameters: KuikkaTerrainGenParams) -> Texture2D:
	var hmap_texture = NoiseTexture2D.new()
	hmap_texture.noise = FastNoiseLite.new()
	hmap_texture.width = parameters.width
	hmap_texture.height = parameters.height
	
	# NoiseTexture2D runs threaded and may return empty if not awaited for.
	await hmap_texture.changed
	return hmap_texture

