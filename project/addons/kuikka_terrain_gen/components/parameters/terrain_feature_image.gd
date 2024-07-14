class_name TerrainFeatureImage extends Resource

## Data structure defining generation settings based on 
## features extracted from National Land Survey data.


var height_profile : HeightProfile

## Dictionary of TerrainFeature entries
@export var features : Dictionary = {
	
}

var generation_seed : int = 0
var database : HeightSampleDB = HeightSampleDB.new()
var evolution = {
	"generations" : 3,
	"population_size" : 6,
	"mutation_chance": 0.2,
	"gene_point_size": 5
}

## Set feature to value.
func set_feature(name:StringName, value:TerrainFeature):
	features[name] = value


## Set feature property value.
func set_feature_param(name:StringName, property: StringName, value):
	if features.has(name):
		features[name].set(property, value)
