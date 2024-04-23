extends Control

var DisplayRect = preload("res://addons/kuikka_terrain_gen/ui/area_overlay_texture.gd")
var GeneDisplayRect = preload("res://addons/kuikka_terrain_gen/ui/genes_overlay_texture.gd")

var areas : Dictionary

var colors : Array[Color] = [Color.RED, Color.GREEN, Color.BLUE]

var gene_colors : Array[Color] = [Color.MAROON, Color.DARK_SEA_GREEN, Color.CADET_BLUE]

## [Control] node holding drawn textures.
@onready var holder = $Textures
@onready var labels = $VBoxContainer


func _ready():
	# Make gene point colors transparent
	for c in gene_colors.size():
		gene_colors[c].a = 0.95


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
	var gene_labels = []
	
	for area in areas:
		print_debug(area)
		# Set drawn texture
		var display = DisplayRect.new()
		holder.add_child(display)
		
		# Draw curve paths
		display.draw_area(areas[area]["agent_travel"], colors[color_i])
		
		# TODO: Draw covered points delaunay
		
		# Set label
		var l = Label.new()
		labels.add_child(l)
		l.text = area
		l.set("theme_override_colors/font_color", colors[color_i])
		
		
		color_i += 1
		color_i = clamp(color_i, 0, colors.size())
		
		# Add gene display
		
		
		# Set label
		var gl = Label.new()
		gl.text = area + " genes"
		gl.set("theme_override_colors/font_color", gene_colors[color_i])
		gene_labels.append(gl)
		
		var gdisplay = GeneDisplayRect.new()
		holder.add_child(gdisplay)
		
		gdisplay.draw_area(areas[area]["gene_points"], gene_colors[color_i])

	# Add gene labels after list separator
	# labels.add_child(HSeparator.new())
	
	for gl in gene_labels:
		labels.add_child(gl)
		
