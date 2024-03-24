extends TextureRect

var area : Array
var color : Color


func draw_area(new_area: Array, new_color: Color):
	area = new_area
	color = new_color
	queue_redraw()


func _draw():
	for curve : Curve2D in area:
		var start = curve.get_point_position(0)
		draw_circle(start, 2, color)
		
		if curve.point_count > 1:
			for i in range(1, curve.point_count-1):
				draw_circle(start, 2, color)
				draw_line(start, 
					curve.get_point_position(i), color, 5)
				
				start = curve.get_point_position(i)
