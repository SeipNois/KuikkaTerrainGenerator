extends Control


@export var labels : Control

var DisplayRect = preload("res://addons/kuikka_terrain_gen/ui/area_overlay_texture.gd")
var GeneDisplayRect = preload("res://addons/kuikka_terrain_gen/ui/genes_overlay_texture.gd")
var CoastDisplayRect = preload("res://addons/kuikka_terrain_gen/ui/coast_overlay_texture.gd")

var areas : Dictionary

var colors : Array[Color] = [Color.GREEN, Color.RED, Color.BLUE, Color.GOLDENROD]
var coast_line_color = Color.LIGHT_SEA_GREEN

var gene_colors : Array[Color] = [Color.MAROON, Color.DARK_SEA_GREEN, Color.CADET_BLUE, Color.YELLOW, ]

## [Control] node holding drawn textures.
@onready var holder = $Textures


func _ready():
	# Make gene point colors transparent
	for c in colors.size():
		colors[c].a = 0.9
	for c in gene_colors.size():
		gene_colors[c].a = 0.6
	
	coast_line_color.a = 0.8
	if not labels:
		labels = $VBoxContainer

func draw_areas(new_areas: Dictionary):
	areas = new_areas
	# FIXME: Remove to enable
	return
	
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
		# if areas[area]["agent_travel"].size() > 0:
		display.draw_area(areas[area]["agent_travel"], colors[color_i])
		# else:
		#	display.draw_area(areas[area]["covered_points"], colors[color_i])
		
		## Add coast line for lakes
		if areas[area].has("coast_line"):
			var coast = CoastDisplayRect.new()
			holder.add_child(coast)
			coast.draw_area(areas[area]["coast_line"], coast_line_color)
			
			var l = Label.new()
			labels.add_child(l)
			l.text = "Coastline"
			l.set("theme_override_colors/font_color", coast_line_color)
			
			var coast_toggle = CheckButton.new()
			coast_toggle.toggled.connect(func(toggled): coast.visible = toggled)
			labels.add_child(coast_toggle)
			coast_toggle.toggle_mode = true
			coast_toggle.button_pressed = true
		
		display.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# TODO: Draw covered points delaunay
		
		# Set label
		var l = Label.new()
		labels.add_child(l)
		l.text = area
		l.set("theme_override_colors/font_color", colors[color_i])
		
		# Add toggle 
		var btn = CheckButton.new()
		btn.toggled.connect(func(toggled): display.visible = toggled)
		labels.add_child(btn)
		btn.toggle_mode = true
		btn.button_pressed = true
		
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
		gdisplay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Add toggle 
		var gbtn = CheckButton.new()
		gbtn.toggled.connect(func(toggled): gdisplay.visible = toggled)
		gene_labels.append(gbtn)
		gbtn.toggle_mode = true
		gbtn.button_pressed = true

	# Add gene labels after list separator
	# labels.add_child(HSeparator.new())
	
	for gl in gene_labels:
		labels.add_child(gl)
		
