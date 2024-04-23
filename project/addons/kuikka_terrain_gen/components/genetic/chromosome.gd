class_name Chromosome extends Resource

static var GENETIC_OPERATIONS = [GeneticOperationRise, GeneticOperationLower, 
								GeneticOperationShiftX, GeneticOperationShiftY]

@export var reference_fitness : FitnessParameters
## Array of filepaths to height sample images.
@export var sample_pool : Array[String] = []

@export var genes: Array[Gene] = []

@export var gene_placements : Dictionary

## [float] representing fitness of chromosome as comparison value against
## other fitness values. The smaller the value the closer result is to
## required and thus the
var chromosome_fitness : float = -1

var _rng : RandomNumberGenerator = RandomNumberGenerator.new()


func create_genes(points : Dictionary, seed: int, state: int):
	_rng.set_seed(seed)
	_rng.set_state(state)
	
	gene_placements = points
	var used_indexes = []
	
	var index = _rng.randi_range(0, sample_pool.size()-1)
	
	# print_debug(gene_placements.gene_points)
	
	# Place genes
	for i in gene_placements.gene_points.size():

		var p = gene_placements.gene_points[i]
		var w = gene_placements.gene_weights[i]
		
		if sample_pool.size() == 0:
			printerr("Chromosome sample pool size is 0! Can't appoint samples for genes.")
			
		used_indexes.append(index)

		var sample = sample_pool[index] if index >= 0 else Image.new()
		var g = Gene.new(p, 64, w, sample, _rng.randi())
		genes.append(g)
		
		# Don't use same index twice
		while used_indexes.find(index):
			index = _rng.randi_range(0, sample_pool.size()-1)
			# print_debug(index)
		

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
