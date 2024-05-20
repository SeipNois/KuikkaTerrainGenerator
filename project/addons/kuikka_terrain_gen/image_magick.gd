class_name ImageMagick extends Node

## ImageMagick related API binds to run in external command line.

const MAGICK = "/magick.exe"
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
func execute(args):
	var result = []
	if not try_load_executable():
		printerr("Failed to find ImageMagick executable!")
		return result
	
	var exitc = OS.execute(exec_path+MAGICK, args, result, OS.is_debug_build(), OS.is_debug_build())
	if exitc == -1:
		printerr("Error executing command with imagemagick.")
		return result
	return result

## Load image stats to output file. Return result if successful.
## Otherwise returns empty array.
func fetch_img_stats(path: String, extended_features: bool = false) -> Dictionary:
	var result = []
	if not try_load_executable():
		printerr("Failed to find ImageMagick executable!")
		return {}
	
	var args = ["identify", "-verbose"]
	
	if extended_features:
		args.append_array(["-features", "100"])
	
	args.append(path)
	
	var exitc = OS.execute(exec_path+MAGICK, args, result, OS.is_debug_build(), false)
	if exitc == -1:
		printerr("Failed to fetch image stats.")
		return {}
	
	# print("ImageMagick result: \n", result[0])
	
	# Split by rows
	var split = result[0].split("\n")
	
	# Find overall stats.
	var rows = _im_parse_output(split, "Channel statistics")
	var items = _im_parse_output(rows, "Gray")
	items = items.slice(1, 9)
	
	# Use Red channel if Gray is not available.
	if items.size() < 8:
		items = _im_parse_output(rows, "Red")
		items = items.slice(1, 9)
	
	for i in items.size():
		var item : String = items[i]
		# Remove spaces, returns and other empty characters.
		item = item.replace(" ", "")
		item = item.replace("\r", "")
		item = item.replace("\n", "")
		
		# Get normalized value in braces if it exists. Otherwise take default.
		if item.contains("("):
			item = item.split("(")[1].split(")")[0]
		else:
			item = item.split(":")[1].split("(")[0]
		items[i] = item
	
	if items.size() < 8:
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
static func _im_parse_output(arr: Array, key: String):
	var item = arr.filter(func(x: String): return x.contains(key))
	var idx = -1
	
	if item.size() > 0:
		idx = arr.find(item[0])
	
	if idx == -1:
		return []
	
	return arr.slice(idx, -1)

