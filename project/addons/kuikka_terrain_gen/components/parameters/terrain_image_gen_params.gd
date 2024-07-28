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
@export var start_level : float = 0.0

## Height scale to interpret 8-bit image values as 0-255 -> scale
@export var image_height_scale : Vector2 = Vector2(0, 255)

## Size of imported heightmap tiles.
var height_tile_size = 3000
## Size of GML formatted data sample tile.
var gml_tile_size = 6000
## Meters per pixel in heightmaps.
var pixel_size = 2

var point_size : int = 60
var population : int = 6
var generations : int = 3


@export_category("Image settings")
@export var image_format : Image.Format = Image.FORMAT_RGBA8# Image.FORMAT_RGBAH# 

@export var seed : int = 0
