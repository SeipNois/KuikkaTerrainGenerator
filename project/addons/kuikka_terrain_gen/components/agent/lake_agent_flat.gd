class_name KuikkaLakeAgentFlat extends KuikkaTerrainAgent

## Agent that creates lakes, ponds and bodies of water.


## Agent specific parameter collection for generation features.
# var parameters : KuikkaLakeParameters

var start_position: Vector2i = Vector2i.ZERO
var last_position: Vector2i = Vector2i.ZERO
var move_direction: Vector2 = Vector2.ZERO

var mask = preload("res://addons/kuikka_terrain_gen/brushes/128_gaussian.png").get_image()


func _init():
	agent_type = &"KuikkaLakeAgent"
	gene_placement = GeneDistribute.NONE

func _generation_process():
	# Update brush
	var new_size = rng.randi_normal_dist(parameters["lake"].size_mean*2, 
								parameters["lake"].size_std_dev*2)
	
	new_size = clamp(new_size, 0, heightmap.get_width())
	_update_brush_size(new_size)
	
	# Blend at current position if within height threshold
	var rang = terrain_image.height_profile.represent_range
	var h = rang.x + heightmap.get_pixel(last_position.x, last_position.y).r \
															* (rang.y-rang.x)
	
	# print_debug(h, " ", parameters["lake"].gen_height_min, 
	#		" ", parameters["lake"].gen_height_max)
	
	if last_position.x > 0 and last_position.x < heightmap.get_width() and \
	last_position.y > 0 and last_position.y < heightmap.get_height() and\
	h > parameters["lake"].gen_height_min and \
	h < parameters["lake"].gen_height_max:
		
		# Flatten base area
		var region = heightmap.get_region(Rect2i(last_position-offset, offset*2))
		var flat_h = Fitness.img_get_mean(region)
		
		var flat = Image.create(brush.get_width(), brush.get_height(), false, heightmap.get_format())
		mask.resize(flat.get_width(), flat.get_height())
		flat.fill(Color(flat_h, flat_h, flat_h, 1))
		#flat = KuikkaImgUtil.images_blend_alpha(flat, mask)
		var m = brush.duplicate()
		m = KuikkaImgUtil.image_mult_alpha(m, 1.3)
		#heightmap.blend_rect_mask(flat, m, flat.get_used_rect(), last_position-offset)
		heightmap = KuikkaImgUtil.blend_rect_sum_mask(heightmap, flat, m, flat.get_used_rect(), last_position-offset)
		#heightmap = KuikkaImgUtil.blend_rect_diff_mask(heightmap, flat, brush, 
		#						flat.get_used_rect(), last_position-offset, 1)
		
		area_silhouette.agent_travel[-1].add_point(last_position)
		
		# Make deeper "holes" within silhouette of given flattened area.
		var main_size = brush_size
		
		# Flatten as cluster around current area
		for i in ceil(main_size / 100):
			var center = last_position
			var small_size = rng.randi_range(parameters["lake"].size_min*2, brush_size)
			_update_brush_size(small_size)
			# TODO: Handle offset treshold based on generation data
			center.x += round(main_size/2 * rng.randi_range(-0.75, 0.75))
			center.y += round(main_size/2 * rng.randi_range(-0.75, 0.75))
			
			# Flatten towards main area center height
			flat_h = heightmap.get_pixel(last_position.x, last_position.y).r
			
			flat.resize(small_size, small_size)
			flat.fill(Color(flat_h, flat_h, flat_h))
			mask.resize(flat.get_width(), flat.get_height())
			#flat = KuikkaImgUtil.images_blend_alpha(flat, mask)
			#flat = KuikkaImgUtil.image_mult_alpha(flat, 1.2)
			
			#heightmap = KuikkaImgUtil.blend_rect_diff_mask(heightmap, flat, brush,
			#					flat.get_used_rect(), last_position-offset, 0.5)
			#heightmap.blend_rect_mask(flat, m, flat.get_used_rect(), last_position-offset)
			heightmap = KuikkaImgUtil.blend_rect_sum_mask(heightmap, flat, m, flat.get_used_rect(), last_position-offset)
			gene_mask.blend_rect(brush,
						brush.get_used_rect(), 
						last_position-offset)
			
		tokens -= 2
	# Reduced token consumption if unsuccessful
	else:
		tokens -= 1
	
	var feat = parameters["lake"]
	var speed = rng.randi_range_weighted(feat.size_min, feat.size_max, feat.size_mean, feat.size_std_dev)
	var new_pos: Vector2 = Vector2(last_position) + move_direction * speed
	last_position = Vector2i(new_pos)
		
		# Randomize new position if out of bounds or jump treshold is reached.
	if last_position.x < 0 or last_position.x >= heightmap.get_width() or \
	last_position.y < 0 or last_position.y >= heightmap.get_height() \
	# TODO: Jump treshold
	or rng.randf_range(0, 1) < 0.3:
		
		last_position = Vector2i(rng.randi_range(offset.x, heightmap.get_width()-offset.x),
								rng.randi_range(offset.y, heightmap.get_height()-offset.y))
		# Add new curve when starting from new position.
		area_silhouette.agent_travel.append(Curve2D.new())
	
	### Randomize new lake location.
	#last_position = Vector2i(rng.randi_range(offset.x, heightmap.get_width()-offset.x),
							#rng.randi_range(offset.y, heightmap.get_height()-offset.y))
							
	## Add new curve when starting from new position.
	area_silhouette.agent_travel.append(Curve2D.new())
	generation_step.emit()


## Setup intial position and start generation.
func start_generation():
	# Prepare agent starting state.
	
	# Use either lake or sea based on which has more occurences
	var lake = terrain_image.features["jarvi"]
	var sea = terrain_image.features["meri"]
	var result = sea if sea.density > lake.density else lake
	
	parameters = { "lake": result }
	
	# Double tokens to consume 2 when successful and only one if 
	# failing to generate.
	tokens = round(parameters["lake"].density) * 2
	rng.set_seed(seed)
	rng.set_state(state)
	
	brush_size = rng.randi_normal_dist(parameters["lake"].size_mean*2, parameters["lake"].size_std_dev*2)
	_load_brush()
	
	gene_mask = Image.create(heightmap.get_width(), heightmap.get_height(), false, heightmap.get_format())
	
	start_position = Vector2i(rng.randi_range(offset.x, heightmap.get_width()-offset.x),
								rng.randi_range(offset.y, heightmap.get_height()-offset.y))
	last_position = start_position
	move_direction = Vector2i(rng.randi_range(-1, 1),
								rng.randi_range(-1, 1))
	
	area_silhouette.agent_travel.append(Curve2D.new())
	
	# Start generation.
	super.start_generation()


func _load_brush():
	brush = preload("res://addons/kuikka_terrain_gen/brushes/128_gaussian.png").get_image()
	brush.resize(brush_size, brush_size)
	
	# Flip brush to black for lakes
	for x in brush.get_width():
		for y in brush.get_height():
			# TODO: Blend weight
			brush.set_pixel(x, y, Color(0, 0, 0, brush.get_pixel(x, y).a * blend_multiplier))


