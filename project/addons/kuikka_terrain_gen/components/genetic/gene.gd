class_name Gene extends Resource

## Use gaussian mask to blend gene effect around it.
var blend_mask : Image = preload("res://addons/kuikka_terrain_gen/brushes/128_gaussian.png").get_image()

@export_category("Common Features")
## Center of area of effect of this gene.
@export var center : Vector2i

## Radius of area of effect for gene.
@export var radius : float

## Weight of mask blending. [member blend_mask] alpha channel will be
## multiplied by this value when blending to heightmap.
@export_range(0, 1) var weight : float

@export_category("Genetic Operations")
## File path of height sample to use as basis for calculating result
## with operations.
@export var height_sample : String
@export var genetic_operations : Array[GeneticOperation]

#var _processed_sample : Image

var _rng = RandomNumberGenerator.new()


func _init(c:=Vector2i.ZERO, r:=1.0, w:=1.0, img_path:String="", op_seed: int=0):
	center = c
	# Radius should be at least 1 pixel to be able to resize mask image.
	radius = max(r, 1)
	# blend_mask = preload("res://addons/kuikka_terrain_gen/brushes/128_gaussian.png").get_image()
	weight = w
	
	blend_mask.resize(radius*2, radius*2)
	# blend_mask = KuikkaUtils.image_mult_alpha(blend_mask, 0.3)
	height_sample = img_path
	
	_rng.set_seed(op_seed)
	_rng.set_state(0)
	
	# Generate operations
	setup_operations()


## Randomly generate genetic operations for gene.
func setup_operations():
	var amo = _rng.randi_range(0, 5)
	
	for i in amo:
		var op = _rng.randi_range(0, Chromosome.GENETIC_OPERATIONS.size()-1)
		var gen_op : GeneticOperation = Chromosome.GENETIC_OPERATIONS[op].new()
		gen_op.strength = _rng.randf_range(0.0, 1.0)
		genetic_operations.append(gen_op)


## Process given height sample from file [member height_sample] 
## through genetic operations and return resulting [Image].
func apply_genetic_operations(apply_weights:=false) -> Image:
	var _sample: Image = load(height_sample).get_image()
	var path = Chromosome.TEMP_PATH+str(get_instance_id())+".png"
	
	# Save original height sample as image.
	_sample.save_png(path)
	
	_sample.resize(radius*2, radius*2)
	
	# Apply operations
	for op in genetic_operations:
		#_sample = op.apply_operation(_sample)
		op.apply_operation_path(path)
	
	if not apply_weights:
		return _sample
	
	# Blend height sample with mask and gene weights.
	var format = _sample.get_format()
	var size = radius*2
	var origin = Vector2i.ZERO + round(size - _sample.get_width())
	var rect = Rect2i(origin, Vector2i(_sample.get_width(), _sample.get_height()))
						
	var _processed_sample = Image.create(size, size, false, _sample.get_format())
	_processed_sample.blend_rect_mask(_sample, blend_mask, rect, Vector2i.ZERO)

	return _processed_sample


## Mutate genetic operation by replacing with new operation.
func mutate_operation(index: int) -> void:
	var op = _rng.randi_range(0, Chromosome.GENETIC_OPERATIONS.size()-1)
	var gen_op : GeneticOperation = Chromosome.GENETIC_OPERATIONS[op].new()
	gen_op.strength = _rng.randf_range(0.0, 1.0)
	genetic_operations[index] = gen_op
	return


## Mutate genetic operation effect scale by replacing operation strength value.
func mutate_operation_weight(index: int) -> void:
	genetic_operations[index].strength = _rng.randf_range(0.0, 1.0)
	return
