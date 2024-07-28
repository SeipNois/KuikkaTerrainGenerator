class_name GeneticOperationRise extends GeneticOperation


## Applies genetic operation to [param sample] and returns the
## resulting [Image]
func apply_operation(img : Image) -> Image:
	
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	var copy = img.duplicate()
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = img.get_pixel(x, y)
		var result = Color(clampf(color.r+0.1*strength, 0.0, 1.0), 
					clampf(color.g+0.1*strength, 0.0, 1.0),
					clampf(color.b+0.1*strength, 0.0, 1.0))
		copy.set_pixel(x, y, result)
	img=copy
	
	return img



## Applies genetic operation to image at [param path] using
## imagemagick command line tools.
func apply_operation_path(path : String) -> Image:
	var ext = FilePath.get_extension(path)
	# var op_path = path.rstrip(ext) + "_processed" + ext
	
	KuikkaImgUtil.img_magick_execute(["convert", path, "-modulate", (110*strength), path])
	#KuikkaImgUtil.gdal_calc(path, op_path, "+%f" % (strength*0.1))
	var img : Image = await Image.load_from_file(path)
	#img.save_png(path)
	
	return img
