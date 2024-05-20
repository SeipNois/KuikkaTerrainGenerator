class_name GeneticOperationShiftY extends GeneticOperation

## Shift image towards positive y for maximum of half image
## replacing original values with the last row blended to empty.
func apply_operation(img : Image) -> Image:
	
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	
	var bytes = img.get_data()
	
	var shift = floor(strength * 0.5 * h)
	var first_row = []
	
	# Get first row for reference
	for rx in h:
		first_row.append(img.get_pixel(rx, 0))
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Blend shifted edge edge.
		if y < shift:
			img.set_pixel(x, y, first_row[x]*y/shift)
		# New values from shift.
		else:
			var color = img.get_pixel(x, y-shift)
			img.set_pixel(x, y, color)
	
	return img


## Applies genetic operation to image at [param path] using
## imagemagick command line tools.
func apply_operation_path(path : String) -> void:
	return
