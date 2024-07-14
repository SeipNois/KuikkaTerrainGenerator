extends VBoxContainer

## UI Element to display dictionaries as text.

var area_item = preload("res://addons/kuikka_terrain_gen/ui/agent_area_spec.tscn")
var areas : Dictionary


func set_areas(new_areas : Dictionary):
	areas = new_areas
	update_display()


func update_display():
	for c in get_children():
		remove_child(c)
		c.queue_free()
	
	for area in areas:
		var item = area_item.instantiate()
		add_child(item)
		item.set_area(areas[area], area)
