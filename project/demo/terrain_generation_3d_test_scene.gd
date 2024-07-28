@tool
extends Node3D

signal heightmap_changed

## Image to use as heightmap
@export var heightmap : Image:
	set(val):
		heightmap = val
		_on_heightmap_changed()


@export var ref_heightmap: Image:
	set(val):
		ref_heightmap = val
		_on_ref_hmap_changed()


@export var height_scale : float = 255:
	set(val):
		height_scale = val
		_on_height_scale_changed()


## Terrain3D Node
@export var terrain : Terrain3D
@export var reference_terrain : Terrain3D


@onready var ui = %TerrainGenUI


# Called when the node enters the scene tree for the first time.
func _ready():
	if terrain:
		terrain.storage.add_region(Vector3.ZERO, [null, null, null])
		terrain.storage.add_region(Vector3(1024, 0, 0), [null, null, null])
		
		if heightmap:
			print_debug(heightmap)
			
			terrain.storage.import_images([heightmap, null, null], Vector3.ZERO, 0, 1)
	
		var material = terrain.material
		terrain.material = material
	
	%TerrainGenUI.heightmap_changed.connect(func(hmap): heightmap = hmap)	
	%TerrainGenUI.input_heightmap_changed.connect(func(hmap): ref_heightmap = hmap)	
	%TerrainGenUI.height_range_changed.connect(func(s: Vector2): height_scale = s.y-s.x)
	
	
func _input(event):
	if event.is_action_pressed("toggle_ui"):
		%TerrainGenUI.visible = !%TerrainGenUI.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if %TerrainGenUI.visible else Input.MOUSE_MODE_CAPTURED


## Reimport maps if heightmap changes
func _on_heightmap_changed():
	print_debug("Reimporting heightmap.")
	
	if terrain and heightmap:
		terrain.storage.import_images([heightmap, null, null], Vector3.ZERO, 0, height_scale)
		
	if not heightmap:
		print_debug("No heightmap")

func _on_ref_hmap_changed():
	
	if ref_heightmap and reference_terrain:
		reference_terrain.storage.import_images([ref_heightmap, null, null], Vector3(1024, 0, 0), 0, height_scale)


func _on_height_scale_changed():
	print_debug("Rescaling terrain.")

	if terrain and heightmap:
		terrain.storage.import_images([heightmap, null, null], Vector3.ZERO, 0, height_scale)
	
	if ref_heightmap and reference_terrain:
		reference_terrain.storage.import_images([ref_heightmap, null, null], Vector3(1024, 0, 0), 0, height_scale)
