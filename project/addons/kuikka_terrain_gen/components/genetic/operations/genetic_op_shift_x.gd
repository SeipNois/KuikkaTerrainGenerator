class_name GeneticOperationShiftX extends GeneticOperation

## Shift image towards positive y for maximum of half image
## replacing original values with the last row blended to empty.
func apply_operation(img : Image) -> Image:
	
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	
	var copy = img.duplicate()
	
	var shift = floor(strength * 0.5 * w)
	var first_col = []
	
	# Get column row for reference
	#for ry in h:
		#first_col.append(img.get_pixel(0, ry))
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Blend shifted edge edge.
		if x < shift:
			img.set_pixel(x, y, Color(0, 0, 0, 0))#first_col[y]*x/shift)
		# New values from shift.
		else:
			var color = img.get_pixel(x-shift, y)
			img.set_pixel(x, y, color)
	
	return img


## Applies genetic operation to image at [param path] using
## imagemagick command line tools.
func apply_operation_path(path : String) -> Image:
	var ext = FilePath.get_extension(path)
	#var op_path = path.rstrip(ext) + "_processed" + ext
	
	KuikkaImgUtil.img_magick_execute(["convert", path, "-page", "+%d+0" % round(strength * 100), "-background", "none", path])
	var img : Image = await Image.load_from_file(path)
	#img.save_png(path)"
	
	return img
