class_name KuikkaLakeAgent extends KuikkaTerrainAgent

## Agent that creates lakes, ponds and bodies of water.

## Offset for blending brush rect centered around point.
var offset = Vector2i(brush_size/2, brush_size/2)

## Agent specific parameter collection for generation features.
var parameters : KuikkaLakeParameters

var start_position: Vector2i = Vector2i.ZERO
var last_position: Vector2i = Vector2i.ZERO
var move_direction: Vector2 = Vector2.ZERO


func _init():
	agent_type = &"KuikkaLakeAgent"


func _generation_process():
	# Blend at current position if under treshold
	if heightmap.get_pixel(last_position.x, last_position.y).r < parameters.generation_treshold:
		heightmap.blend_rect(brush,
							brush.get_used_rect(), 
							last_position-offset)
	
	area_silhouette[-1].add_point(last_position)
	
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
	rng.randi_range(0, 1) < parameters.jump_treshold:
		
		last_position = Vector2i(rng.randi_range(offset.x, heightmap.get_width()-offset.x),
								rng.randi_range(offset.y, heightmap.get_height()-offset.y))
		# Add new curve when starting from new position.
		area_silhouette.append(Curve2D.new())
	
	tokens -= 1


## Setup intial position and start generation.
func start_generation():
	# Prepare agent starting state.
	tokens = parameters.initial_tokens
	rng.set_seed(seed)
	rng.set_state(state)
	_load_brush()
	
	start_position = Vector2i(rng.randi_range(offset.x, heightmap.get_width()-offset.x),
								rng.randi_range(offset.y, heightmap.get_height()-offset.y))
	last_position = start_position
	move_direction = Vector2i(rng.randi_range(-1, 1),
								rng.randi_range(-1, 1))
	
	area_silhouette.append(Curve2D.new())
	
	# Start generation.
	super.start_generation()


func _load_brush():
	brush = Image.load_from_file("res://addons/kuikka_terrain_gen/brushes/128_gaussian.png")
	brush.resize(brush_size, brush_size)
	
	# Flip brush to black for lakes
	for x in brush.get_width():
		for y in brush.get_height():
			brush.set_pixel(x, y, Color(0, 0, 0, brush.get_pixel(x, y).a * parameters.blend_weight))
	
