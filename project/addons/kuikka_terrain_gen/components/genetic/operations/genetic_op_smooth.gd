class_name GeneticOperationSmooth extends GeneticOperation


## Applies genetic operation to [param sample] and returns the
## resulting [Image]
func apply_operation(img : Image) -> Image:
	
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	
	var mean = 0
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		mean += img.get_pixel(x, y).r
	
	if size != 0:
		mean /= size
	else: 
		mean = 0
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = img.get_pixel(x, y)
		var result = Color(clampf(color.r+(mean-color.r)*0.5*strength, 0.0, 1.0), 
					clampf(color.g+(mean-color.g)*0.5*strength, 0.0, 1.0),
					clampf(color.b+(mean-color.b)*0.5*strength, 0.0, 1.0))
		img.set_pixel(x, y, result)
	
	return img

