class_name KuikkaLakeAgentFlood extends KuikkaTerrainAgent

## Agent that creates lakes, ponds and bodies of water.


## Agent specific parameter collection for generation features.
# var parameters : KuikkaLakeParameters

const HMAP_TEMP = "res://generated/hmap_temp.png"
const ERODE_TEMP = "res://generated/hmap_erode_temp.png"
const DILATE_TEMP = "res://generated/hmap_dilate_temp.png"

var start_position: Vector2i = Vector2i.ZERO
var last_position: Vector2i = Vector2i.ZERO
var move_direction: Vector2 = Vector2.ZERO

var mask = preload("res://addons/kuikka_terrain_gen/brushes/128_gaussian.png").get_image()

## Queue for flood fill 
var queue : Array[Vector2i] = []

## Already processed items for flood fill
var processed : Dictionary = {}

## Calculated local minima to use for "filling" with water.
var local_minima : Dictionary = {}

## Calculated local maxima used to prevent water level rising too high.
var local_maxima : Dictionary = {}

## local_minima.keys() sorted into rising order by local_minima[key] value.
var sorted_minima : Array

var sorted_maxima : Array

var color_map_index = Color(3/255, 0, 0)


func _init():
	agent_type = &"KuikkaLakeAgent"
	gene_placement = GeneDistribute.NONE
	
	## Coastline as series of pixels.
	area_silhouette["coast_line"] = [] # Vector2i


func _generation_process():
	# Stop generation if minima sites have been exhausted.
	if local_minima.keys().size() == 0:
		tokens = 0
		generation_step.emit()
		return
	
	# Update brush
	var new_size = rng.randi_normal_dist(parameters["lake"].size_mean*2, 
								parameters["lake"].size_std_dev*2)
	
	new_size = clamp(new_size, 0, heightmap.get_width())
	_update_brush_size(new_size)
	
	## Randomize new lake location.
	#last_position = Vector2i(rng.randi_range(offset.x, heightmap.get_width()-offset.x),
							#rng.randi_range(offset.y, heightmap.get_height()-offset.y))
	
	# get random minima (weighted to prioritize lower ones)
	var pos_index = rng.randi_range_weighted(0, local_minima.keys().size(), local_minima.keys().size()/3, local_minima.keys().size()/10)
	
	# Prioritize lowest minimas.
	last_position = local_minima.keys()[pos_index]
	
	# Site has been changed by another lake generation. Remove and try again.
	if local_minima[last_position] != heightmap.get_pixel(last_position.x, last_position.y).r:
		local_minima.erase(last_position) 
		sorted_minima.erase(last_position)
		tokens -= 1
		generation_step.emit()
		return
		
							
	## Add new curve when starting from new position.
	area_silhouette.agent_travel.append(Curve2D.new())
	
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
		
		# Use flood fill to fill around area.
		#var surface_height = (rng.randi_normal_dist(
		#							parameters["lake"].gen_height_mean,
		#							parameters["lake"].gen_height_std_dev) - rang.x) / (rang.y-rang.x)
		
		var start = last_position-offset
		var end = offset*2
		
		# Cap area outside image.
		if start.x < 0:
			end.x += abs(start.x)
			start.x = 0
		if start.y < 0:
			end.y += abs(start.y)
			start.y = 0
		
		var region = heightmap.get_region(Rect2i(start, end))
		var surface_height = Fitness.img_get_mean(region)
		var refv = Vector2(last_position)
		sorted_maxima.sort_custom(
					func(a: Vector2i, 
						b: Vector2i): 
							return refv.distance_squared_to(Vector2(a)) < refv.distance_squared_to(Vector2(b)))
		
		var maxima = local_maxima[sorted_maxima[0]]+0.1
		# Clamp to closest maxima so as to not fill to far up.
		#if maxima > parameters["lake"].gen_height_mean:
		surface_height = clampf(surface_height, surface_height, maxima)
		
		var c = Color(surface_height, surface_height, surface_height)
		
		#print_debug(" ---- Surface : ", surface_height)
		
		flood_fill(last_position, c)
		area_silhouette.agent_travel[-1].add_point(last_position)
		
		tokens -= 2
	# Reduced token consumption if unsuccessful
	else:
		tokens -= 1
	
	generation_step.emit()


## Setup intial position and start generation.
func start_generation():
	# Prepare agent starting state.
	
	area_silhouette["cover_map"] = Image.create(heightmap.get_width(), heightmap.get_height(), false, Image.FORMAT_RF)
	
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
	
	#last_position = Vector2i(rng.randi_range(offset.x, heightmap.get_width()-offset.x),
								#rng.randi_range(offset.y, heightmap.get_height()-offset.y))
	#last_position = start_position
	#move_direction = Vector2i(rng.randi_range(-1, 1),
	#							rng.randi_range(-1, 1))
	
	#area_silhouette.agent_travel.append(Curve2D.new())
	
	_calculate_local_minima_sites()
	
	# Start generation.
	super.start_generation()


func finish_generation():
	
	# Merge points from coastline polygons
	for i in area_silhouette.coast_line.size():
		var pol = area_silhouette.coast_line[i]
		#pol = KuikkaUtils.merge_points_by_distance(pol, 15)
		pol = KuikkaUtils.make_clockwise(pol)
		area_silhouette.coast_line[i] = pol
	
	super.finish_generation()


## Flood fill area outwards around position if heights are lower than given
## value.
func flood_fill(position: Vector2i, height: Color):
	queue.clear()
	queue.append(position)
	
	area_silhouette.coast_line.append([])
	
	var cycles = 0
	print_debug("Starting flood fill process at height %f." % height.r)
	
	var end = false
	
	while not end:
		# FILO faster than FIFO? (Order itself is irrelevant for this work.)
		var p : Vector2i = queue.pop_back()
		var new_queue = fill_neightbours(p, height)
		queue.append_array(new_queue)
		processed[p] = true
		cycles += 1
		
		end = queue.is_empty()
		
		if cycles > 1000000:
			printerr("Aborting flood fill. Maximum iterations reached!")
			return
		
		#if end:
			#print_debug("Flood fill processing complete")	
			#return map
		
	print_debug("Flood fill processing complete with %d iterations." % cycles)	
	

## Recursive function to use to modify neighbouring pixels around given position
## in [map] [Image].
func fill_neightbours(position: Vector2i, height: Color):
	var neighbours = [Vector2i(-1, 0), Vector2i(0, -1),
						Vector2i(1, 0), Vector2i(0, 1)]
	var w = heightmap.get_width()
	var h = heightmap.get_height()
	var new_queue = []
	
	for n in neighbours:
		var p = position + n
		
		# Only pixels within [map] area
		if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h:
			continue
		else:
			#print_debug("map: ", heightmap.get_pixel(p.x, p.y).r, " level: ", height.r)
			if heightmap.get_pixel(p.x, p.y).r < height.r:
				var c = height
				heightmap.set_pixel(p.x, p.y, c)
				
				# Set to color map FIXME: index should be 2 (5 least significant bits)
				area_silhouette["cover_map"].set_pixel(p.x, p.y, (2 & 0x1F) << 27)
				
				if not p in queue and not p in processed:
					new_queue.append(p)
			else:
				area_silhouette.coast_line[-1].append(p)
	
	return new_queue


func _load_brush():
	brush = preload("res://addons/kuikka_terrain_gen/brushes/128_gaussian.png").get_image()
	brush.resize(brush_size, brush_size)
	
	# Flip brush to black for lakes
	for x in brush.get_width():
		for y in brush.get_height():
			# TODO: Blend weight
			brush.set_pixel(x, y, Color(0, 0, 0, brush.get_pixel(x, y).a * blend_multiplier))


## Calculate list of pixel coordinates at local minimas.
## Can be used to find "holes" to "fill" with water.
func _calculate_local_minima_sites():
	local_minima.clear()
	
	var path = ProjectSettings.globalize_path(HMAP_TEMP)
	var erode_path = ProjectSettings.globalize_path(ERODE_TEMP)
	var dilate_path = ProjectSettings.globalize_path(DILATE_TEMP)
	heightmap.save_png(path)
	
	# Calculate minimas
	KuikkaImgUtil.img_magick_execute(["convert", path, "-morphology", "Erode", "Octagon:3", erode_path])
	KuikkaImgUtil.img_magick_execute(["convert", path, "-morphology", "Dilate", "Octagon:3", dilate_path])

	var erode_map = Image.load_from_file(erode_path)
	var w : int = erode_map.get_width()
	var h : int = erode_map.get_height()
	var size : int = w * h
	
	for i in size:
		var x = i % w	
		var y = floor(i / w)
		
		# Positions with unchanged value are local minimas
		if erode_map.get_pixel(x, y).r == heightmap.get_pixel(x, y).r:
			local_minima[Vector2i(x, y)] = erode_map.get_pixel(x, y).r
	
	sorted_minima = local_minima.keys()
	
	# Merge minimas too close
	var minimas_vect2 = sorted_minima.map(func(v): return Vector2(v))
	
	minimas_vect2 = KuikkaUtils.merge_points_by_distance(minimas_vect2, 15)
	sorted_minima = minimas_vect2.map(func(v): return Vector2i(v))
	
	local_minima.clear()
	for key in sorted_minima:
		local_minima[key] = heightmap.get_pixel(key.x, key.y).r
		
	sorted_minima.sort_custom(func(a, b): return local_minima[a] < local_minima[b])
	
	print_debug("Identified %d local minima sites." % local_minima.keys().size())
	
	# Maxima
	
	var dilate_map = Image.load_from_file(dilate_path)
	var wd : int = dilate_map.get_width()
	var hd : int = dilate_map.get_height()
	var sized : int = wd * hd
	
	var mean = KuikkaUtils.mean(KuikkaUtils.dict_to_array(local_minima))
	
	for j in sized:
		var x = j % wd
		var y = floor(j / wd)
	
		# Positions with unchanged value are local minimas
		# HACK: Use minima mean to prevent maximas at flat low areas where
		# lakes are formed in original map.
		if dilate_map.get_pixel(x, y).r == heightmap.get_pixel(x, y).r and \
		dilate_map.get_pixel(x, y).r > mean:
			print_debug("local maxima : ", x, " ", y, dilate_map.get_pixel(x, y).r)
			local_maxima[Vector2i(x, y)] = dilate_map.get_pixel(x, y).r
	
	sorted_maxima = local_maxima.keys()
	sorted_maxima.sort_custom(func(a, b): return local_maxima[a] < local_maxima[b])
	# Merge maximas too close
	var maximas_vect2 = sorted_maxima.map(func(v): return Vector2(v))
	
	maximas_vect2 = KuikkaUtils.merge_points_by_distance(minimas_vect2, 15)
	sorted_maxima = maximas_vect2.map(func(v): return Vector2i(v))
	
	local_maxima.clear()
	for key in sorted_maxima:
		local_maxima[key] = heightmap.get_pixel(key.x, key.y).r
		
	sorted_maxima.sort_custom(func(a, b): return local_maxima[a] < local_maxima[b])
	
	## FIXME: Activate deletion to prevent cluttering
	# Remove temp images.
	#if FileAccess.file_exists(path):
	#	DirAccess.remove_absolute(path)
	#if FileAccess.file_exists(erode_path):
	#	DirAccess.remove_absolute(erode_path)
	
