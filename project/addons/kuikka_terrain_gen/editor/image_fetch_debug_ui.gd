extends Control

var convert_source_path = "res://addons/kuikka_terrain_gen/height_samples/SAMPLES_GEOTIFF"
var convert_source # = DirAccess.get_files_at(convert_source_path)
var convert_destination : String = "res://addons/kuikka_terrain_gen/height_samples/SAMPLES_PNG"
var conversion_format : int = 0
var bits : int = 0

@onready var convert_image_btn = %ConvertImagesButton
@onready var format_select = %ImageFormatOption

@onready var magick_format_select = %ImageMagickFormatOption


# Called when the node enters the scene tree for the first time.
func _ready():
	
	for item in GdalUtils.ImgFormat.keys():
		format_select.add_item(item)
	
	for item in GdalUtils.ColorFormat.keys():
		%SpinBoxColor.add_item(item)

	for item in ImageMagick.ImgFormat.keys():
		magick_format_select.add_item(item)


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
	
	KuikkaImgUtil.gdal_translate_batch(convert_source, convert_destination, conversion_format, bits, true)
	
	convert_image_btn.disabled = false


# Select images to convert.
func _on_file_dialog_source_files_selected(paths):
	convert_source = paths
	%Sources.text = "\n".join(paths)

# Select destination directory.
func _on_file_dialog_destination_dir_selected(dir):
	convert_destination = dir
	%Destination.text = dir


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


## ImageMagick format conversion

var magick_format = 0
var magick_bits : int = 8

func _on_convert_formats_pressed():
	KuikkaImgUtil.img_magick_convert_batch(convert_source, convert_destination, magick_format, magick_bits)


func _on_image_magick_format_option_item_selected(index):
	magick_format = index


func _on_spin_box_color_item_selected(index):
	bits = index


func _on_spin_box_magick_color_item_selected(index):
	magick_bits = index
