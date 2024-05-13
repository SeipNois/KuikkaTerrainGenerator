class_name TerrainFeatureImage extends Resource

## Data structure defining generation settings based on 
## features extracted from National Land Survey data.


## Height feature profile to save heightmap data.
class HeightProfile:
	@export var min : float
	@export var max : float
	@export var mean : float
	@export var median : float
	@export var kurtosis : float
	@export var std_dev : float
	# g > 0 "leaning" to left, g < 0 "leaning" to right
	@export var skewness : float
	@export var entropy : float
	@export var contrast : float
	@export var correlation : float
	@export var height_range : float
	
	# Calculate comparison value for reference HeightProfile, based on
	## how much values for each differ from each other.
	func compare(ref: HeightProfile):
		return abs(min-ref.min) + abs(max-ref.max) + abs(mean-ref.mean) +\
		abs(median-ref.median)+abs(std_dev-ref.std_dev)


## Structure representing generation parameters for single terrain feature.
class TerrainFeature:
	@export var feature_name : StringName
	@export var density : float
	@export var size_min : float
	@export var size_max : float
	@export var size_mean : float
	@export var size_median : float
	@export var size_std_dev : float
	
	@export var gen_height_min : float
	@export var gen_height_max : float
	@export var gen_height_mean : float
	@export var gen_height_median : float
	@export var gen_height_std_dev : float


var height_profile : HeightProfile

## Dictionary of TerrainFeature entries
@export var features : Dictionary = {
	
}

var generation_seed : int = 0

## Set feature to value.
func set_feature(name:StringName, value:TerrainFeature):
	features[name] = value


## Set feature property value.
func set_feature_param(name:StringName, property: StringName, value):
	if features.has(name):
		features[name].set(property, value)
