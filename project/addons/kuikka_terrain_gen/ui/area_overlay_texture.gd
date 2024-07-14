extends TextureRect

var area : Array
var color : Color


func draw_area(new_area: Array, new_color: Color):
	area = new_area
	color = new_color
	queue_redraw()


func _draw():
	# Draw curve
	for curve in area:
		if curve is Curve2D:
			var start = curve.get_point_position(0)
			# draw_circle(start, 3, color)
			
			if curve.point_count > 1:
				for i in range(1, curve.point_count-1):
					draw_circle(start, 3, color)
					draw_line(start, curve.get_point_position(i), color, 1)
					
					start = curve.get_point_position(i)
			draw_circle(start, 3, color)
		
		
		# Draw single points 
		elif curve is Vector2i:
			draw_circle(curve, 3, color)
