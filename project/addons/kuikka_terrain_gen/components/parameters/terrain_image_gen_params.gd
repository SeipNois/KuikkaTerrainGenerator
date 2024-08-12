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
var height_tile_rect : Rect2 = Rect2(Vector2.ZERO, Vector2(3000, 3000))

## Set hegiht tile rectangle from array of [position, scale, rotation]
func set_height_tile_rect(values: Array):
	height_tile_rect.position = values[0]
	var size = values[1]
	
	if size.x < 0:
		height_tile_rect.position.x += size.x * 3000
		size.x *= -1
		
	if size.y < 0:
		height_tile_rect.position.y += size.y * 3000
		size.y  *= -1
	
	height_tile_rect.size = size * 3000
	
	
	## HACK: Rotation coefficient is always 0 as maps are not rotated so skip it.

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
