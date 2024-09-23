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
#var processed_queue : Dictionary = {}
#var ref_map : Image

## Calculated local minima to use for "filling" with water.
var local_minima : Dictionary = {}

## Calculated local maxima used to prevent water level rising too high.
var local_maxima : Dictionary = {}

## local_minima.keys() sorted into rising order by local_minima[key] value.
var sorted_minima : Array = []

var sorted_maxima : Array = []

## Mean of local maximas
var maxima_mean : float

var color_map_index = Color(3/255, 0, 0)

var minima_index = 0


func _init():
	agent_type = &"KuikkaLakeAgent"
	gene_placement = GeneDistribute.NONE
	
	## Coastline as series of pixels.
	area_silhouette["coast_line"] = [] # Vector2i
	area_silhouette["cover_map"] = []
	set_process(false)


func _generation_process():
	if parameters.source == "lake":
		_generation_process_lake()
	elif parameters.source == "sea":
		_generation_process_sea()
	else:
		tokens = 0
		
	
func _generation_process_lake():
	# Stop generation if minima sites have been exhausted.
	if not local_minima or local_minima.is_empty():
		tokens = 0
		generation_step.emit()
		return
	
	if minima_index % 500 == 0:
		print_debug("Lake progress ", minima_index, " iterations.")
	
	# Use id to identify current generated lake
	var id = KuikkaUtils.rand_string(10)
	
	# Update brush
	var new_size = rng.randi_range(parameters["lake"].size_mean*2-parameters["lake"].size_std_dev*4, 
									parameters["lake"].size_mean*2+parameters["lake"].size_std_dev*1)
	
	new_size = clamp(new_size, 2, heightmap.get_width())
	_update_brush_size(new_size)
	
	## Randomize new lake location.
	#last_position = Vector2i(rng.randi_range(offset.x, heightmap.get_width()-offset.x),
							#rng.randi_range(offset.y, heightmap.get_height()-offset.y))
	
	# get random minima (weighted to prioritize lower ones)
	var pos_index = rng.randi_range_weighted(0, local_minima.keys().size(), local_minima.keys().size()/3, local_minima.keys().size()/10)
	
	# Prioritize lowest minimas.
	last_position = sorted_minima[minima_index]
	minima_index += 1
	
	# Stop further cycles if already processed all sites
	if minima_index > sorted_minima.size():
		tokens = 0
	
	# Site has been changed by another lake generation. Remove and try again.
	if last_position in processed:# local_minima[last_position] != heightmap.get_pixel(last_position.x, last_position.y).r:
		generation_step.emit()
		return
							
	## Add new curve when starting from new position.
	area_silhouette.agent_travel.append(Curve2D.new())
	
	# Blend at current position if within height threshold
	var rang = terrain_image.height_profile.represent_range
	var h = rang.x + heightmap.get_pixel(last_position.x, last_position.y).r \
															* (rang.y-rang.x)
	
	# Calculate to be surface height
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
	var surface_height = Fitness.img_get_mean(region) + rng.randi_range(-0.05, 0.1)
	
	# print_debug("Surface height ", surface_height)
	
	var sh = rang.x + surface_height * (rang.y-rang.x)
	
	if last_position.x < 0 or last_position.x >= heightmap.get_width() or \
	last_position.y < 0 or last_position.y >= heightmap.get_height():
		generation_step.emit()
		return
		
	if sh >= parameters["lake"].gen_height_min-0.01*(rang.y-rang.x) and \
	sh <= parameters["lake"].gen_height_max+0.01*0.01*(rang.y-rang.x):
		
		var refv = Vector2(last_position)
		sorted_maxima.sort_custom(
					func(a: Vector2i, 
						b: Vector2i): 
							return refv.distance_squared_to(Vector2(a)) < refv.distance_squared_to(Vector2(b)))
		
		var maxima = local_maxima[sorted_maxima[0]]+0.1 if sorted_maxima.size() > 0 else 1
		# Clamp to closest maxima so as to not fill to far up.
		if surface_height > maxima:
			surface_height = clampf(surface_height, surface_height, maxima)
		
		var c = Color(surface_height, surface_height, surface_height)
		
		#print_debug(" ---- Surface : ", surface_height)
		
		var cycles = flood_fill(last_position, c)
		area_silhouette.agent_travel[-1].add_point(last_position)
		
		tokens -= ceil(cycles * 0.005)
	# Reduced token consumption if unsuccessful
	else:
		print_debug("Lake site not within height range, h: %d." % surface_height)
		tokens -= 1
	
	generation_step.emit()


func _generation_process_sea():
	# Stop generation if minima sites have been exhausted.
	if not local_minima or local_minima.is_empty():
		tokens = 0
		generation_step.emit()
		return
	
	if minima_index % 500 == 0:
		print_debug("Lake progress ", minima_index, " iterations.")
	
	# Update brush
	var new_size = rng.randi_normal_dist(parameters["lake"].size_mean*2, 
								parameters["lake"].size_std_dev)
	
	new_size = clamp(new_size, 0, heightmap.get_width())
	_update_brush_size(new_size)
	
	## Randomize new lake location.
	#last_position = Vector2i(rng.randi_range(offset.x, heightmap.get_width()-offset.x),
							#rng.randi_range(offset.y, heightmap.get_height()-offset.y))
	
	# get random minima (weighted to prioritize lower ones)
	var pos_index = rng.randi_range_weighted(0, local_minima.keys().size(), local_minima.keys().size()/3, local_minima.keys().size()/10)
	
	# Prioritize lowest minimas.
	last_position = sorted_minima[minima_index]
	minima_index += 1
	
	# Stop further cycles if already processed all sites
	if minima_index > sorted_minima.size():
		tokens = 0
	
	# Site has been changed by another lake generation. Remove and try again.
	if last_position in processed:# local_minima[last_position] != heightmap.get_pixel(last_position.x, last_position.y).r:
		#local_minima.erase(last_position) 
		#sorted_minima.erase(last_position)
		#tokens -= 1
		#print_debug("Lake site already processed.")
		generation_step.emit()
		return
		
							
	## Add new curve when starting from new position.
	area_silhouette.agent_travel.append(Curve2D.new())
	
	var surface_height = Fitness.img_get_mean(heightmap)+0.0025
	
	# Blend at current position if within height threshold
	var rang = terrain_image.height_profile.represent_range
	var h = rang.x + heightmap.get_pixel(last_position.x, last_position.y).r \
															* (rang.y-rang.x)
	
	if last_position.x > 0 and last_position.x < heightmap.get_width() and \
	last_position.y > 0 and last_position.y < heightmap.get_height() and\
	h < surface_height:
		
		var start = last_position-offset
		var end = offset*2
		
		# Cap area outside image.
		if start.x < 0:
			end.x += abs(start.x)
			start.x = 0
		if start.y < 0:
			end.y += abs(start.y)
			start.y = 0
		
		#var surface_height = Fitness.img_get_mean(region)
		var refv = Vector2(last_position)
		sorted_maxima.sort_custom(
					func(a: Vector2i, 
						b: Vector2i): 
							return refv.distance_squared_to(Vector2(a)) < refv.distance_squared_to(Vector2(b)))
		
		var maxima = local_maxima[sorted_maxima[0]]+0.1 if sorted_maxima.size() > 0 else 1
		
		# Clamp to closest maxima so as to not fill to far up.
		if surface_height > maxima:
			surface_height = clampf(surface_height, surface_height, maxima)
		
		var c = Color(surface_height, surface_height, surface_height)
		
		#print_debug(" ---- Surface : ", surface_height)
		
		flood_fill(last_position, c)
		area_silhouette.agent_travel[-1].add_point(last_position)
		
		# Single generation cycle for sea.
		tokens = 0
	# Reduced token consumption if unsuccessful
	else:
		print_debug("Lake site not within height range.")
		tokens -= 1
	
	generation_step.emit()


## Setup intial position and start generation.
func start_generation():
	# Prepare agent starting state.
	
	# Use either lake or sea based on which has more occurences
	var lake = terrain_image.features["jarvi"]
	var sea = terrain_image.features["meri"]
	var result = sea if sea.density > lake.density else lake
	var source = "sea" if sea.density > lake.density else "lake"
	
	parameters = { "lake": result, "source": source }
	
	# Double tokens to consume 2 when successful and only one if 
	# failing to generate.
	tokens = round(parameters["lake"].density) * 2
	rng.set_seed(seed)
	rng.set_state(state)
	
	brush_size = rng.randi_normal_dist(parameters["lake"].size_mean*2, parameters["lake"].size_std_dev*2)
	_load_brush()
	
	gene_mask = Image.create(heightmap.get_width(), heightmap.get_height(), false, heightmap.get_format())
	
	_calculate_local_minima_sites()
	
	if tokens > 0:
		# Start generation.
		super.start_generation()
	else:
		print_debug(agent_type, ", no tokens assigned. Skipping generation.")
		
		# Await to let preparation complete if finishing immediately from setup.
		await get_tree().process_frame
		finish_generation()


# Set heights to heightmap
func create_water():
	for p in processed.keys():
		var h = processed[p]
		heightmap.set_pixel(p.x, p.y, Color(h, h, h, 1))
	return


func finish_generation():
	#processed_queue.clear()
	
	#create_water()
	
	# Merge points from coastline polygons
	for i in area_silhouette.coast_line.size():
		var pol = area_silhouette.coast_line[i]
		#pol = KuikkaUtils.merge_points_by_distance(pol, 15)
		pol = KuikkaUtils.make_clockwise(pol)
		area_silhouette.coast_line[i] = PackedVector2Array(pol)
	
	area_silhouette.gene_points = []
	set_process(false)
	generation_finished.emit(self)
	# super.finish_generation()


## Flood fill area outwards around position if heights are lower than given
## value.
func flood_fill(position: Vector2i, height: Color, id:StringName=&"base_id"):
	if tokens <= 0:
		return 0
	
	#processed_queue = {}
	
	queue.clear()
	queue.append(position)
	# processed.clear()
	
	area_silhouette.coast_line.append([])
	
	var cycles = 0
	print_debug("Starting flood fill process at height %f." % height.r)
	
	# Process start position
	# TODO: ** Process start position
	#heightmap.set_pixel(position.x, position.y, height)
	processed[position] = height.r
	
	while queue != null and not queue.is_empty() and (tokens > 0):
		# FILO faster than FIFO? (Order itself is irrelevant for this work.)
		var p : Vector2i = queue.pop_back()
		var new_queue = fill_neightbours(p, height.r)#, id)
		queue.append_array(new_queue)
		#processed[p] = height #id
		#processed_queue[p] = id
		cycles += 1
		
		if cycles > 1000000:
			printerr("Aborting flood fill. Maximum iterations reached!")
			return cycles
		
		if queue.is_empty() or tokens <= 0:
			break
		
	print_debug("Flood fill processing complete with %d iterations." % cycles)	
	return cycles

## Recursive function to use to modify neighbouring pixels around given position
## in [map] [Image].
func fill_neightbours(position: Vector2i, height:float): #Color, id:StringName):
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
			if not (p in processed and processed[p] >= height) and heightmap.get_pixel(p.x, p.y).r < height:
				#var c = height
				#heightmap.set_pixel(p.x, p.y, c)
				processed[p] = height
				
				# Set to control map 
				area_silhouette["cover_map"].append(p)
				
				if not p in queue: # and not (p in processed and processed[p] > height): #not p in processed_queue:
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
	#var minimas_vect2 = merge_minimas(15)
	#sorted_minima = minimas_vect2.map(func(v): return Vector2i(v))
	
	#local_minima.clear()
	#for key in sorted_minima:
	#	local_minima[key] = heightmap.get_pixel(key.x, key.y).r
		
	sorted_minima.sort_custom(func(a, b): return local_minima[a] < local_minima[b])
	var center = Vector2(round(heightmap.get_width()/2), round(heightmap.get_height()/2))
	
	# Sort so as to prioritize points in the center.
	#sorted_minima.sort_custom(func(a, b): return center.distance_squared_to(Vector2(a)) < center.distance_squared_to(Vector2(b)))
	
	print_debug("Identified %d local minima sites." % local_minima.keys().size())
	
	# Maxima
	
	var dilate_map = Image.load_from_file(dilate_path)
	var wd : int = dilate_map.get_width()
	var hd : int = dilate_map.get_height()
	var sized : int = wd * hd
	
	var mean = KuikkaUtils.mean(KuikkaUtils.dict_to_array(local_minima))
	
	maxima_mean = 0
	
	for j in sized:
		var x = j % wd
		var y = floor(j / wd)
	
		# Positions with unchanged value are local minimas
		# HACK: Use minima mean to prevent maximas at flat low areas where
		# lakes are formed in original map.
		if dilate_map.get_pixel(x, y).r == heightmap.get_pixel(x, y).r and \
		dilate_map.get_pixel(x, y).r > mean:
			#print_debug("local maxima : ", x, " ", y, dilate_map.get_pixel(x, y).r)
			local_maxima[Vector2i(x, y)] = dilate_map.get_pixel(x, y).r
			
			maxima_mean = dilate_map.get_pixel(x, y).r
	
	sorted_maxima = local_maxima.keys()
	
	sorted_maxima.sort_custom(func(a, b): return local_maxima[a] < local_maxima[b])
	# Merge maximas too close

	#var maximas_vect2 = merge_maximas(15)
	#sorted_maxima = maximas_vect2.map(func(v): return Vector2i(v))
	#
	#local_maxima.clear()
	#for key in sorted_maxima:
		#local_maxima[key] = heightmap.get_pixel(key.x, key.y).r
		
	sorted_maxima.sort_custom(func(a, b): return local_maxima[a] < local_maxima[b])
	
	maxima_mean = KuikkaUtils.mean(KuikkaUtils.dict_to_array(local_maxima))
	
	## FIXME: Activate deletion to prevent cluttering
	# Remove temp images.
	#if FileAccess.file_exists(path):
	#	DirAccess.remove_absolute(path)
	#if FileAccess.file_exists(erode_path):
	#	DirAccess.remove_absolute(erode_path)


## Merge points within treshold to minimum of points.
func merge_minimas(treshold: float):
	var cloud : Array = sorted_minima
	var result = []
	
	# Assigned group indexes for points
	var assigned = {}
	
	var groups = []
	var new_group = []
	var index = -1
	
	print_debug("Starting (min) merge with point cloud size ", cloud.size())
	
	for i in cloud.size():
		var p : Vector2 = Vector2(cloud[i])
		# Group with already considered points if assigned. 
		# Otherwise create new group.
		if not assigned.has(p):
			index += 1
			groups.append([p])
			assigned[p] = index
		
		# Compare against new points
		for j in range(i+1, cloud.size()):
			var r : Vector2 = cloud[j]
			if p.distance_to(r) < treshold:
				
				# Assign as group point if minimum
				if local_minima[Vector2i(r)] < local_minima[Vector2i(groups[index][-1])]:
					groups[index] = [r]
				
				# Assign to group to avoid reassigning whether or not minimum.
				assigned[r] = index
	
	
	# Calculate minimum from groups
	for g in groups:
		if g.size() > 1:
			var points = g.map(func(p): return local_minima[Vector2i(p)])
			var new_point = points.min()
			
			result.append(new_point)
		else:
			result.append(g[0])
	
	print_debug("Merged (min) point groups to size ", result.size())
	
	return result
	

## Merge points within treshold to maximum of points.
func merge_maximas(treshold: float):
	var cloud : Array = sorted_maxima
	var result = []
	
	# Assigned group indexes for points
	var assigned = {}
	
	var groups = []
	var new_group = []
	var index = -1
	
	print_debug("Starting (max) merge with point cloud size ", cloud.size())
	
	for i in cloud.size():
		var p : Vector2 = Vector2(cloud[i])
		# Group with already considered points if assigned. 
		# Otherwise create new group.
		if not assigned.has(p):
			index += 1
			groups.append([p])
			assigned[p] = index
		
		# Compare against new points
		for j in range(i+1, cloud.size()):
			var r : Vector2 = cloud[j]
			if p.distance_to(r) < treshold:
				# Assign as group point if maximum
				if local_maxima[Vector2i(r)] > local_maxima[Vector2i(groups[index][-1])]:
					groups[index] = [r]
				
				# Assign to group to avoid reassigning whether or not maximum.
				assigned[r] = index
				
	# Calculate maximum from groups
	for g in groups:
		if g.size() > 1:
			var points = g.map(func(p): return local_maxima[Vector2i(p)])
			var new_point = points.max()
			
			result.append(new_point)
		else:
			result.append(g[0])
	
	print_debug("Merged (max) point groups to size ", result.size())
	
	return result	
