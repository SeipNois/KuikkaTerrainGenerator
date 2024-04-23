class_name KuikkaTerrainGenParams extends Resource

## Structure for holding parameters collected from user input for
## generating terrain.


@export_category("Map dimensions")
## Width of image to generate
@export var width : int = 512
## Height of image to generate
@export var height : int = 512
## Starting height for heightmap.
## TODO: Select channel which to use for height
@export var start_level : Color = Color.DARK_GRAY

@export_category("Image settings")
@export var image_format : Image.Format = Image.FORMAT_RGBA8

@export_category("Agent settings")

@export var generation_seed : int = 0

## Array of agent type specific parameter collections.
@export var agents : Dictionary = {
	"KuikkaLakeAgent": KuikkaLakeParameters.new(),
	"KuikkaHillAgent": KuikkaHillParameters.new()
}

@export_category("Genetic settings")
## Amount of generations in evolution process
@export var generations : int = 1
@export_range(2, 30) var population_size : int = 2
@export_range(300, 1000) var height_sample_size : int = 300
## Chance for mutation to occur in a gene.
@export_range(0.0, 1.0) var crossover_chance : float = 0.5
## Chance for mutation to occur in a gene.
@export_range(0.0, 1.0) var mutation_chance : float = 0.1
### Maximum amount of images used.
@export var image_pool_size : int = 10

@export var database : HeightSampleDB = preload("res://addons/kuikka_terrain_gen/db/height_db.tres")

## Reference fitness parameters for areas of each agent to use to
## define gene fitness for given area.
@export var area_fitness : Dictionary = {
	"KuikkaLakeAgent": FitnessParameters.new(),
	"KuikkaHillAgent": FitnessParameters.new()
}
