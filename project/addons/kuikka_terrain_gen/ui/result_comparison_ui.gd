extends HSplitContainer

var height_spec = preload("res://addons/kuikka_terrain_gen/ui/height_spec.tscn")

var input_profile : HeightProfile
var output_profile : HeightProfile
var id : String
var gen_time : Vector2 = Vector2(NAN, NAN)

var exports_path = "res://result_comparisons/"

@onready var _input = %Input
@onready var _output = %Output

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func set_images(inp: HeightProfile, outp: HeightProfile, new_id: String):
	input_profile = inp
	output_profile = outp
	id = new_id
	update_display()


func update_display():
	var ci = _input.get_node_or_null("HeightProfileSpec")
	if ci:
		_input.remove_child(ci)
	
	ci = height_spec.instantiate()
	_input.add_child(ci)

	var co = _output.get_node_or_null("HeightProfileSpec")
	if co:
		_output.remove_child(co)
		
	co = height_spec.instantiate()
	_output.add_child(co)
	
	ci.set_height_profile(input_profile)
	co.set_height_profile(output_profile)
	
	var t = get_node_or_null("../Time/TimeLabel")	
	if t and gen_time and gen_time.x != NAN and gen_time.y != NAN:
		t.text = str(gen_time.y-gen_time.x) + " ms"
	return

func _on_export_stats_threaded():
	WorkerThreadPool.add_task(_on_export_stats_pressed)


func _on_export_stats_pressed():
	print_debug("Export result comparison...")
	const KEYS_VALUES = ["min", "max", "mean", "median", "std_dev"]
	const KEYS_MEASURE = ["entropy", "kurtosis", "skewness"]
	var save_path = ProjectSettings.globalize_path(exports_path+id+".txt")
	#print_debug("Exporting result comparison for %s to <%s>" % [id, save_path])
	
	if not input_profile or not output_profile:
		printerr("Failed to export result comparison. Height profiles have not yet been calculated.")
		return
		
	var ri = input_profile.represent_range.y - input_profile.represent_range.x
	var mi = input_profile.represent_range.x
	var ro = output_profile.represent_range.y - output_profile.represent_range.x
	var mo = output_profile.represent_range.x
	
	var depth = input_profile.height_range.y - input_profile.height_range.x
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	
	if not file:
		printerr("Failed to open file %s for saving result comparison." % save_path)
		return
	
	file.store_string("Result comparison for generation %s \n\n" % id)
	file.store_string("-------------------------\n")
	file.store_string("%10-s|%10-s|%10-s|%10-s|%10-s\n" % ["Value", "Input", "Input Norm", "Output", "Output Norm"])
	for key in KEYS_VALUES:
		#var values = [key, mi+ri*input_profile[key], input_profile[key], 
		#				mo+ro*output_profile[key], output_profile[key]]
		var values= []
		if key == "std_dev":
			values = [key, ri*input_profile[key]/depth, input_profile[key]/depth, 
							ro*output_profile[key]/depth, output_profile[key]/depth]
		else:
			values = [key, mi+ri*input_profile[key]/depth, input_profile[key]/depth, 
							mo+ro*output_profile[key]/depth, output_profile[key]/depth]
		file.store_string("%10-s|%10f|(%10f)|%10f|(%10f)\n" % values) 
	
	for key in KEYS_MEASURE:
		var values = [key, input_profile[key], " ", 
						output_profile[key], " "]
		file.store_string(" %10-s|%10f|(%10-s)|%10f|(%10-s)\n" % values) 

	file.store_string("\n-------------------------\n")
	
	file.store_string("\nTotal generation time %d ms\n" % (gen_time.y-gen_time.x))
	
	file.store_string("\n  Representational range Input: %f - %f | Output: %f - %f" % [input_profile.represent_range.x, 
																			input_profile.represent_range.y, 
																			output_profile.represent_range.x, 
																			output_profile.represent_range.y])
	
	file.store_string("\n-------------------------\n")
	
	file.store_string("\nInput values")
	for key in KEYS_VALUES:
		#file.store_string("\n%f" % (mi+ri*input_profile[key]))
		if key == "std_dev":
			file.store_string("\n%f" % (ri*input_profile[key]/depth))
		else:
			file.store_string("\n%f" % (mi+ri*input_profile[key]/depth))
	for key in KEYS_MEASURE:
		file.store_string("\n%f" % input_profile[key])
		
	file.store_string("\nOutput values")
	for key in KEYS_VALUES:
		#file.store_string("\n%f" % (mo+ro*output_profile[key]))
		if key == "std_dev":
			file.store_string("\n%f" % (ro*output_profile[key]/depth))
		else:
			file.store_string("\n%f" % (mo+ro*output_profile[key]/depth))
	for key in KEYS_MEASURE:
		file.store_string("\n%f" % output_profile[key])
	
	file.close()
	#print_debug("Comparison exporting done.")
	return
