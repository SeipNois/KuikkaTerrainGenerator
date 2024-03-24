@tool
extends Node3D

signal heightmap_changed

## Image to use as heightmap
@export var heightmap : Texture2D:
	set(val):
		heightmap = val
		heightmap_changed.emit()

## Terrain3D Node
@export var terrain : Terrain3D


# Called when the node enters the scene tree for the first time.
func _ready():
	if terrain:
		terrain.storage.add_region(Vector3.ZERO, [null, null, null])
		
		await heightmap.changed
		
		if heightmap:
			print_debug(heightmap.get_image())
			
			terrain.storage.import_images([heightmap.get_image(), null, null], Vector3.ZERO, 0, 1)
			
	heightmap_changed.connect(_on_heightmap_changed)


## Reimport maps if heightmap changes
func _on_heightmap_changed():
	await heightmap.changed
	if terrain and heightmap:
		terrain.storage.import_images([heightmap.get_image(), null, null], Vector3.ZERO, 0, 1)
		print_debug(heightmap.get_image())
		
	if not heightmap:
		print_debug("No heightmap")
