class_name KuikkaTerrainGenParams extends Resource

## Structure for holding parameters collected from user input for
## generating terrain.


@export var generation_seed : int = 0

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
## Array of agent type specific parameter collections.
@export var agents : Dictionary = {
	"KuikkaLakeAgent": KuikkaLakeParameters.new(),
	"KuikkaHillAgent": KuikkaHillParameters.new()
}
