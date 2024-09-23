class_name Fitness extends Node

## Fitness function as collection of calculations to 
## calculate fitness value from heightmap sample.


## Calculate total fitness from heightmap [param img] based on difference to 
## references [FitnessParameters][param reference].
static func calculate_img_fitness(img: Image, reference: FitnessParameters) -> float:
	var fit_params : FitnessParameters = img_get_fitness_params(img)
	var sum = 0
	sum += fit_params.difference(reference)
	return sum
	


static func img_get_fitness_params(img : Image) -> FitnessParameters:
	var result = FitnessParameters.new()
	
	var min = Fitness.img_get_min(img)
	var max = Fitness.img_get_max(img)
	var mean = Fitness.img_get_mean(img) 
	var variance = Fitness.img_get_variance(img, mean)
	
	result.min_height = min
	result.max_height = max
	result.mean = mean
	result.variance = variance
	# result.hill_frequency = Fitness.img_get_frequency(img)
	
	# print_debug(result.min_height, " ", result.max_height, " ", result.mean, " ", result.variance)
	
	return result


## Get minimum value in heightmap image.
## NOTE: Uses red channel, considering image monochrome.
static func img_get_min(img : Image) -> float:
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	var minimum : float = -1
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = img.get_pixel(x, y)
		if not minimum or minimum < 0:
			minimum = color.r
		else:
			minimum = min(color.r, minimum)
			
	return minimum
	
		
## Get maximum value in heightmap image.
## NOTE: Uses red channel, considering image monochrome.
static func img_get_max(img : Image) -> float:
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	var maximum : float = -1
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = img.get_pixel(x, y)
		if not maximum or maximum < 0:
			maximum = color.r
		else:
			maximum = max(color.r, maximum)
	
	return maximum

## Get mean value in heightmap image.
## NOTE: Uses red channel, considering image monochrome.
static func img_get_mean(img : Image) -> float:
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	var sum : float = 0
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = img.get_pixel(x, y)
		sum += color.r

	#print_debug("Region mean, ", w, " ", h, " : ", sum/size if size > 0 else 0)

	return sum/size if size > 0 else 0


## Get value variance in heightmap image.
## NOTE: Uses red channel, considering image monochrome.
static func img_get_variance(img : Image, mean: float=NAN) -> float:
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	var sum : float = 0
	
	# Calculate average if not given
	if mean == NAN:
		push_warning("Image mean value not specified for variance calculation. Calculating manually.")
		mean = img_get_mean(img)
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = img.get_pixel(x, y)
		sum += (color.r-mean)**2
	
	return sum/size


#static func img_get_frequency(img):
	### TODO: Implement.
	#var fft = fft2d(img)
	#return fft

#
### Calculate FFT for image by rows using Godot-fft Fast fourier transform.
#static func fft2d(img : Image):
	#var byte_array : PackedByteArray = img.save_png_to_buffer()
	#var ffts = []
	#var w = img.get_width()
	#
	#for y in img.get_height():
		## Calculate fft by row
		#var subarr = byte_array.slice(y*w, (y+1)*w)
		#ffts.append_array(FFT.fft(subarr))
	#
	## var result = FFT.fft(ffts)
	#var result = ffts.map(func(comp): return comp if comp is int else comp.re)
	#return result

#
#static func visualize_fft2(img : Image):
	#var array = fft2d(img)
	#var w = floor(sqrt(array.size()))
	#var new_img = Image.create(w, w, false, Image.FORMAT_RGBA8)
	#
	#for y in w:
		#for x in w:
			#var i = w*y+x
			#var c = array[i]
			#new_img.set_pixel(x, y, Color(c, c, c))
