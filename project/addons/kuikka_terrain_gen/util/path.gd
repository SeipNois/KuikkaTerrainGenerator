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


## Join array elements into filepath with "/" separator.
static func join(arr: Array[String]):
	return "/".join(arr)
