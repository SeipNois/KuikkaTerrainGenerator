class_name GdalUtils extends Node

## Uses OSGeo GDAL Library through separate process to
## Convert GeoTIFF Images to Godot supported Image format.


const GDAL_TRANSLATE = "/gdal_translate.exe"

enum ImgFormat {PNG, EXR}

@export var gdal_path : StringName =  ProjectSettings.globalize_path(
	ProjectSettings.get_setting("kuikka_terrain_gen/gdal_path") if ProjectSettings.get_setting("kuikka_terrain_gen/gdal_path") else "")
var _active_process_ids : Array[int]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## Set path to gdal executables
func set_gdal_path(path: StringName):
	gdal_path = path


## Convert all valid images in given directory to given format using gdal_translate.
func gdal_translate_directory(directory : String, destination: String, format: ImgFormat):
	if not try_load_gdal_executable():
		printerr("Gdal executables could not be located! Please check gdal_path set in ProjectSettings.")
		return
		
	directory = ProjectSettings.globalize_path(directory)
	destination = ProjectSettings.globalize_path(destination)
	var files = DirAccess.get_files_at(directory)
	
	for f in files:
		await gdal_translate_one(FilePath.join([directory, f]), destination, format)
		await get_tree().create_timer(0.002).timeout


## Convert all files in given path between formats
## [param filepaths] Array of file paths of files to convert to another format.
## [param destination] Filepath of the destination directory for converted files.
## [param format] Image format to convert to.
func gdal_translate_batch(filepaths : Array, destination: String, format: ImgFormat):
	if not try_load_gdal_executable():
		printerr("Gdal executables could not be located! Please check gdal_path set in ProjectSettings.")
		return
		
	for f in filepaths:
		await gdal_translate_one(f, destination, format)
	

## Convert all files in given path between formats
## [param filepath] Path of file to convert to another format.
## [param destination] Filepath of the destination directory for converted files.
## [param format] Image format to convert to.
## [param keep_world_data] Save georeferencing data to separate pgw file.
## @tutorial https://gdal.org/programs/gdal_translate.html
func gdal_translate_one(filepath : String, destination: String, format: ImgFormat, keep_world_data: bool=false):
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
	
	var args = ["-of", form_str]
	
	#if format == ImgFormat.PNG or format == 0:
		#args.append_array(["-ot", "UInt16", "-scale", "32.53501", "767.4913", "0", "65535"])
	if keep_world_data:
		args.append_array(["-co", "WORLDFILE=YES"])
	
	args.append_array([filepath, dest_file])
	
	print_debug("Attempting to convert %s => %s" % [filepath, dest_file])
	print_debug("Args: ", args)
	var exitc = OS.execute(gdal_path+GDAL_TRANSLATE, args, result, OS.is_debug_build(), OS.is_debug_build())
	if exitc == -1:
		printerr("Gdal translation failed.")
	else:
		print(result[0])
		
	# return result


## Check that gdal executables exist in given path
func try_load_gdal_executable() -> bool:
	if not gdal_path or gdal_path == "":
		return false
		
	return FileAccess.file_exists(gdal_path+GDAL_TRANSLATE)
