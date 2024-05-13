class_name KuikkaLakeAgent extends KuikkaTerrainAgent

## Agent that creates lakes, ponds and bodies of water.


## Agent specific parameter collection for generation features.
# var parameters : KuikkaLakeParameters

var start_position: Vector2i = Vector2i.ZERO
var last_position: Vector2i = Vector2i.ZERO
var move_direction: Vector2 = Vector2.ZERO


func _init():
	agent_type = &"KuikkaLakeAgent"


func _generation_process():
	# Update brush
	_update_brush_size(
		rng.randi_normal_dist(parameters["lake"].size_mean*2, 
								parameters["lake"].std_dev*2))
	
	# Blend at current position if within height threshold
	var h = heightmap.get_pixel(last_position.x, last_position.y).r * terrain_image.height_profile.height_range
	if h > parameters["lake"].gen_height_min and \
	h < parameters["lake"].gen_height_max:
		
		# Flatten base area
		var region = heightmap.get_region(Rect2i(last_position-offset, offset*2))
		var flat_h = Fitness.img_get_mean(region)
		
		var flat = Image.create(offset.x*2, offset.y*2, false, heightmap.get_format())
		heightmap.blend_rect_mask(flat, 
									brush,
									flat.get_used_rect(), 
									last_position-offset)
		
		area_silhouette.agent_travel[-1].add_point(last_position)
		
		# Make deeper "holes" within silhouette of given flattened area.
		var main_size = brush_size
		
		for i in ceil(main_size / 100):
			var center = last_position
			var small_size = rng.randi_range(parameters["lake"].size_min*2, brush_size)
			_update_brush_size(small_size)
			# TODO: Handle offset treshold based on generation data
			center.x += round(main_size.x/2 * rng.randi_range(-0.75, 0.75))
			center.y += round(main_size.y/2 * rng.randi_range(-0.75, 0.75))
			
			heightmap.blend_rect(brush,
						brush.get_used_rect(), 
						center-offset)
			gene_mask.blend_rect(brush,
						brush.get_used_rect(), 
						last_position-offset)

	## Randomize new lake location.
	last_position = Vector2i(rng.randi_range(offset.x, heightmap.get_width()-offset.x),
							rng.randi_range(offset.y, heightmap.get_height()-offset.y))
	## Add new curve when starting from new position.
	area_silhouette.agent_travel.append(Curve2D.new())
	tokens -= 1

	## FIXME: Old code 

	## Blend at current position if within height threshold
	#var h = heightmap.get_pixel(last_position.x, last_position.y).r * terrain_image.height_profile.height_range
	#if h > parameters["lake"].gen_height_min and \
	#h < parameters["lake"].gen_height_max:
		#heightmap.blend_rect(brush,
							#brush.get_used_rect(), 
							#last_position-offset)
		#gene_mask.blend_rect(brush,
					#brush.get_used_rect(), 
					#last_position-offset)
	#
	#area_silhouette.agent_travel[-1].add_point(last_position)
	#
	## Add to covered area to silhouette.
	## _append_covered_points(last_position, offset)
	#
	## Get next position, round new position to pixels.
	#var speed = rng.randi_range(parameters.move_speed.x, parameters.move_speed.y)
	#var new_pos: Vector2 = Vector2(last_position) + move_direction * speed
	#last_position = Vector2i(new_pos)
	#
	## Select new movement direction
	#move_direction = move_direction.rotated(
									#rng.randf_range(-parameters.direction_sway, 
													#parameters.direction_sway))
	#
	## Randomize new position if out of bounds or jump treshold is reached.
	#if last_position.x < 0 or last_position.x > heightmap.get_width() or \
	#last_position.y < 0 or last_position.y > heightmap.get_height() or \
	#rng.randi_range(0, 1) < parameters.jump_treshold:
		#
		#last_position = Vector2i(rng.randi_range(offset.x, heightmap.get_width()-offset.x),
								#rng.randi_range(offset.y, heightmap.get_height()-offset.y))
		## Add new curve when starting from new position.
		#area_silhouette.agent_travel.append(Curve2D.new())
	#
	#tokens -= 1


## Setup intial position and start generation.
func start_generation():
	# Prepare agent starting state.
	parameters = { "lake": terrain_image.features["jarvi"] }
	
	# TODO: Density has to be 
	tokens = parameters["lake"].density
	rng.set_seed(seed)
	rng.set_state(state)
	
	brush_size = rng.randi_normal_dist(parameters["lake"].size_mean*2, parameters["lake"].std_dev*2)
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
			brush.set_pixel(x, y, Color(0, 0, 0, brush.get_pixel(x, y).a * parameters.blend_weight))


func _update_brush_size(size):
	brush.resize(size, size)

