extends Control

var gml_file_path : String
@onready var text_edit : TextEdit = %TextEdit

func get_stats():
	var result = KuikkaTerrainGen.terrain_parser._parse_gml(ProjectSettings.globalize_path(gml_file_path))
	
	#var d = []
	
	print_debug("Result ", result)
	
	for item in result.keys():
		#d.snapped("%s density: %d" % [item, result[item].density])
		print_debug("key ", item)
		text_edit.insert_text_at_caret("%s density: %d\n" % [item, result[item].density])
	
	# text_edit.insert_text_at_caret(JSON.stringify(result))
	

func _on_open_file_btn_pressed():
	%FileDialog.show()


func _on_file_dialog_file_selected(path):
	gml_file_path = path
	%FileNameLine.text = path
	get_stats()
