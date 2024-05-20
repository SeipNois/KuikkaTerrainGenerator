class_name Chromosome extends Resource

static var GENETIC_OPERATIONS = [GeneticOperationRise, GeneticOperationLower, 
								GeneticOperationShiftX, GeneticOperationShiftY]

@export var reference_fitness : FitnessParameters
@export var ref_image : TerrainFeatureImage

## Array of filepaths to height sample images.
@export var sample_pool : Array[String] = []

@export var genes: Array[Gene] = []

@export var gene_placements : Dictionary

## [float] representing fitness of chromosome as comparison value against
## other fitness values. The smaller the value the closer result is to
## required and thus the
var chromosome_fitness : float = -1

var _rng : RandomNumberGenerator = RandomNumberGenerator.new()

const TEMP_PATH : String = "res://generated/gene_processed/"


func create_genes(points : Dictionary, seed: int, state: int, heightmap: Image):
	_rng.set_seed(seed)
	_rng.set_state(state)
	
	gene_placements = points
	var used_indexes = []
	
	var index = _rng.randi_range(0, sample_pool.size()-1)
	
	# print_debug(gene_placements.gene_points)
	
	# Place genes
	
	
	# Place genes
	for y in range(0, heightmap.get_height(), 80):
		for x in range(0, heightmap.get_width(), 80):
			var p = Vector2(x, y)
			var w = gene_placements.gene_mask.get_pixel(p.x, p.y).a
			
			if sample_pool.size() == 0:
				printerr("Chromosome sample pool size is 0! Can't appoint samples for genes.")
			
			if w > 0:
				var sample = sample_pool[index]
				var g = Gene.new(p, 64, w, sample, _rng.randi())
				genes.append(g)
				
				index = _rng.randi_range(0, sample_pool.size()-1)
			else:
				print_debug("Skipping position ", p, " in gene mask.")
		
		
	#for i in gene_placements.gene_points.size():
#
		#var p = gene_placements.gene_points[i]
		#var w = gene_placements.gene_weights[i]
		#
		#if sample_pool.size() == 0:
			#printerr("Chromosome sample pool size is 0! Can't appoint samples for genes.")
			#
		## used_indexes.append(index)
#
		#var sample = sample_pool[index]
		#var g = Gene.new(p, 64, w, sample, _rng.randi())
		#genes.append(g)
		#
		#index = _rng.randi_range(0, sample_pool.size()-1)
		#
		
		
		## FIXME: Allow use of same sample several times.
		# Don't use same index twice
		#while used_indexes.find(index):
			#index = _rng.randi_range(0, sample_pool.size()-1)
			## print_debug(index)
		

## Calculate fitness values for single [Gene][param gene]
func calculate_gene_fitness(gene: Gene) -> float:
	var hmap = gene.apply_genetic_operations()
	return Fitness.calculate_img_fitness(hmap, reference_fitness)


## Evaluate fitness of [Chromosome] based on its genes fitness and
## reference [FitnessParameters].
func evaluate_fitness() -> float:
	var fitnesses = []
	
	# Calculate fitness of each gene.
	for g in genes:
		fitnesses.append(calculate_gene_fitness(g))

	# Get average fitness for chromosome.
	chromosome_fitness = KuikkaUtils.mean(fitnesses)
	
	# Result should be positive value.
	if chromosome_fitness == -1:
		printerr("Chromosome fitness was not calculated correctly!")
	
	return chromosome_fitness

## * * * * * * * * * * * * * * * * * * * * * * * * 
## [TerrainFeatureImage.HeightProfile] based fitness 


## Evaluate fitness of [Chromosome] based on its genes fitness and
## reference [FitnessParameters].
func evaluate_height_profile() -> float:
	var fitnesses = []
	
	# Calculate fitness of each gene.
	for g in genes:
		fitnesses.append(await calculate_gene_height_profile(g))

	# Get average fitness for chromosome.
	chromosome_fitness = KuikkaUtils.mean(fitnesses)
	
	# Result should be positive value.
	if chromosome_fitness == -1:
		printerr("Chromosome fitness was not calculated correctly!")
	
	return chromosome_fitness


func calculate_gene_height_profile(gene: Gene) -> float:
	var hmap = gene.apply_genetic_operations()
	var stats = await TerrainParser._parse_heightmap(TEMP_PATH+str(gene.get_instance_id())+".png")
	
	if not stats or not stats.is_valid():
		return 1000000000000
	
	# Remove temp file.
	# if FileAccess.file_exists(temp_path):
	# 	OS.move_to_trash(temp_path)
		
	return ref_image.height_profile.compare(stats)
