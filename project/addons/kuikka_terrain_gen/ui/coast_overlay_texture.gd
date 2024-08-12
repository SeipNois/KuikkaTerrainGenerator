extends TextureRect

## Texture for displaying gene positions

var polygons : Array
var color : Color


func draw_area(new_p: Array, new_color: Color):
	polygons = new_p
	
	color = new_color
	queue_redraw()


func _draw():
	# for arr: Array in points:
	for p: Array in polygons:
		for i in p:
			draw_circle(i, 1, color)
