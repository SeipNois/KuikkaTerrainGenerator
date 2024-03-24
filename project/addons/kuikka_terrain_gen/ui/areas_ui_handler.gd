extends Control

var DisplayRect = preload("res://addons/kuikka_terrain_gen/ui/area_overlay_texture.gd")

var areas : Dictionary
var colors : Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]

## [Control] node holding drawn textures.
@onready var holder = $Textures
@onready var labels = $VBoxContainer


func draw_areas(new_areas: Dictionary):
	areas = new_areas
	
	holder.custom_minimum_size = custom_minimum_size
	labels.custom_minimum_size = custom_minimum_size
	
	# TODO: Make faster by not deleting each texture every time and
	# link to specific agents instead.
	for c in holder.get_children():
		holder.remove_child(c)
		c.queue_free()
	
	for l in labels.get_children():
		labels.remove_child(l)
		l.queue_free()
	
	# Color index
	var color_i = 0
	
	for area in areas:
		print_debug(area)
		# Set drawn texture
		var display = DisplayRect.new()
		holder.add_child(display)
		display.draw_area(areas[area], colors[color_i])
		
		# Set label
		var l = Label.new()
		labels.add_child(l)
		l.text = area
		l.set("theme_override_colors/font_color", colors[color_i])
		
		
		color_i += 1
		color_i = clamp(color_i, 0, colors.size())
