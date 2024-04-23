class_name GeneticOperation extends Resource

## GeneticOperation represents single genetic operation to be
## applied to given height sample [Image] by running apply_operation.

## Strength of applied operation as percents
@export_range(0.0, 1.0) var strength : float

## Applies genetic operation to [param sample] and returns the
## resulting [Image]
func apply_operation(sample : Image) -> Image:
	return sample
