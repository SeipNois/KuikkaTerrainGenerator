@tool
extends Node3D

signal heightmap_changed

## Image to use as heightmap
@export var heightmap : Image = null:
	set(val):
		heightmap = val
		_on_heightmap_changed()

@export var control_map : Array = []:
	set(val):
		control_map = val
		_on_control_map_changed()


@export var ref_color_map : Image = null:
	set(val):
		ref_color_map = val
		_on_ref_hmap_changed()


@export var ref_heightmap: Image = null:
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
	
	ui.heightmap_changed.connect(func(hmap): heightmap = hmap)	
	ui.input_heightmap_changed.connect(func(hmap): ref_heightmap = hmap)	
	ui.height_range_changed.connect(func(s: Vector2): height_scale = s.y-s.x)
	ui.colormap_changed.connect(func(c: Array): control_map = c)
	ui.ref_gis_colormap_changed.connect(func(c): ref_color_map = c)
	ui.screen_shot.connect(_on_screen_shot)
	
	
func _input(event):
	if event.is_action_pressed("toggle_ui"):
		ui.visible = !ui.visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if ui.visible else Input.MOUSE_MODE_CAPTURED


## Reimport maps if heightmap changes
func _on_heightmap_changed():
	print_debug("Reimporting heightmap.")
	
	if terrain and heightmap:
		terrain.storage.import_images([heightmap, null, null], Vector3.ZERO, 0, height_scale)
		
	if not heightmap:
		print_debug("No heightmap")


func _on_control_map_changed():
	print_debug("Clearing control map data.")
	var maps = []
	maps.resize(terrain.storage.control_maps.size())
	terrain.storage.control_maps = maps

	terrain.storage.force_update_maps(Terrain3DStorage.TYPE_CONTROL)
	
	#await get_tree().process_frame
	
	print_debug("Reimporting control map data.")
	# Set water covered areas
	for p in control_map:
		terrain.storage.set_control(Vector3(p.x, 0, p.y), 
			KuikkaUtils.encode_terrain_3d_control([2, 0, 0, 0, 0, 0, 0, 0]))
	
	terrain.storage.force_update_maps(Terrain3DStorage.TYPE_CONTROL)


func _on_ref_hmap_changed():
	
	# Scale colormap to match heightmap
	if ref_heightmap and ref_color_map:
		if ref_color_map.get_width() != ref_heightmap.get_width() or \
		ref_color_map.get_height() != ref_heightmap.get_height():
			ref_color_map.resize(ref_heightmap.get_width(), ref_heightmap.get_height(), Image.INTERPOLATE_BILINEAR)
		
	if ref_heightmap and reference_terrain:
		reference_terrain.storage.import_images([ref_heightmap, null, ref_color_map], Vector3(1024, 0, 0), 0, height_scale)
		reference_terrain.storage.force_update_maps(Terrain3DStorage.TYPE_COLOR)

func _on_height_scale_changed():
	print_debug("Rescaling terrain.")

	if terrain and heightmap:
		terrain.storage.import_images([heightmap, null, null], Vector3.ZERO, 0, height_scale)
	
	if ref_heightmap and reference_terrain:
		reference_terrain.storage.import_images([ref_heightmap, null, null], Vector3(1024, 0, 0), 0, height_scale)


func _on_screen_shot():
	print_debug("Saving 3d screenshots for generation %s" % ui.img_name)
	var result = ui.img_name + "_3d"
	var ref = FilePath.get_filename(ui._selected_hmaps[0]) + "_3d"
	
	var result_path = ProjectSettings.globalize_path(ui.image_exports_path+result+".png")
	var ref_path = ProjectSettings.globalize_path(ui.image_exports_path+ref+".png")
	
	# Update subviews
	%SubViewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	%SubViewport2.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var img = %DemoCamera2.get_viewport().get_texture().get_image()
	var ref_img = %DemoCamera3.get_viewport().get_texture().get_image()
	
	img.save_png(result_path)
	ref_img.save_png(ref_path)
	
	print_debug("Screenshots saved.")
	return
