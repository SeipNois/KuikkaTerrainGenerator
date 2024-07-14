class_name GeneticOperation extends Node

## GeneticOperation represents single genetic operation to be
## applied to given height sample [Image] by running apply_operation.

## Strength of applied operation as percents
@export_range(0.0, 1.0) var strength : float

## Applies genetic operation to [param sample] and returns the
## resulting [Image]
func apply_operation(sample : Image) -> Image:
	# print_debug("Genetic operation on sample ", sample)
	return sample


## Applies genetic operation to image at [param path] using
## imagemagick command line tools.
func apply_operation_path(path : String) -> Image:
	var img : Image = await Image.load_from_file(path)
	img = apply_operation(img)
	img.save_png(path)
	return img
