extends TextureRect

## Texture for displaying gene positions
signal texture_created(image)

var polygons : Array
var color : Color

var img : Image
var img_size:Vector2i=Vector2i(512, 512)


func _ready():
	#texture_created.connect(func(image): 
		#print_debug("Coastline texture set.")
		#img = image
		#texture = ImageTexture.create_from_image(image))
	pass


func draw_area(new_p: Array, new_color: Color, nsize:Vector2i=Vector2i(512, 512)):
	img_size = nsize
	polygons = new_p
	
	color = new_color
	#queue_redraw()
	
	print_debug("Creating coastline overlay texture.")
	#thread = Thread.new()
	#thread.start(create_texture)
	# WorkerThreadPool.add_task(create_texture)
	create_texture()

#func _draw():
	## for arr: Array in points:
	#for p: Array in polygons:
		#for i in p:
			#draw_circle(i, 1, color)


func create_texture():
	var image = Image.create(img_size.x, img_size.y, false, Image.FORMAT_RGBA8)
	
	for p: Array in polygons:
		for i in p:
			image.set_pixel(i.x, i.y, color)
		
		#await get_tree().create_timer(0.02).timeout
		
	_on_texture_finished(image) #_on_texture_finished.call_deferred(image)


func _on_texture_finished(image : Image):
	img = image
	texture = ImageTexture.create_from_image(img)
	
		
