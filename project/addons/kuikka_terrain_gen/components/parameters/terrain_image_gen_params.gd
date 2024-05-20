class_name ImageGenParams extends Node

## Parameter collection for parameters related 
## to creating heightmap image.

@export_category("Map dimensions")
## Width of image to generate
@export var width : int = 512
## Height of image to generate
@export var height : int = 512
## Starting height for heightmap.
## TODO: Select channel which to use for height
@export var start_level : Color = Color.DARK_GRAY

## Size of imported heightmap tiles.
var height_tile_size = 3000
## Size of GML formatted data sample tile.
var gml_tile_size = 6000
## Meters per pixel in heightmaps.
var pixel_size = 2


@export_category("Image settings")
@export var image_format : Image.Format = Image.FORMAT_RGBA8

@export var seed : int = 0
