class_name EvolutionHandler extends Node

## Class for handling evaluation process of chromosome population for
## each terrain type area.

signal database_ready
signal populations_generated
signal setup_completed
signal heightmap_completed(hmap: Image)

@export var chromosomes : Dictionary


var _rng : RandomNumberGenerator = RandomNumberGenerator.new()

## Generation seed for RNG
var seed : int = 0:
	set(val):
		seed = val
		_rng.set_seed(seed)


## Starting state for RNG to be set by [TerrainServerGD] to avoid each agent
## possibly taking same actions when using same seed.
var state : int = 0:
	set(val):
		state = val
		_rng.set_state(state)


var height_database: HeightSampleDB
var height_samples : Array = []

var heightmap : Image

## Dictionary of agent : [Chromosome] pairs to generate
## resulting heightmap. Used by WorkerThreadPool to save their work.
var _fittest : Dictionary

## List agents here to allow WorkerThreadPool tasks to fetch their data.
var _threadpool_keys = []

## Save parameters for WorkerThreadPool tasks to use.
var _parameters : KuikkaTerrainGenParams
## Only run generation when free.
var _tasks_running = false


func _exit_tree():
	# Remove temp files for split height samples.
	if height_samples:
		for sample in height_samples:
			print_debug("SHOULD REMOVE ", sample)
			# DirAccess.remove_absolute(sample)


## Setup source heightmap for generation and the database of image samples.
func setup_evolution_handler(parameters: KuikkaTerrainGenParams, hmap: Image):
	heightmap = hmap
	setup_database(parameters)
	setup_completed.emit()


func setup_database(parameters: KuikkaTerrainGenParams):
	# Use preset database if defined.
	if parameters.database:
		height_database = parameters.database
	else:
		height_database = HeightSampleDB.new()
	
	# Automatically sort if not generated yet.
	if height_database.samples.is_empty():
		sort_height_samples(parameters)


## Sort height samples.
func sort_height_samples(parameters):
	# Use preset database if defined.
	if not height_database:
		height_database = parameters.database if parameters.database else HeightSampleDB.new()
	
	# Generate new database.
	var ref_fitnesses = parameters.area_fitness
	
	# Initialize empty data
	for agent in ref_fitnesses:
		height_database.samples.clear()
		height_database.samples[agent] = []
		# print_debug("Fitness <", agent,">")
	
	# Add each height sample to pool of best matching area.
	print_debug("Sorting image pools for agents.")
	
	var samples_total = height_database.unsorted_samples.size()
	for i in samples_total:
		var sample = height_database.unsorted_samples[i]
		var img = load(sample).get_image() # Image.load_from_file(sample)# 
		
		# HACK: Speed up evaluation by resizing images.
		img.resize(img.get_width()/4, img.get_height()/4)
		
		var key = evaluate_best_agent(img, ref_fitnesses)
		height_database.append_sample(key, sample)
		
		if i % 50 == 0:
			print_debug("Sorting height samples. Progress ", i, " / ", samples_total)
	
	ResourceSaver.save(height_database)
	
	print_debug("Database setup.")
	database_ready.emit()


## Initialize first generation of chromosome populations for agent areas.
func initialize_populations(parameters: KuikkaTerrainGenParams, areas: Dictionary):
	for agent in parameters.area_fitness:
		chromosomes[agent] = []
		
		print_debug("Generating population for ", agent)
		# Create population amount of chromosomes for each area.
		for i in parameters.population_size:
			var chr = Chromosome.new()
			chr.reference_fitness = parameters.area_fitness[agent]
			chr.sample_pool.append_array(height_database.get_samples(agent))
			chr.create_genes(areas[agent], seed, state)
			chromosomes[agent].append(chr)
	
	print_debug("Populations setup.")
	populations_generated.emit()


func run_evolution_process(parameters: KuikkaTerrainGenParams):
	print_debug("Started evolution process.")
	# run_evolution_process_single_thread(parameters)
	run_evolution_process_threaded(parameters)


## Run full evolution process for chromosomes and calculate resulting 
## heightmap in main thread with parameters specified by 
## given [KuikkaTerrainGenParams][param parameters].
func run_evolution_process_single_thread(parameters: KuikkaTerrainGenParams):
	_fittest.clear()
	
	# Run given amount of evolutions
	for gen in parameters.generations-1:
		print_debug("Running evolution process. Iteration %i" % gen)
		chromosomes = _evolution_step(parameters)
	
	for agent in chromosomes:
		# Get the strongest individual for region.
		_fittest[agent] = _evolve_population_by_agent(agent)[0]
	
	generate_result(_fittest)
	

## Generate resulting heightmap using fittest chromosomes for each population.
func generate_result(fittest: Dictionary) -> Image:
	
	for agent in fittest:
		var chromosome = fittest[agent]
		
		# Apply each gene effect to heightmap at given position.
		for gene : Gene in chromosome.genes:
			var result = gene.apply_genetic_operations(true)
			var rad = Vector2i(gene.radius, gene.radius)
			var source_rect = Rect2i(Vector2i.ZERO, 
								Vector2i(result.get_width(), result.get_height()))
			# result = KuikkaUtils.image_mult_alpha(result, gene.weight)
			
			# Create weighted blend mask
			var mask = Image.create(result.get_width(), result.get_height(), false, heightmap.get_format())
			mask.fill(Color(1, 1, 1, gene.weight))
			
			# Convert to match heightmap format.
			result.convert(heightmap.get_format())
			
			# Blend formats don't match
			heightmap.blend_rect_mask(result, mask, source_rect, Vector2i(gene.center-rad))
	
	heightmap_completed.emit(heightmap)
	return heightmap


## * * * * Single thread evolution * * * * 

## Run one generation step in evolution.
func _evolution_step(parameters: KuikkaTerrainGenParams) -> Dictionary:
	var new_generation = {}
	
	for agent in chromosomes:
		var parents = _evolve_population_by_agent(agent)
		new_generation[agent] = _generate_new_population(parameters, parents[0], parents[1])
		
	return new_generation

	
## Run evolution step for population of single agent.
## Returns two chromosomes deemed best fit parents for next population.
func _evolve_population_by_agent(agent: String) -> Array:
	print_debug("Running single generation evolution step for ", agent)
	var new_parents = []
	var population = chromosomes[agent]
	var fitness = []
	for chr in population:
		fitness.append(chr.evaluate_fitness())
	
	# Get best fit for parent
	var min_idx = fitness.find(fitness.min())
	new_parents.append(population[min_idx])
	fitness.remove_at(min_idx)
	
	# Get second best fit for parent
	min_idx = fitness.find(fitness.min())
	new_parents.append(population[min_idx])
	
	return new_parents
	
	
## Generate new chromosome population of size [param population_size] 
## as children of parents [param parent_a] and [param parent_b].
func _generate_new_population(parameters: KuikkaTerrainGenParams, 
				parent_a: Chromosome, parent_b: Chromosome) -> Array:
	var new_population = []
	var population_size = parameters.population_size
	
	# Population size is always rounded to even number.
	for n in ceil(population_size/2):
		var child_1: Chromosome = parent_a.duplicate()
		var child_2: Chromosome = parent_b.duplicate()
		child_1.sample_pool = parent_a.sample_pool
		child_2.sample_pool = parent_b.sample_pool
		
		# Crossover
		child_1.genes = []
		child_2.genes = []
		var split_a = _rng.randi_range(1, parent_a.genes.size()-2)
		var split_b = _rng.randi_range(1, parent_b.genes.size()-2)
		
		var start_seq_1 = parent_a.genes.slice(0, split_a)
		var end_seq_1 = parent_b.genes.slice(split_b, parent_b.genes.size()-1)
		
		var start_seq_2 = parent_b.genes.slice(0, split_b)
		var end_seq_2 = parent_a.genes.slice(split_a, parent_a.genes.size()-1)
										
		child_1.genes.append_array(start_seq_1)
		child_1.genes.append_array(end_seq_1)
		
		child_2.genes.append_array(start_seq_2)
		child_2.genes.append_array(end_seq_2)
	
		# Mutations
		for g in child_1.genes:
			if _rng.randf_range(0, 1) <= parameters.mutation_chance:
				_mutate_gene(g)
				
		for g in child_2.genes:
			if _rng.randf_range(0, 1) <= parameters.mutation_chance:
				_mutate_gene(g)
		
		# Add created children as part of the new population.
		new_population.append_array([child_1, child_2])
		
	return new_population


## * * * Threadpool evolution * * * 

## Run full evolution process for chromosomes and calculate resulting 
## heightmap in using threadpools with parameters specified by 
## given [KuikkaTerrainGenParams][param parameters].
func run_evolution_process_threaded(parameters: KuikkaTerrainGenParams):
	if _tasks_running:
		printerr("Cannot run genetic evolution! Another task is already running.")
		return
	_tasks_running = true
	
	print_debug("Starting evolution process with ", " generations: ", parameters.generations, 
	" population size: ", parameters.population_size)
	
	# Get list of agents with allocated chromosomes.
	_threadpool_keys = chromosomes.keys()
	_fittest.clear()
	_parameters = parameters
	
	
	# Run given generation amount of evolutions
	# and get the fittest of each population.
	var task = WorkerThreadPool.add_group_task(_run_evolution_gen_agent, _threadpool_keys.size())

	# Generate resulting heightmap
	# WorkerThreadPool.wait_for_group_task_completion(task)
	print_debug("Waiting for evolution to finish...")
	while not WorkerThreadPool.is_group_task_completed(task):
		await KuikkaTimer.create_timer(5).timeout
	
	print_debug("Finished evolution iterations.")
	
	generate_result(_fittest)
	_tasks_running = false
	
	heightmap_completed.emit(heightmap)
	return heightmap


func _run_evolution_gen_agent(index : int):
	var agent : String = _threadpool_keys[index]
	var population : Array = chromosomes[agent]
	var parameters = _parameters
	
	# Run given amount of evolutions
	for gen in parameters.generations-1:
		population = _evolution_step_agent(parameters, population)
	
	var fittest : Chromosome = _evolve_population(population)[0]
	
	# Save result in main thread on idle frame.
	_thread_save_result.call_deferred(agent, fittest)
	
	return fittest


func _evolution_step_agent(parameters: KuikkaTerrainGenParams, population: Array) -> Array:
	var new_generation = []
	
	var parents = _evolve_population(population)
	new_generation = _generate_new_population(parameters, parents[0], parents[1])
		
	return new_generation


## Run evolution step for population of single agent.
## Returns two chromosomes deemed best fit parents for next population.
func _evolve_population(population: Array) -> Array:
	var new_parents = []
	var fitness = []
	for chr in population:
		fitness.append(chr.evaluate_fitness())
	
	# Get best fit for parent
	var min_idx = fitness.find(fitness.min())
	new_parents.append(population[min_idx])
	fitness.remove_at(min_idx)
	
	# Get second best fit for parent
	min_idx = fitness.find(fitness.min())
	new_parents.append(population[min_idx])
	
	return new_parents

## Save resulting fittest chromosome from evolution process to [member _fittest].
## Can be used with call_deferred() from worker thread to save on main thread.
func _thread_save_result(agent: String, result: Chromosome):
	_fittest[agent] = result

## * * * * * * * * * * * * * * * * *


## Cause a operation or operation weight override mutation in given gene.
func _mutate_gene(g : Gene):
	if _rng.randi_range(1, 2) == 1:
		g.mutate_operation(g._rng.randf_range(0, g.genetic_operations.size()-1))
	else:
		g.mutate_operation_weight(g._rng.randf_range(0, g.genetic_operations.size()-1))


## Find best matching fitness for height sample from agent
## specific reference fitnesses.
func evaluate_best_agent(sample : Image, references: Dictionary):
	var best = ""
	var fittest = -1
	
	var results = []
	
	# Find best match for source height samples.
	for ref in references:
		# Offset fitness by size of already accumulated samples so that not all
		# samples are added under single agent even if biome types resemble
		# each other closely.
		var existing_samples = height_database.get_samples(ref).size()
		var fit = Fitness.calculate_img_fitness(sample, references[ref])
		var new_result = fit # +0.1*existing_samples
		
		# Set current as best choice if best is not selected yet or
		# current is better than last candidate.
		if fittest < 0 or new_result < fittest:	
			fittest = new_result
			best = ref
	
	return best


