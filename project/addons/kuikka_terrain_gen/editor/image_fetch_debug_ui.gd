extends Control

var convert_source_path = "res://addons/kuikka_terrain_gen/height_samples/SAMPLES_GEOTIFF"
var convert_source # = DirAccess.get_files_at(convert_source_path)
var convert_destination : String = "res://addons/kuikka_terrain_gen/height_samples/SAMPLES_PNG"
var conversion_format : int = 0

@onready var convert_image_btn = %ConvertImagesButton
@onready var format_select = %ImageFormatOption

# Called when the node enters the scene tree for the first time.
func _ready():
	
	for item in GDALUtils.ImgFormat.keys():
		format_select.add_item(item)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _can_convert() -> bool:
	if not convert_destination:
		printerr("Cannot convert. Please select destination for conversion.")
		return false
	if not convert_source or convert_source.is_empty():
		printerr("Cannot convert. Please select files to convert.")
		return false
		
	return true


func _on_convert_images_button_pressed():
	if not _can_convert():
		return
	
	convert_image_btn.disabled = true
	
	GDALUtils.gdal_translate_batch(convert_source, convert_destination, conversion_format)
	
	convert_image_btn.disabled = false


# Select images to convert.
func _on_file_dialog_source_files_selected(paths):
	convert_source = paths
	$CenterContainer/VBoxContainer/Sources.text = "\n".join(paths)

# Select destination directory.
func _on_file_dialog_destination_dir_selected(dir):
	convert_destination = dir
	$CenterContainer/VBoxContainer/Destination.text = dir


# Select image destination format.
func _on_image_format_option_item_selected(index):
	conversion_format = index


func _on_calculate_images_fft_pressed():
	for path in DirAccess.get_files_at(convert_destination):
		var file = FilePath.join([convert_destination, path])
		var img = Image.load_from_file(file)
		# print(KuikkaUtils.fft2d(img))

		# var result = KuikkaUtils.visualize_fft2(img)
		var result = img
		
		$CenterContainer/HBoxContainer/VBoxContainer2/TextureRect.texture = ImageTexture.create_from_image(result)
		# DEBUG: End after one
		return
