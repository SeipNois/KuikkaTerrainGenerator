extends Node3D

const PATH = "H://Tiedostot/Opiskelu/diplomityö/kuikka-project/mml_data/test_set/N4124C.png"
const EXPORT_PATH = "res://image_exports/N4124C.png"


# Called when the node enters the scene tree for the first time.
func _ready():
	var map = Image.load_from_file(PATH)
	
	# refmap.resize(1500, 1500)
	# Blend quantization and reload image
	KuikkaImgUtil.img_magick_execute(["convert", PATH, "-blur", "2x6", EXPORT_PATH])
	var refmap = Image.load_from_file(EXPORT_PATH)
	
	$Terrain3D.storage.import_images([map, null, null], Vector3(0, 0, 0), 0, 120)
	$Terrain3D2.storage.import_images([refmap, null, null], Vector3(3000, 0, 0), 0, 120)
	


func _input(event):
	if event.is_action_pressed("toggle_ui"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE else Input.MOUSE_MODE_VISIBLE  
