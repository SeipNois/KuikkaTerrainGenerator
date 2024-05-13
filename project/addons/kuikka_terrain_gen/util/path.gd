class_name FilePath extends Object

## Filepath related utility functions.

## Get file extension from filepath.
static func get_extension(path: String):
	return "."+path.split(".")[-1]


## Find filename section of filepath omitting file extension.
static func get_filename(path: String):
	# Ensure UNIX style delimiters.
	path = path.replace("\\", "/")
	var file = path.split("/")[-1]
	var split = file.rfind(".")
	var result = file.substr(0, split)
	return result
	
	
## Find directory of file path omitting last part as filename.
static func get_directory(path: String):
	path = ProjectSettings.globalize_path(path)
	
	# Is filepath.
	if FileAccess.file_exists(path):
		# Ensure UNIX style delimiters.
		path = path.replace("\\", "/")
		var split = path.rfind("/")
		var result = path.substr(0, split)
		return result
		
	# Is already directory path.
	elif DirAccess.dir_exists_absolute(path):
		return path



## Join array elements into filepath with "/" separator.
static func join(arr: Array[String]):
	return "/".join(arr)
