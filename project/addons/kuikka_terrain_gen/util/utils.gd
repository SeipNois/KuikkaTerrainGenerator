extends Node
class_name KuikkaUtils

const CHARS = "abcdefghijklmnopqrstuvwxyz0123456789"

# Create simple random [String] of given length.
# NOTE: Has no quarantees for uniqueness. Use some uuid implementation instead.
static func rand_string(length : int):
	var str : String = ""
	
	for i in length:
		str += CHARS[randi() % CHARS.length()]
	
	return str


## Calculate mean value from array of floats.
static func mean(values : Array) -> float:
	var sum = 0
	values.reduce(func(sum, n): return sum + n, sum)
	if values.size() == 0:
		return 0
	return sum / values.size()

## Calculate standard deviation from array of floats.
static func standard_deviation(values: Array, mean: float) -> float:
	if values.size() == 0:
		return 0
	
	var sum = 0
	sum = values.reduce(func(s, x): return s + (x-mean)**2, sum)
	return sqrt(sum/values.size())



## Returns all non overlapping points for array of GDDelaunay [Delaunay.Triangle]s.
static func triangulation_get_unique_points(triangles: Array) -> Array:
	
	var points = []
	
	for tri : Delaunay.Triangle in triangles:
		if tri.a not in points:
			points.append(tri.a)
		if tri.b not in points:
			points.append(tri.b)
		if tri.c not in points:
			points.append(tri.c)
	
	return points


## Sample Images into pieces of given size
## [param path]			Path to search for images.
## [param size]			Side lenght of image squares to produce
## [param batch_size] 	Maximum amount of source images to use.
## [param destination]	Path to store the resulting images.
static func sample_images(path: String, size: int, batch_size: int,
	destination:String="res://addons/kuikka_terrain_gen/height_samples/split_samples") -> Array[String]:
	var result = [] as Array[String]
	var images = parse_image_path_batch(path)
	destination = ProjectSettings.globalize_path(destination)
	var index = 1
	
	## Split images into given size pieces.
	print_debug("Splitting images to regions.")
	for img_path: String in images:
		var regions = sample_image(img_path, size, destination)
		
		result.append_array(regions)
		index += 1
		
		# Allow processing maximum of set batch size amount of source
		# images.
		if index >= batch_size:
			return result
		
	return result


## Sample Images into pieces of given size
## [param paths]		Array of image paths.
## [param size]			Side lenght of image squares to produce
## [param destination]	Path to store the resulting images.
static func sample_images_array(paths: Array, size: int,
	destination:String="res://addons/kuikka_terrain_gen/height_samples/gene_samples") -> Array[String]:
	var result = [] as Array[String]
	destination = ProjectSettings.globalize_path(destination)
	
	## Split images into given size pieces.
	print_debug("Splitting images to regions.")
	for img_path: String in paths:
		var regions = sample_image(img_path, size, destination)
		
		result.append_array(regions)
		
	return result


static func sample_image(img_path : String, size: int, destination: String):
	var regions = []
	var img : Image = Image.load_from_file(img_path)
	if img.get_width() % size != 0 or img.get_height() % size != 0:
		push_warning("Image size is not divisible by given size. 
				Omitting extra from split regions.")
	
	for y in range(0, img.get_height()-size, size):
		if y+size > img.get_height():
			push_warning("Image height is not divisible by given size. 
			Omitting extra from split regions.")
			break
		
		for x in range(0, img.get_width()-size, size):
			if x+size > img.get_width():
				push_warning("Image width is not divisible by given size. 
				Omitting extra from split regions.")
				break
			
			var rect = Rect2i(Vector2i(x, y), Vector2i(size, size))
			var new_img = img.get_region(rect)
			var fname = FilePath.get_filename(img_path)+"-"+str(x)+"-"+str(y)+FilePath.get_extension(img_path)
			
			if FileAccess.file_exists(fname):
				push_warning("Image ", fname, " already exists! Skipping creation.")
			else:
				var new_img_path = FilePath.join([destination, fname])
				var err = new_img.save_png(new_img_path)
			
				if not err:
					regions.append(new_img_path)
				else:
					printerr("Failed to save image at ", new_img_path, " error ", err)
	
	# If image is smaller than size use it as single height sample.
	if regions.is_empty():
		regions.append(img_path)
	
	return regions


## Get all files in directory path that are Images.
## [param path]			Directory path to search images from
## [param batch_size]	Maximum amount of images to list.
static func parse_image_path_batch(path: String, batch_size: int = -1) -> Array[String]:
	var gpath = ProjectSettings.globalize_path(path)
	var dir = DirAccess.open(gpath)
	if dir:
		dir.list_dir_begin()
		var result = [] as Array[String]
		var file_name = dir.get_next()
		var index = 1
		print_debug("Trying to load images from ", gpath)
		while file_name != "":
			# Skip directories and import files.
			if not dir.current_is_dir() and not file_name.ends_with(".import"):
				var img_path = FilePath.join([path, file_name])
				var img = Image.new()
				var err = img.load(img_path)
				if not err:
					print_debug("Parsed image from ", img_path)
					result.append(img_path)
					index += 1
				else:
					print_debug("Omitting non-image file ", img_path, " error ", err)
				
				# Unload image.
				img = null
			
			file_name = dir.get_next()
			
			# Allow for maximum of batch size images if batch size is defined.
			if batch_size > 0 and index >= batch_size:
				print_debug("Done parsing images.")
				return result
				
		print_debug("Done parsing images.")
		return result
	else:
		printerr("Error opening directory <", gpath, ">" )
		return []


static func image_mult_alpha(img: Image, mult: float) -> Image:
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = img.get_pixel(x, y)
		color.a = color.a * mult
		img.set_pixel(x, y, color)
	return img


static func image_set_alpha(img: Image, val: float) -> Image:
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = img.get_pixel(x, y)
		color.a = val
		img.set_pixel(x, y, color)
	return img


static func images_blend_alpha(img: Image, alpha_image: Image) -> Image:
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	var result = img.duplicate()
	
	if alpha_image.get_width() != img.get_width() or \
	alpha_image.get_height() != img.get_height():
		printerr("Aplha blending images requires mask to be same size as source image!")
		return img
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = result.get_pixel(x, y)
		var acolor = alpha_image.get_pixel(x, y)
		color.a = acolor.a
		result.set_pixel(x, y, color)
	return result
	
	
## Similar to [method Array.filter] but returns the first
## item in array that fulfills given condition.
## [param array] [Array] to search
## [param condition] [Callable] Condition that called with array item
## 								should return true or false based on
##								condition fullfilment by item.
static func array_find_first(array: Array, condition: Callable):
	for item in array:
		if condition.call(item):
			return item
	
	return null
