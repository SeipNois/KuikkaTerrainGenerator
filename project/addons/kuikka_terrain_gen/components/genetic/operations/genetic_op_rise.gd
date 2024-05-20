class_name GeneticOperationRise extends GeneticOperation


## Applies genetic operation to [param sample] and returns the
## resulting [Image]
func apply_operation(img : Image) -> Image:
	
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	
	var bytes = img.get_data()
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = img.get_pixel(x, y)
		var result = Color(clampf(color.r+0.1*strength, 0.0, 1.0), 
					clampf(color.g+0.1*strength, 0.0, 1.0),
					clampf(color.b+0.1*strength, 0.0, 1.0))
		img.set_pixel(x, y, result)
	
	return img


## Applies genetic operation to image at [param path] using
## imagemagick command line tools.
func apply_operation_path(path : String) -> void:
	return
