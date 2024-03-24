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
signal generation_finished

var _instance: TerrainServerGD
static var global_instance: TerrainServerGD

## RNG to set starting states for different agent RNGs in deterministic way.
var rng : RandomNumberGenerator = RandomNumberGenerator.new()

## Heightmap [Image] to generate terrain to.
var heightmap : Image

## [Array] of [TerrainAgent] instances to use to generate terrain features.
var agents : Array[KuikkaTerrainAgent]

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
	pass # Replace with function body.


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
	var result : Texture2D
	print_debug("Starting terrain generation.")
	_generate_heightmap(parameters)
	
	# Wait for agent generation to finish
	await generation_finished
	print_debug(agent_areas)
	print_debug("Terrain generation finished.")
		
	result = ImageTexture.create_from_image(heightmap)
	
	return [result, agent_areas]


func _generate_heightmap(parameters: KuikkaTerrainGenParams):
	heightmap = Image.create(parameters.width, 
							parameters.height,
							false,
							parameters.image_format)
	heightmap.fill(parameters.start_level)
	_setup_agents(parameters, heightmap)
	
	# Start generation for each agent to run in idle loop.
	_start_agent_generation()
	return


## Start generation loop for each agent.
func _start_agent_generation():
	for agent in _active_agents:
		agent.start_generation.call_deferred()
	return

## Setup agents for generating heightmap
func _setup_agents(parameters: KuikkaTerrainGenParams, heightmap: Image):
	rng.set_seed(parameters.generation_seed)
	rng.set_state(0)
	
	print_debug(parameters.generation_seed, " ", rng.seed)
	
	# Create new agent instances
	agents.clear()
	for c in get_children():
		remove_child(c)
		c.queue_free()
	agents.append_array([KuikkaLakeAgent.new(), KuikkaHillAgent.new()])
	
	for agent in agents:
		agent.heightmap = heightmap
		agent.seed = parameters.generation_seed
		agent.state = rng.randi()
		print_debug(agent.agent_type)
		agent.parameters = parameters.agents[agent.agent_type]
		# Add as child to enable _ready and _process loop for agent Nodes.
		add_child(agent, true)
		
		# Remove agent from active when tokens are spent and generation finishes.
		agent.generation_finished.connect(
				(func(a): 
					if a in _active_agents: 
						print_debug("Agent ", a, "finished generation.")
						agent_areas[a.agent_type] = a.area_silhouette
						_active_agents.erase(a)
					# Consider finished if all agents have finished.
					if _active_agents.size() == 0:
						print_debug("Generation finished.")
						generation_finished.emit()))
	
	# Start with every agent unfinished
	_active_agents = agents
	return


func _test_generate(parameters: KuikkaTerrainGenParams) -> Texture2D:
	var hmap_texture = NoiseTexture2D.new()
	hmap_texture.noise = FastNoiseLite.new()
	hmap_texture.width = parameters.width
	hmap_texture.height = parameters.height
	
	# NoiseTexture2D runs threaded and may return empty if not awaited for.
	await hmap_texture.changed
	return hmap_texture
