extends Node

## Image processing related utilities

@onready var _gdal = $GDAL
@onready var _img_magick = $ImageMagick


## * * * Common * * *
## Get minimum value in heightmap image.


## Get collection of statistics from image.
func img_get_stats(path: String, extended_features: bool = false):
	path = ProjectSettings.globalize_path(path)
	return im_fetch_img_stats(path, extended_features)


## NOTE: Uses red channel, considering image monochrome.
func img_get_min(path : String) -> float:
	return 0
	
	#var w = img.get_width()
	#var h = img.get_height()
	#var size = w*h
	#var minimum : float = -1
	#
	#for i in size:
		#var x = i % w
		#var y = floor(i / w)
		#
		#var color = img.get_pixel(x, y)
		#if not minimum or minimum < 0:
			#minimum = color.r
		#else:
			#minimum = min(color.r, minimum)
			#
	#return minimum
	
		
## Get maximum value in heightmap image.
## NOTE: Uses red channel, considering image monochrome.
func img_get_max(path : String) -> float:
	return 0
	
	#var w = img.get_width()
	#var h = img.get_height()
	#var size = w*h
	#var maximum : float = -1
	#
	#for i in size:
		#var x = i % w
		#var y = floor(i / w)
		#
		#var color = img.get_pixel(x, y)
		#if not maximum or maximum < 0:
			#maximum = color.r
		#else:
			#maximum = max(color.r, maximum)
	#
	#return maximum


## Get mean value in heightmap image.
## NOTE: Uses red channel, considering image monochrome.
func img_get_mean(path : String) -> float:
	return 0
	
	#var w = img.get_width()
	#var h = img.get_height()
	#var size = w*h
	#var sum : float = 0
	#
	#for i in size:
		#var x = i % w
		#var y = floor(i / w)
		#
		#var color = img.get_pixel(x, y)
		#sum += color.r
#
	#return sum/size


## Get value variance in heightmap image.
## NOTE: Uses red channel, considering image monochrome.
func img_get_variance(img : Image, mean: float=NAN) -> float:
	return 0
	#
	#var w = img.get_width()
	#var h = img.get_height()
	#var size = w*h
	#var sum : float = 0
	#
	## Calculate average if not given
	#if mean == NAN:
		#push_warning("Image mean value not specified for variance calculation. Calculating manually.")
		#mean = img_get_mean(img)
	#
	#for i in size:
		#var x = i % w
		#var y = floor(i / w)
		#
		#var color = img.get_pixel(x, y)
		#sum += (color.r-mean)**2
	#
	# return sum/size


func img_get_frequency(path: String):
	pass
	
	### TODO: Implement.
	#var fft = fft2d(img)
	#return fft


## Calculate FFT for image by rows using Godot-fft Fast fourier transform.
func fft2d(img : Image):
	var byte_array : PackedByteArray = img.save_png_to_buffer()
	var ffts = []
	var w = img.get_width()
	
	for y in img.get_height():
		# Calculate fft by row
		var subarr = byte_array.slice(y*w, (y+1)*w)
		ffts.append_array(FFT.fft(subarr))
	
	# var result = FFT.fft(ffts)
	var result = ffts.map(func(comp): return comp if comp is int else comp.re)
	return result


func visualize_fft2(img : Image):
	var array = fft2d(img)
	var w = floor(sqrt(array.size()))
	var new_img = Image.create(w, w, false, Image.FORMAT_RGBA8)
	
	for y in w:
		for x in w:
			var i = w*y+x
			var c = array[i]
			new_img.set_pixel(x, y, Color(c, c, c))



## * * * GDAL * * * *

func gdal_translate_directory(directory : String, destination: String, format: GdalUtils.ImgFormat):
	_gdal.gdal_translate_directory(directory,destination,format)


func gdal_translate_batch(filepaths : Array, destination: String, format: GdalUtils.ImgFormat):
	_gdal.gdal_translate_batch(filepaths,destination,format)


func gdal_translate_one(filepath : String, destination: String, format: GdalUtils.ImgFormat, keep_world_data: bool=false):
	_gdal.gdal_translate_one(filepath,destination,format,keep_world_data)


func gdal_fetch_img_stats(path: String):
	path = ProjectSettings.globalize_path(path)
	return _gdal.fetch_img_stats(path)


## * * * ImageMagick * * * *

func im_fetch_img_stats(path: String, extended_features: bool = false):
	path = ProjectSettings.globalize_path(path)
	return _img_magick.fetch_img_stats(path, extended_features)


## Execute imagemagick from commandline with arbitrary arguments.
func img_magick_execute(args: Array):
	return _img_magick.execute(args)
	
