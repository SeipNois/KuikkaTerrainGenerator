class_name GeneticOperationRotateCW extends GeneticOperation


## Applies genetic operation to [param sample] and returns the
## resulting [Image]
func apply_operation(sample : Image) -> Image:
	return sample


## Applies genetic operation to image at [param path] using
## imagemagick command line tools.
func apply_operation_path(path : String) -> Image:
	return null
