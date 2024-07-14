extends VBoxContainer

var height_spec = preload("res://addons/kuikka_terrain_gen/ui/height_spec.tscn")
var feat_spec = preload("res://addons/kuikka_terrain_gen/ui/terrain_feature_specs.tscn")
var _tfi : TerrainFeatureImage

func update_feature_list(terrain_image):
	_tfi = terrain_image
	
	# Clear existing children
	for c in get_children():
		remove_child(c)
		c.queue_free()
	
	var hspec = height_spec.instantiate()
	add_child(hspec)
	hspec.set_height_profile(_tfi.height_profile)
	
	for fn in _tfi.features:
		var fspec = feat_spec.instantiate()
		add_child(fspec)
		fspec.set_feature(_tfi.features[fn])
