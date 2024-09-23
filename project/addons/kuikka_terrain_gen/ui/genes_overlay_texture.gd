extends TextureRect

## Texture for displaying gene positions

var points : Array
var color : Color

var img : Image
var img_size:Vector2i=Vector2i(512, 512)


func draw_area(new_p: Array, new_color: Color):
	points = new_p
	color = new_color
	queue_redraw()


func _draw():
	# for arr: Array in points:
	for p: Vector2i in points:
		draw_circle(p, 3, color)
