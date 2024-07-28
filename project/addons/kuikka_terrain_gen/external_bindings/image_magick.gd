class_name ImageMagick extends Node

## ImageMagick related API binds to run in external command line.

const MAGICK = "/magick.exe"

enum ImgFormat {PNG, EXR, HDR}

@export var exec_path = ProjectSettings.globalize_path(
	ProjectSettings.get_setting("kuikka_terrain_gen/image_magick_path") if ProjectSettings.get_setting("kuikka_terrain_gen/image_magick_path") else ""):
		set(val):
			exec_path = ProjectSettings.globalize_path(val).trim_suffix("/")
					
			if exec_path == "":
				exec_path = KuikkaConfig.tools_config().get_value("tools", "image_magick_path", "")
			
			print("Image magick executable path set to %s" % val)
			_is_loaded = try_load_executable()

var _is_loaded : bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


## Check that executables exist in given path
func try_load_executable() -> bool:
	if _is_loaded:
		return true
	
	if not exec_path or exec_path == "": return false
	_is_loaded = FileAccess.file_exists(exec_path+MAGICK)
	return _is_loaded


## Execute operation with imagemagick with arbitrary arguments.
func execute(args: Array, debug=false):
	var result = []
	if not try_load_executable():
		printerr("Failed to find ImageMagick executable!")
		return result
	
	if debug:
		print_debug("Running ImageMagick: ", exec_path+MAGICK, " with arguments ", args)
	
	var exitc = OS.execute(exec_path+MAGICK, args, result, debug, debug)
	if exitc == -1:
		printerr("Error executing command with imagemagick.")
		return result
	return result


## Convert image to new format.
func convert_image(path: String, destination: String, format, debug:bool=false):
	if not try_load_executable():
		printerr("Failed to find ImageMagick executable!")
		return false
	var result = []
	
	path = ProjectSettings.globalize_path(path)
	destination = ProjectSettings.globalize_path(destination)
	var form_str : String  = ImgFormat.keys()[format]
	var f_name= FilePath.get_filename(path)
	var ext = form_str.to_lower()
	var dest_file = FilePath.join([destination, f_name+"."+ext])
	
	print_debug("Attempting to convert %s => %s" % [path, dest_file])
	
	var args = ["convert", path, "-format", form_str, dest_file]
		
	var exitc = OS.execute(exec_path+MAGICK, args, result, true, debug)
	if exitc == -1:
		printerr("Failed to convert %s to %s" % [path, dest_file])
		return false
		
	return true

## Load image stats to output file. Return result if successful.
## Otherwise returns empty array.
func fetch_img_stats(path: String, extended_features: bool = false, debug=false) -> Dictionary:
	var result = []
	if not try_load_executable():
		printerr("Failed to find ImageMagick executable!")
		return {}
	
	var args = ["identify", "-verbose"]
	
	if extended_features:
		args.append_array(["-features", "100"])
	
	args.append(path)
	
	var exitc = OS.execute(exec_path+MAGICK, args, result, debug, false)
	if exitc == -1:
		printerr("Failed to fetch image stats.")
		return {}
	
	if debug:
		print_debug("Magick processing image ", path)
		print_debug("Result: \n", result[0])
	
	# Split by rows
	var split = result[0].split("\n")
	
	## TODO: Check channel mode and get values from Gray / Red instead
	## -> Overall stats get from alpha 
	var color_type = _im_parse_output(_im_parse_output(split, "Image"), "Colorspace")[0].split(":")[1]
	var depth = _im_parse_output(_im_parse_output(split, "Image"), "Depth")[0].split(":")[1]
	
	var channel_name = ""
	if color_type.contains("Gray"):
		channel_name = "Gray"
	elif color_type.contains("RGB"):
		channel_name = "Red"
	
	# Find overall stats.
	var rows = _im_parse_output(split, "Channel statistics")
	var end = KuikkaUtils.array_find_index(rows, (func(x): return x.contains("Histogram")))
	# Split off other than Channel Statistics.
	if end:
		rows = rows.slice(0, end)
	
	var items = _im_parse_output(rows, channel_name)
	items = items.slice(1, 9)

	# Use Red channel if Gray is not available.
	# if items.size() < 8:
		#rows = _im_parse_output(split, "Channel statistics")
		#end = KuikkaUtils.array_find_index(rows, (func(x: String): return x.contains("Histogram")))
		#if end:
			#rows = rows.slice(0, end)
		#
		#items = _im_parse_output(rows, "Gray")
		#items = items.slice(1, 9)
	#
		#if debug:
			#print_debug("Red channel result ", items)
	
	if debug:
		print_debug("Stats result ", rows)
		print_debug("Overall channel result ", items)
	
	for i in items.size():
		var item : String = items[i]
		# Remove spaces, returns and other empty characters.
		item = item.replace(" ", "")
		item = item.replace("\r", "")
		item = item.replace("\n", "")
		
		# For 32/16-bit bands get 16-bit value that represents result as meters.
		if depth.contains("32/16-bit") or depth.contains("16-bit"):
			if item.contains("("):
				item = item.split("(")[1].split(")")[0]
			# Get non scale dependent values kurtosis etc.
			else:
				item = item.split(":")[1]
			items[i] = item
		# For 16-bit and 8-bit images use bytes band instead of normalized value.
		else:
			# Get normalized value in braces if it exists. Otherwise take default.
			if item.contains("("):
				item = str(float(item.split("(")[0].split(":")[1]))
			# Get non scale dependent values kurtosis etc.
			else:
				item = item.split(":")[1]
			items[i] = item
	
	if debug:
		print("ImageMagick result: \n", result[0], "	\nParsed: ", items)
	
	if items.size() < 8:
		print("ImageMagick result: \n", result[0], "	\nParsed: ", items)
		print_debug("\n-----\nStats result ", rows)
		push_error("Failed to fetch image stats.")
		return {}
	
	var stats = {
		"min": float(items[0]),
		"max": float(items[1]),
		"mean": float(items[2]),
		"median": float(items[3]),
		"std_dev": float(items[4]),
		"kurtosis": float(items[5]),
		"skewness": float(items[6]),
		"entropy": float(items[7])
	}
	
	# Find extended stats if wanted
	if extended_features:
		# TODO: Implement
		pass
	
	return stats


## Find first array item in Array[String] that contains the given key and
## returns subarray of items after found index. [index, -1]
static func _im_parse_output(arr: Array, key: String, begins_with:bool=false):
	var item = arr.filter(func(x: String): return x.begins_with(key)) if begins_with else \
						arr.filter(func(x: String): return x.contains(key))
	var idx = -1
	
	if item.size() > 0:
		idx = arr.find(item[0])
	
	if idx == -1:
		return []
	
	return arr.slice(idx, -1)

