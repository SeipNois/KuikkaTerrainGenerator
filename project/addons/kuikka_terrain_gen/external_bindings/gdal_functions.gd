class_name GdalUtils extends Node

## Uses OSGeo GDAL Library through separate process to
## Convert GeoTIFF Images to Godot supported Image format.


const GDAL_TRANSLATE = "/gdal_translate.exe"
const GDAL_INFO = "/gdalinfo.exe"
const GDAL_CALC = "/gdal_calc.exe"
const EXECUTABLES = ["gdal_translate.exe", "gdalinfo.exe", "gdal_calc.exe", "gdalwarp.exe"]

enum ImgFormat {PNG, EXR, EHdr}
enum ColorFormat {Byte, Int8, Int16, UInt16}

@export var gdal_path : StringName =  ProjectSettings.globalize_path(
	ProjectSettings.get_setting("kuikka_terrain_gen/gdal_path") if ProjectSettings.get_setting("kuikka_terrain_gen/gdal_path") else ""):
	set(val):
		gdal_path = ProjectSettings.globalize_path(val).trim_suffix("/")
		
		if gdal_path == "":
			gdal_path = KuikkaConfig.tools_config().get_value("tools", "gdal_path", "")
		
		_is_loaded = try_load_gdal_executable()
	
var _active_process_ids : Array[int]
var _is_loaded :bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## Set path to gdal executables
func set_gdal_path(path: StringName):
	gdal_path = path
	

## Execute gdal executable 
func execute(executable: String, args: Array, debug=false):
	if not try_load_gdal_executable():
		printerr("Gdal executables could not be located! Please check gdal_path set in ProjectSettings.")
		return
	
	if not executable in EXECUTABLES:
		printerr("Invalid name for gdal executable ", executable)
		
	var result = []
	
	print_debug("Running gdal: ", gdal_path+"/"+executable, " with arguments ", args)
	
	var exitc = OS.execute(gdal_path+"/"+executable, args, result, debug, debug)
	
	if exitc == -1:
		printerr("Error executing command with imagemagick.")
		return result
	return result


## Convert all valid images in given directory to given format using gdal_translate.
func gdal_translate_directory(directory : String, destination: String, format: ImgFormat, bit_depth: int):
	if not try_load_gdal_executable():
		printerr("Gdal executables could not be located! Please check gdal_path set in ProjectSettings.")
		return
		
	directory = ProjectSettings.globalize_path(directory)
	destination = ProjectSettings.globalize_path(destination)
	var files = DirAccess.get_files_at(directory)
	
	for f in files:
		await gdal_translate_one(FilePath.join([directory, f]), destination, format, bit_depth)
		await get_tree().create_timer(0.002).timeout


## Convert all files in given path between formats
## [param filepaths] Array of file paths of files to convert to another format.
## [param destination] Filepath of the destination directory for converted files.
## [param format] Image format to convert to.
func gdal_translate_batch(filepaths : Array, destination: String, format: ImgFormat,bit_depth: int, debug:bool=false):
	if not try_load_gdal_executable():
		printerr("Gdal executables could not be located! Please check gdal_path set in ProjectSettings.")
		return
		
	for f in filepaths:
		await gdal_translate_one(f, destination, format, bit_depth, false, debug)


## Convert all files in given path between formats
## [param filepath] Path of file to convert to another format.
## [param destination] Filepath of the destination directory for converted files.
## [param format] Image format to convert to.
## [param keep_world_data] Save georeferencing data to separate pgw file.
## @tutorial https://gdal.org/programs/gdal_translate.html
func gdal_translate_one(filepath : String, destination: String, format: ImgFormat, bit_depth: int, keep_world_data: bool=false, debug:bool=false):
	# Convert to absolute paths if in Godot local res:// or user:// format.
	filepath = ProjectSettings.globalize_path(filepath)
	destination = ProjectSettings.globalize_path(destination)
	var form_str : String = ImgFormat.keys()[format]
	var result = []
	
	# Setup gdal_translate arguments 
	# Documentation @tutorial https://gdal.org/programs/gdal_translate.html
	var f_name = FilePath.get_filename(filepath)
	var ext = form_str.to_lower()
	var dest_file = FilePath.join([destination, f_name+"."+ext])
	
	var stats = KuikkaImgUtil.img_get_stats(filepath)
	print_debug("Scaling to stats ", stats.min, " ", stats.max)
	
	var bits = ColorFormat.keys()[bit_depth]
	
	var depth = 65535 if bits == "UInt16" else 255
	
	# HACK: Scale to values to original heighmap scale for easier blend.
	# Use 16-bit band.
	var args = ["-of", form_str, "-b", 1, "-ot", bits, "-scale", stats.min-15, stats.max+15, 0, depth]
	
	#if format == ImgFormat.PNG or format == 0:
		#args.append_array(["-ot", "UInt16", "-scale", "32.53501", "767.4913", "0", "65535"])
	if keep_world_data:
		args.append_array(["-co", "WORLDFILE=YES"])
	
	args.append_array([filepath, dest_file])
	
	print_debug("Attempting to convert %s => %s" % [filepath, dest_file])
	print_debug("Args: ", args)
	var exitc = OS.execute(gdal_path+GDAL_TRANSLATE, args, result, true, debug)
	if exitc == -1:
		printerr("Gdal translation failed.")
	else:
		print(result[0])
		
	# return result


## Fetch image statistics using gdalinfo
func fetch_img_stats(path: String, debug=false) -> Dictionary:
	if not try_load_gdal_executable():
		printerr("Gdal executables could not be located! Please check gdal_path set in ProjectSettings.")
		return {}
	
	var result = []
	var filepath = ProjectSettings.globalize_path(path)
	var args = ["-mm", filepath]
	
	var exitc = OS.execute(gdal_path+GDAL_INFO, args, result, true, debug)
	
	if exitc == -1:
		printerr("Failed to fetch image statistics with gdalinfo.")
		return {}
	
	# Dictionarize result values.
	var dict = {}
	
	var split = result[0].split("\n")
	var row = _parse_output(split, "Computed Min/Max")
	
	if row.size() > 0:
		row = row[0]
		row = row.replace(" ", "")
		row = row.replace("\r", "")
		row = row.replace("\n", "")
		var min_max = row.split("=")[1].split(",")
		
		dict["min"] = float(min_max[0])
		dict["max"] = float(min_max[1])
	else:
		push_error("Failed to parse min/max values for ", filepath)
	
	#var orig_row = _parse_output(split, "Origin")
	#
	#if orig_row.size() > 0:
		#orig_row = orig_row.replace(" ", "")
		#orig_row = orig_row.replace("\r", "")
		#orig_row = orig_row.replace("\n", "")
		#var xy = orig_row.split("(")[1].split(")")[0].split(":")
			#
		#dict["origin"] = Vector2(float(xy[0]), float(xy[1]))
		#
	#else:
		#push_error("Failed to parse origin coordinate values for ", filepath)
	
	return dict


## Execute gdal_calc or (gdalwarp) to path with given operation
func gdal_calc(pathin: String, pathout: String, operation: String, debug:bool=false):
	if not try_load_gdal_executable():
		printerr("Gdal executables could not be located! Please check gdal_path set in ProjectSettings.")
		return
	
	var result = []
	var args = ["--calc=%s" % operation, pathin, pathout]
	
	var exitc = OS.execute(gdal_path+GDAL_CALC, args, result, true, debug)
	
	if exitc == -1:
		printerr("Failed to fetch image statistics with gdalinfo.")
		return


## Check that gdal executables exist in given path
func try_load_gdal_executable() -> bool:
	if _is_loaded:
		return true
		
	if not gdal_path or gdal_path == "":
		return false
	
	_is_loaded = FileAccess.file_exists(gdal_path+GDAL_TRANSLATE) and \
		 	FileAccess.file_exists(gdal_path+GDAL_INFO)
	
	return _is_loaded


## Find first array item in Array[String] that contains the given key and
## returns subarray of items after found index. [index, -1]
static func _parse_output(arr: Array, key: String):
	var item = arr.filter(func(x: String): return x.contains(key))
	var idx = -1
	
	if item.size() > 0:
		idx = arr.find(item[0])
	
	if idx == -1:
		return []
	
	return arr.slice(idx, -1)
