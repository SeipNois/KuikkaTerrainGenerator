class_name KuikkaHillAgent extends KuikkaTerrainAgent

## Agent that creates lakes, ponds and bodies of water.

## Agent specific parameter collection for generation features.
# var parameters : KuikkaHillParameters

var start_position: Vector2i = Vector2i.ZERO
var last_position: Vector2i = Vector2i.ZERO
var move_direction: Vector2 = Vector2.ZERO


func _init():
	agent_type = &"KuikkaHillAgent"


func _generation_process():
	# Blend at current position if above treshold
	if heightmap.get_pixel(last_position.x, last_position.y).r > parameters.generation_treshold:
		heightmap.blend_rect(brush,
							brush.get_used_rect(), 
							last_position-offset)
		gene_mask.blend_rect(brush,
							brush.get_used_rect(), 
							last_position-offset)
	
	area_silhouette.agent_travel[-1].add_point(last_position)
	
	# Add to covered area rect to silhouette.
	# _append_covered_points(last_position, offset)
	
	
	# Get next position, round new position to pixels.
	var speed = rng.randi_range(parameters.move_speed.x, parameters.move_speed.y)
	var new_pos: Vector2 = Vector2(last_position) + move_direction * speed
	last_position = Vector2i(new_pos)
	
	# Select new movement direction
	move_direction = move_direction.rotated(
									rng.randf_range(-parameters.direction_sway, 
													parameters.direction_sway))
	
	# Randomize new position if out of bounds or jump treshold is reached.
	if last_position.x < 0 or last_position.x > heightmap.get_width() or \
	last_position.y < 0 or last_position.y > heightmap.get_height() or \
	rng.randf_range(0, 1) < parameters.jump_treshold:
		
		last_position = Vector2i(rng.randi_range(offset.x, heightmap.get_width()-offset.x),
								rng.randi_range(offset.y, heightmap.get_height()-offset.y))
		# Add new curve when starting from new position.
		area_silhouette.agent_travel.append(Curve2D.new())
	
	tokens -= 1


## Setup intial position and start generation.
func start_generation():
	# Prepare agent starting state.
	tokens = parameters.initial_tokens
	rng.set_seed(seed)
	rng.set_state(state)
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
	_modulate_brush_alpha(parameters.blend_weight)
