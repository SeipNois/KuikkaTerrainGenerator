extends VBoxContainer

var area
var area_name : String

func set_area(new_area, new_name: String):
	area = new_area
	area_name = new_name
	update_display()


func update_display():
	for c in get_children():
		remove_child(c)
		c.queue_free()
	
	create_label(area_name)
	for item in area:
		var content = item + ": " + JSON.stringify(area[item])
		create_label(content)
	
func create_label(content):
	var label = Label.new()
	label.custom_minimum_size = Vector2(400, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(label)
	label.text = str(content)
