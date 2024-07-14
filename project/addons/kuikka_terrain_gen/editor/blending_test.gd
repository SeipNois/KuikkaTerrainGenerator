extends Control

## Test scene for different image blending options

enum BlendType {MULTIPLY, SUM, LAPLACE, DIFFERENCE, POISSON, MEAN_DIFF, DIFF_MULT}

var image : Image
var image_path : String
var blend_mask : Image
var blend_mask_path : String
var blend_position : Vector2i = Vector2i.ZERO
var rect : Rect2i

var result_img : Image

var current_blend : BlendType = 0

@onready var _loaded_img_rect : TextureRect = %LoadedImage
@onready var _loaded_mask_rect : TextureRect = %LoadedMask
@onready var _result : TextureRect = %ResultImage


func blend_image():
	# Create result image.
	result_img = Image.create(400, 400, false, Image.FORMAT_RGBA8)
	result_img.fill(Color.DARK_GRAY)
	
	blend_position = clamp(blend_position, Vector2i.ZERO, 
							Vector2i(result_img.get_width()-image.get_width(), 
									result_img.get_height()-image.get_height()))
	image.convert(result_img.get_format())
	blend_mask.convert(result_img.get_format())
	blend_mask.resize(image.get_width(), image.get_height())
	
	# Blend
	match current_blend:
		BlendType.MULTIPLY:
			var item = KuikkaImgUtil.images_blend_alpha(image, blend_mask)
			result_img.blend_rect(item, item.get_used_rect(), blend_position)
		BlendType.SUM:
			result_img = KuikkaImgUtil.blend_rect_sum_mask(result_img, image, blend_mask, rect, blend_position, "r")
		BlendType.LAPLACE:
			pass
		BlendType.DIFFERENCE: 
			var mean = await KuikkaImgUtil.im_fetch_img_stats(image_path).mean
			result_img = KuikkaImgUtil.blend_rect_diff_mask(result_img, image, blend_mask, rect, blend_position, mean, "r")
		BlendType.POISSON:
			var mean = await KuikkaImgUtil.im_fetch_img_stats(image_path).mean
			result_img = KuikkaImgUtil.blend_poisson_mask(result_img, image, blend_mask, rect, blend_position, mean, "r")
		BlendType.MEAN_DIFF:
			var mean = await KuikkaImgUtil.im_fetch_img_stats(image_path).mean
			result_img = KuikkaImgUtil.blend_mean_diff_mask(result_img, image, blend_mask, rect, blend_position, mean, "r")
		BlendType.DIFF_MULT:
			var mean = await KuikkaImgUtil.im_fetch_img_stats(image_path).mean
			result_img = KuikkaImgUtil.blend_diff_mult_mask(result_img, image, blend_mask, rect, blend_position, mean, "r")
		_:
			printerr("Blend mode didn't match any possible blend mode.")
	
	# Display result
	_result.texture = ImageTexture.create_from_image(result_img)


# * * * * * * * *
# Open files
func _on_open_file_button_pressed():
	%OpenImageFileDialog.show()

func _on_open_file_mask_button_pressed():
	%OpenImageMaskFileDialog.show()

func _on_open_image_file_dialog_file_selected(path):
	image = Image.load_from_file(ProjectSettings.globalize_path(path))
	image_path = path
	_loaded_img_rect.texture = ImageTexture.create_from_image(image)

func _on_open_image_mask_file_dialog_file_selected(path):
	blend_mask = Image.load_from_file(ProjectSettings.globalize_path(path))
	blend_mask_path = path
	_loaded_mask_rect.texture = ImageTexture.create_from_image(blend_mask)
# ---------------


# * * * * * * * *
# Blend position
func _on_spin_box_x_value_changed(value):
	blend_position.x = value

func _on_spin_box_y_value_changed(value):
	blend_position.y = value
# ---------------


# * * * * * * * *
# Process
func _on_process_button_pressed():
	blend_image()

# * * * * * * * *
# Blend type
func _on_option_button_item_selected(index):
	current_blend = index
# ---------------


# * * * * * * * *
# Blend rect
func _on_spin_box_rx_value_changed(value):
	rect.position.x = value

func _on_spin_box_ry_value_changed(value):
	rect.position.y = value

func _on_spin_box_rw_value_changed(value):
	rect.size.x = value

func _on_spin_box_rh_value_changed(value):
	rect.size.y = value
# ---------------
