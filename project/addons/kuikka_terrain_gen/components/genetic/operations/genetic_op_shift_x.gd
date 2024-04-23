class_name GeneticOperationShiftX extends GeneticOperation

## Shift image towards positive y for maximum of half image
## replacing original values with the last row blended to empty.
func apply_operation(img : Image) -> Image:
	
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	
	var bytes = img.get_data()
	
	var shift = floor(strength * 0.5 * w)
	var first_col = []
	
	# Get column row for reference
	for ry in h:
		first_col.append(img.get_pixel(0, ry))
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Blend shifted edge edge.
		if x < shift:
			img.set_pixel(x, y, first_col[y]*x/shift)
		# New values from shift.
		else:
			var color = img.get_pixel(x-shift, y)
			img.set_pixel(x, y, color)
	
	return img
