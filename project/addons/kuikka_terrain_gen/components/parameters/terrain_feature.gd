## Structure representing generation parameters for single terrain feature.
class_name TerrainFeature extends Resource
@export var feature_name : StringName
@export var density : float = 0
@export var size_min : float = 0
@export var size_max : float = 0
@export var size_mean : float = 0
@export var size_median : float = 0
@export var size_std_dev : float = 0

@export var gen_height_min : float = 0
@export var gen_height_max : float = 0
@export var gen_height_mean : float = 0
@export var gen_height_median : float = 0
@export var gen_height_std_dev : float = 0

## Compare towards terrain feature generation values.
func compare(ref: TerrainFeature):
	return abs(size_min-ref.size_min) + \
	abs(size_max-ref.size_max) + \
	abs(size_mean-ref.size_mean) +\
	abs(size_median-ref.size_median)+\
	abs(size_std_dev-ref.size_std_dev)+ \
	
	abs(gen_height_min-ref.gen_height_min) + \
	abs(gen_height_max-ref.gen_height_max) + \
	abs(gen_height_mean-ref.gen_height_mean) +\
	abs(gen_height_median-ref.gen_height_median)+\
	abs(gen_height_std_dev-ref.gen_height_std_dev)

# Sum current values to parameter feature values.
func sum(ref: TerrainFeature):
	ref.density += density
	
	ref.size_min += size_min
	ref.size_max += size_max
	ref.size_mean += size_mean 
	ref.size_median += size_median 
	ref.size_std_dev += size_std_dev 
	
	ref.gen_height_min += gen_height_min
	ref.gen_height_max += gen_height_max
	ref.gen_height_mean += gen_height_mean
	ref.gen_height_median += gen_height_median 
	ref.gen_height_std_dev += gen_height_std_dev
	
	return ref

# Divide all property values by value. Useful for TerrainFeature
# average calculation.
func divide_by(value: float):
	density /= value
	
	size_min /= value
	size_max /= value
	size_mean /= value 
	size_median /= value 
	size_std_dev /= value 
	
	gen_height_min /= value
	gen_height_max /= value
	gen_height_mean /= value
	gen_height_median /= value 
	gen_height_std_dev /= value
	
	return self


func get_properties():
	return {
			"density": density, 
			"size_min": size_min, 
			"size_max": size_max, 
			"size_mean": size_mean, 
			"size_median": size_median, 
			"size_std_dev": size_std_dev,
			"gen_height_min": gen_height_min, 
			"gen_height_max": gen_height_max, 
			"gen_height_mean": gen_height_mean, 
			"gen_height_median": gen_height_median, 
			"gen_height_std_dev": gen_height_median
			}
