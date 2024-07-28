extends Node

## Image processing related utilities

@onready var _gdal = $GDAL
@onready var _img_magick = $ImageMagick


## * * * Common API * * *
## Get minimum value in heightmap image.


## Get collection of statistics from image.
func img_get_stats(path: String, extended_features: bool = false, debug : bool = false) -> Dictionary:
	path = ProjectSettings.globalize_path(path)
	return im_fetch_img_stats(path, extended_features, debug)


## Try to parse [Dictionary] into [HeightProfile] format.
func dict_to_height_profile(dict: Dictionary) -> HeightProfile:
	const KEYS = ["min", "max", "mean", "median", "std_dev", "kurtosis", "entropy", "skewness"]
	var hprofile = HeightProfile.new()
	
	for key in KEYS:
		if dict.has(key):
			hprofile.set(key, dict[key])
		else:
			printerr("Dictionary missing key ", key, "omitting from height profile.")
		
	return hprofile



## Try to parse [Dictionary] into [HeightProfile] format.
static func terrain_image_to_dict(timg: TerrainFeatureImage) -> Dictionary:
	const KEYS_HPROFILE = ["min", "max", "mean", "median", "std_dev", "kurtosis", "entropy", "skewness"]
	const KEYS_FEATURE = ["size_min", "size_max", "size_mean", "size_median", "size_std_dev", "gen_height_min", "gen_height_max", "gen_height_mean", "gen_height_median", "gen_height_std_dev"]
	
	var dict = {}
	
	dict["height_profile"] = {}
	
	for key in KEYS_HPROFILE:
		dict.height_profile[key] = timg.height_profile.get(key)
	
	for feature in timg.features.keys():
		dict[feature] = {}
		for key in KEYS_FEATURE:
			dict[feature][key] = timg.features[feature].get(key)
	
	return dict



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


## # # # # # # # # # # # # # # # # 
## * * * UTIL OPERATIONS * * * *

## Multiply [Image][param img] alpha channel values with [param mult].
static func image_mult_alpha(img: Image, mult: float) -> Image:
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = img.get_pixel(x, y)
		color.a = color.a * mult
		img.set_pixel(x, y, color)
	return img


## Multiply [Image][param img] rgb channel values with [param mult].
static func image_scale_values(img: Image, mult: float) -> Image:
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		
		var color = img.get_pixel(x, y)
		
		# Offset to scale relative to 0.5 not 0.
		color.r = (color.r-0.5) * mult + 0.5
		color.g = (color.g - 0.5) * mult + 0.5
		color.b = (color.b - 0.5) * mult + 0.5
		
		img.set_pixel(x, y, color)
	return img



## Set [Image][param img] alpha channel pixels to given [param val].
static func image_set_alpha(img: Image, val: float) -> Image:
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = img.get_pixel(x, y)
		color.a = val
		img.set_pixel(x, y, color)
	return img



## Offset [Image][param img] color channels by given value [param offset]
static func image_offset(img: Image, offset: float) -> Image:
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = img.get_pixel(x, y)
		color.r += offset
		color.g += offset
		color.b += offset
		
		img.set_pixel(x, y, color)
	return img


## Switch [param img] alpha channel with given [param channel] from [alpha_image]
static func images_blend_alpha(img: Image, alpha_image: Image, channel:String="a") -> Image:
	var w = img.get_width()
	var h = img.get_height()
	var size = w*h
	var result = img.duplicate()
	
	if alpha_image.get_width() != img.get_width() or \
	alpha_image.get_height() != img.get_height():
		printerr("Alpha blending images requires mask to be same size as source image! It will be resized to fit.")
		alpha_image.resize(img.get_width(), img.get_height())
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var color = result.get_pixel(x, y)
		var acolor = alpha_image.get_pixel(x, y)
		match channel:
			"r":
				color.a = acolor.r
			"g":
				color.a = acolor.g
			"b":
				color.a = acolor.b
			_:
				color.a = acolor.a
		result.set_pixel(x, y, color)
	return result

## * * * * * * * * * * *
## Image blending methods

## Blend [param src_img] to [param dest_img] with laplace weight using [param mask].
static func laplace_blend(dest_img: Image, src_img: Image, mask: Image):
	pass


## Blend [param rect] from [src_img] to [param dest_img] using value 
## difference as result.
static func blend_rect_sum(dest_img: Image, src_img: Image, rect: Rect2i, pos:Vector2i):
	var w = rect.size.x
	var h = rect.size.y
	var o = rect.position
	var size = w * h
	
	var dest_w = dest_img.get_width()
	var dest_h = dest_img.get_height()
	var src_w = src_img.get_width()
	var src_h = src_img.get_height()
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Skip if outside result image bounding rect or outside blending rect.
		if pos.x+x >= dest_w or  pos.y+y >= dest_h \
		or o.x+x >= src_w or o.y >= src_h:
			continue
		
		var base = dest_img.get_pixel(pos.x+x, pos.y+y)
		var add = src_img.get_pixel(o.x+x, o.y+y)
		
		# Sum based on difference
		var color = base
		color.r += (add.r-color.r)*add.a
		color.g += (add.g-color.g)*add.a
		color.b += (add.b-color.b)*add.a
		
		dest_img.set_pixel(pos+x, pos+y, color)
	
	return dest_img


## Blend [param rect] from [src_img] to [param dest_img] using value 
## difference as result.
static func blend_rect_sum_mask(dest_img: Image, src_img: Image, mask_img: Image, rect: Rect2i, pos:Vector2i, mask_ch:String="a"):
	var w = rect.size.x
	var h = rect.size.y
	var o = rect.position
	var size = w * h
	
	var dest_w = dest_img.get_width()
	var dest_h = dest_img.get_height()
	var src_w = src_img.get_width()
	var src_h = src_img.get_height()
	
	if mask_img.get_width() != src_img.get_width() or mask_img.get_height() != src_img.get_height():
		push_warning("<blend_rect_sum_mask()> Mask image size doesn't match 
		source image, it will be resized to fit.")
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Skip if outside result image bounding rect or outside blending rect.
		if pos.x+x >= dest_w or  pos.y+y >= dest_h \
		or o.x+x >= src_w or o.y >= src_h:
			continue
		
		var base = dest_img.get_pixel(pos.x+x, pos.y+y)
		var add = src_img.get_pixel(o.x+x, o.y+y)
		var alpha = 0
		
		match mask_ch:
			"r":
				alpha = mask_img.get_pixel(x, y).r
			"g":
				alpha = mask_img.get_pixel(x, y).g
			"b":
				alpha = mask_img.get_pixel(x, y).b
			_:
				alpha = mask_img.get_pixel(x, y).a
		
		# Sum based on difference
		var color = base
		color.r += (add.r-color.r)*alpha
		color.g += (add.g-color.g)*alpha
		color.b += (add.b-color.b)*alpha
		
		dest_img.set_pixel(pos.x+x, pos.y+y, color)
	
	return dest_img


## Blend [param rect] from [src_img] to [param dest_img] using [param offset]
## luminance to blend dest_img - src_img value difference relative to it.
static func blend_rect_diff(dest_img: Image, src_img: Image, rect: Rect2i, pos:Vector2i, offset: float=0):
	var w = rect.size.x
	var h = rect.size.y
	var o = rect.position
	var size = w * h
	
	var dest_w = dest_img.get_width()
	var dest_h = dest_img.get_height()
	var src_w = src_img.get_width()
	var src_h = src_img.get_height()
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Skip if outside result image bounding rect or outside blending rect.
		if pos.x+x >= dest_w or  pos.y+y >= dest_h \
		or o.x+x >= src_w or o.y >= src_h or pos.x+x < 0 or pos.y+y < 0:
			continue
		
		var base = dest_img.get_pixel(pos.x+x, pos.y+y)
		var add = src_img.get_pixel(o.x+x, o.y+y)
		
		# Sum based on difference
		var color = base
		
		var radd = (add.r-offset)*add.a
		var gadd = (add.g-offset)*add.a
		var badd = (add.b-offset)*add.a
		
		# Multiply to weight towards middle as to not blend over limits.
		#radd *= sqrt(1-base.r) if radd > 0 else sqrt(base.r)
		#gadd *= sqrt(1-base.g) if gadd > 0 else sqrt(base.g)
		#badd *= sqrt(1-base.b) if badd > 0 else sqrt(base.b)
		
		color.r += radd 
		color.g += gadd
		color.b += badd
		
		dest_img.set_pixel(pos.x+x, pos.y+y, color)
	
	return dest_img


## Blend [param rect] from [src_img] to [param dest_img] using mean of src_img
## luminance to blend dest_img - src_img value difference relative to it.
static func blend_rect_diff_mask(dest_img: Image, src_img: Image, mask_img: Image, rect: Rect2i, pos:Vector2i, offset: float=0, mask_ch:String="a"):
	var w = rect.size.x
	var h = rect.size.y
	var o = rect.position
	var size = w * h
	
	var dest_w = dest_img.get_width()
	var dest_h = dest_img.get_height()
	var src_w = src_img.get_width()
	var src_h = src_img.get_height()
	
	if mask_img.get_width() != src_img.get_width() or mask_img.get_height() != src_img.get_height():
		push_warning("<blend_rect_sum_mask()> Mask image size doesn't match 
		source image, it will be resized to fit.")
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Skip if outside result image bounding rect or outside blending rect.
		if pos.x+x >= dest_w or  pos.y+y >= dest_h \
		or o.x+x >= src_w or o.y >= src_h or pos.x+x < 0 or pos.y+y < 0:
			continue
		
		var base = dest_img.get_pixel(pos.x+x, pos.y+y)
		var add = src_img.get_pixel(o.x+x, o.y+y)
		var alpha = 0
		
		match mask_ch:
			"r":
				alpha = mask_img.get_pixel(x, y).r
			"g":
				alpha = mask_img.get_pixel(x, y).g
			"b":
				alpha = mask_img.get_pixel(x, y).b
			_:
				alpha = mask_img.get_pixel(x, y).a
		
		# Sum based on difference
		var color = base
		
		var radd = (add.r-offset)*alpha
		var gadd = (add.g-offset)*alpha
		var badd = (add.b-offset)*alpha
		
		color.r += radd
		color.g += gadd
		color.b += badd
		
		dest_img.set_pixel(pos.x+x, pos.y+y, color)
	
	return dest_img


## Blend [param rect] from [src_img] to [param dest_img] using [param offset]
## luminance to blend dest_img - src_img value difference relative to it.
static func blend_diff_mult(dest_img: Image, src_img: Image, rect: Rect2i, pos:Vector2i, offset: float=0):
	var w = rect.size.x
	var h = rect.size.y
	var o = rect.position
	var size = w * h
	
	var dest_w = dest_img.get_width()
	var dest_h = dest_img.get_height()
	var src_w = src_img.get_width()
	var src_h = src_img.get_height()
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Skip if outside result image bounding rect or outside blending rect.
		if pos.x+x >= dest_w or  pos.y+y >= dest_h \
		or o.x+x >= src_w or o.y >= src_h or pos.x+x < 0 or pos.y+y < 0:
			continue
		
		var base = dest_img.get_pixel(pos.x+x, pos.y+y)
		var add = src_img.get_pixel(o.x+x, o.y+y)
		
		# Sum based on difference
		var color = base
		
		var radd = (add.r-offset)*add.a
		var gadd = (add.g-offset)*add.a
		var badd = (add.b-offset)*add.a
		
		# Multiply to weight towards middle as to not blend over limits.
		#radd *= sqrt(1-base.r) if radd > 0 else sqrt(base.r)
		#gadd *= sqrt(1-base.g) if gadd > 0 else sqrt(base.g)
		#badd *= sqrt(1-base.b) if badd > 0 else sqrt(base.b)
		
		# get values as mean
		color.r = (color.r + color.r+radd) / (2+(-0.3*sign(radd)))
		color.g = (color.g + color.g+radd) / (2+(-0.3*sign(gadd)))
		color.b = (color.b + color.b+radd) / (2+(-0.3*sign(badd)))
		
		dest_img.set_pixel(pos.x+x, pos.y+y, color)
	
	return dest_img


## Blend [param rect] from [src_img] to [param dest_img] using mean of src_img
## luminance to blend dest_img - src_img value difference relative to it.
static func blend_diff_mult_mask(dest_img: Image, src_img: Image, mask_img: Image, rect: Rect2i, pos:Vector2i, offset: float=0, mask_ch:String="a"):
	var w = rect.size.x
	var h = rect.size.y
	var o = rect.position
	var size = w * h
	
	var dest_w = dest_img.get_width()
	var dest_h = dest_img.get_height()
	var src_w = src_img.get_width()
	var src_h = src_img.get_height()
	
	if mask_img.get_width() != src_img.get_width() or mask_img.get_height() != src_img.get_height():
		push_warning("<blend_rect_sum_mask()> Mask image size doesn't match 
		source image, it will be resized to fit.")
	
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Skip if outside result image bounding rect or outside blending rect.
		if pos.x+x >= dest_w or  pos.y+y >= dest_h \
		or o.x+x >= src_w or o.y >= src_h or pos.x+x < 0 or pos.y+y < 0:
			continue
		
		var base = dest_img.get_pixel(pos.x+x, pos.y+y)
		var add = src_img.get_pixel(o.x+x, o.y+y)
		var alpha = 0
		
		match mask_ch:
			"r":
				alpha = mask_img.get_pixel(x, y).r
			"g":
				alpha = mask_img.get_pixel(x, y).g
			"b":
				alpha = mask_img.get_pixel(x, y).b
			_:
				alpha = mask_img.get_pixel(x, y).a
		
		# Sum based on difference
		var color = base
		
		var radd = (add.r-offset)
		var gadd = (add.g-offset)
		var badd = (add.b-offset)
		
		color.r = (base.r + base.r+radd*1.6) / (2+(-0.01*sign(radd)))
		color.g = (base.g + base.g+gadd*1.6) / (2+(-0.01*sign(gadd)))
		color.b = (base.b + base.b+badd*1.6) / (2+(-0.01*sign(badd)))
		
		color.r = (color.r-base.r)*alpha + base.r
		color.g = (color.g-base.g)*alpha + base.g
		color.b = (color.b-base.b)*alpha + base.b
		
		dest_img.set_pixel(pos.x+x, pos.y+y, color)
	
	return dest_img


## Blend image by gradient calculated from pixel neighbour difference.
func blend_poisson(dest_img: Image, src_img: Image, rect: Rect2i, pos:Vector2i, offset: float=0, mask_ch:String="a"):
	var poisson_mask = Image.create(src_img.get_width(), src_img.get_height(), false, src_img.get_format())
	var w = rect.size.x
	var h = rect.size.y
	var o = rect.position
	var size = w * h
	
	# Calculate gradient mask
	for i in size:
		var x = i % w
		var y = floor(i / w)
	
		var neighbours = []
		
		# WEST
		if x - 1 >= 0:
			neighbours.append(src_img.get_pixel(x-1, y))
		# EAST
		if x + 1 < src_img.get_width():
			neighbours.append(src_img.get_pixel(x+1, y))
		# NORTH
		if y - 1 >= 0:
			neighbours.append(src_img.get_pixel(x, y-1))
		# SOUTH
		if y + 1 < src_img.get_height():
			neighbours.append(src_img.get_pixel(x, y+1))
		
		# Use red channel (grayscale images), Gradient as mean difference
		# to neighbours.
		var base = src_img.get_pixel(x, y).r
		var f = neighbours.map(func(p): return base - p.r)
		# var mean = abs(KuikkaUtils.mean(f) / (f.size() if f.size() > 0 else 1))
		var mean = 0
		mean = abs(f.reduce(func(mean, x): return mean+x, mean)) * 100
		
		poisson_mask.set_pixel(x, y, Color(mean, mean, mean, mean))
	
	var result = blend_rect_diff_mask(dest_img, src_img, poisson_mask, rect, pos, offset, mask_ch)
	
	dest_img = result
	return result


func blend_poisson_mask(dest_img: Image, src_img: Image, mask_img: Image, rect: Rect2i, pos:Vector2i, offset: float=0, mask_ch:String="a"):
	var poisson_mask = Image.create(src_img.get_width(), src_img.get_height(), false, src_img.get_format())
	var w = rect.size.x
	var h = rect.size.y
	var o = rect.position
	var size = w * h
	
	var dest_w = dest_img.get_width()
	var dest_h = dest_img.get_height()
	var src_w = src_img.get_width()
	var src_h = src_img.get_height()
	
	# Calculate gradient mask
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		var neighbours = []
		
		# WEST
		if x - 1 >= 0:
			neighbours.append(src_img.get_pixel(x-1, y))
		# EAST
		if x + 1 < src_img.get_width():
			neighbours.append(src_img.get_pixel(x+1, y))
		# NORTH
		if y - 1 >= 0:
			neighbours.append(src_img.get_pixel(x, y-1))
		# SOUTH
		if y + 1 < src_img.get_height():
			neighbours.append(src_img.get_pixel(x, y+1))
		
		# Use red channel (grayscale images), Gradient as mean difference
		# to neighbours.
		var base = src_img.get_pixel(x, y).r
		var f = neighbours.map(func(p): return base - p.r)
		# var mean = abs(KuikkaUtils.mean(f) / (f.size() if f.size() > 0 else 1))
		var mean = 0
		mean = clampf(abs(f.reduce(func(mean, x): return mean+x, mean)) * 100, 0, 1)
		
		poisson_mask.set_pixel(x, y, Color(mean, mean, mean, mean))
	
	# Blend alpha mask
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Skip if outside result image bounding rect or outside blending rect.
		if pos.x+x >= dest_w or  pos.y+y >= dest_h \
		or o.x+x >= src_w or o.y >= src_h or pos.x+x < 0 or pos.y+y < 0:
			continue
		
		var base = dest_img.get_pixel(pos.x+x, pos.y+y)
		var add = src_img.get_pixel(o.x+x, o.y+y)
		var alpha = 0
		
		match mask_ch:
			"r":
				alpha = mask_img.get_pixel(x, y).r * poisson_mask.get_pixel(x, y).r
			"g":
				alpha = mask_img.get_pixel(x, y).g * poisson_mask.get_pixel(x, y).g
			"b":
				alpha = mask_img.get_pixel(x, y).b * poisson_mask.get_pixel(x, y).b
			_:
				alpha = mask_img.get_pixel(x, y).a * poisson_mask.get_pixel(x, y).a
		
		# Sum based on difference
		var color = base
		
		var radd = (add.r-offset)*alpha
		var gadd = (add.g-offset)*alpha
		var badd = (add.b-offset)*alpha
		
		color.r += radd
		color.g += gadd
		color.b += badd
		
		dest_img.set_pixel(pos.x+x, pos.y+y, color)
	
	return dest_img


## Blend weighted by value difference compared to blending offset.
func blend_mean_diff(dest_img: Image, src_img: Image, rect: Rect2i, pos:Vector2i, offset: float=0, mask_ch:String="a"):
	var poisson_mask = Image.create(src_img.get_width(), src_img.get_height(), false, src_img.get_format())
	var w = rect.size.x
	var h = rect.size.y
	var o = rect.position
	var size = w * h
	
	# Calculate gradient mask
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Use red channel (grayscale images)
		var base = src_img.get_pixel(x, y).r
		var f = abs(base - offset)
		
		poisson_mask.set_pixel(x, y, Color(base, base, base, base))
	
	var result = blend_rect_diff_mask(dest_img, src_img, poisson_mask, rect, pos, offset, mask_ch)
	
	dest_img = result
	return result


func blend_mean_diff_mask(dest_img: Image, src_img: Image, mask_img: Image, rect: Rect2i, pos:Vector2i, offset: float=0, mask_ch:String="a"):
	var poisson_mask = Image.create(src_img.get_width(), src_img.get_height(), false, src_img.get_format())
	var w = rect.size.x
	var h = rect.size.y
	var o = rect.position
	var size = w * h
	
	var dest_w = dest_img.get_width()
	var dest_h = dest_img.get_height()
	var src_w = src_img.get_width()
	var src_h = src_img.get_height()
	
	# Calculate gradient mask
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Use red channel (grayscale images)
		var base = src_img.get_pixel(x, y).r
		#print_debug("Color ", base)
		var f = abs(base - offset)
		
		poisson_mask.set_pixel(x, y, Color(base, base, base, base))
	
	
	# Blend alpha mask
	for i in size:
		var x = i % w
		var y = floor(i / w)
		
		# Skip if outside result image bounding rect or outside blending rect.
		if pos.x+x >= dest_w or  pos.y+y >= dest_h \
		or o.x+x >= src_w or o.y >= src_h or pos.x+x < 0 or pos.y+y < 0:
			continue
		
		var base = dest_img.get_pixel(pos.x+x, pos.y+y)
		var add = src_img.get_pixel(o.x+x, o.y+y)
		var alpha = 0
		
		match mask_ch:
			"r":
				alpha = mask_img.get_pixel(x, y).r * poisson_mask.get_pixel(x, y).r
			"g":
				alpha = mask_img.get_pixel(x, y).g * poisson_mask.get_pixel(x, y).g
			"b":
				alpha = mask_img.get_pixel(x, y).b * poisson_mask.get_pixel(x, y).b
			_:
				alpha = mask_img.get_pixel(x, y).a * poisson_mask.get_pixel(x, y).a
		
		# Sum based on difference
		var color = base
		
		var radd = (add.r-offset)*alpha
		var gadd = (add.g-offset)*alpha
		var badd = (add.b-offset)*alpha
		
		color.r += radd
		color.g += gadd
		color.b += badd
		
		dest_img.set_pixel(pos.x+x, pos.y+y, color)
	
	return dest_img


## * * * GDAL * * * *

func gdal_translate_directory(directory : String, destination: String, format: GdalUtils.ImgFormat, bits: int):
	_gdal.gdal_translate_directory(directory, destination, format, bits)


func gdal_translate_batch(filepaths : Array, destination: String, format: GdalUtils.ImgFormat, bits: int, debug:bool=false):
	_gdal.gdal_translate_batch(filepaths, destination, format, bits, debug)


func gdal_translate_one(filepath : String, destination: String, format: GdalUtils.ImgFormat, bits: int, keep_world_data: bool=false,  debug:bool=false):
	_gdal.gdal_translate_one(filepath, destination, format, bits, keep_world_data, debug)


func gdal_fetch_img_stats(path: String):
	path = ProjectSettings.globalize_path(path)
	return _gdal.fetch_img_stats(path)


func gdal_calc(pathin: String, pathout: String,  operation: String, debug:bool=false):
	_gdal.gdal_calc(pathin, pathout, operation, debug)


func gdal_execute(executable: String, args: Array, debug=false):
	_gdal.execute(executable, args, debug)


## * * * ImageMagick * * * *

func im_fetch_img_stats(path: String, extended_features: bool = false, debug:bool=false):
	path = ProjectSettings.globalize_path(path)
	return _img_magick.fetch_img_stats(path, extended_features, debug)


## Execute imagemagick from commandline with arbitrary arguments.
func img_magick_execute(args: Array, debug=false):
	return _img_magick.execute(args, debug)


func img_magick_convert_batch(paths : Array[String], destination: String, format: ImageMagick.ImgFormat, bits: int, debug: bool=false):
	for p in paths:
		await _img_magick.convert_image(p, destination, format, debug)


func img_magick_convert(path: String, destination: String, format: ImageMagick.ImgFormat, bits: int, debug: bool=false):
	await _img_magick.convert_image(path, destination, format, debug)
	
