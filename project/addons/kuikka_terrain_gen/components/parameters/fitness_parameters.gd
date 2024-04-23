class_name FitnessParameters extends Resource

## Parameter resource representing agent / region specific reference values
## for fitness of height sample gene in evolution process.

## Minimum terrain height in height sample.
## Range: 0.0 -- 1.0 (< max_height)
@export var min_height : float

## Maximum terrain height in height sample.
## Range: 0.0 -- 1.0 (> min_height)
@export var max_height : float
		
## Mean terrain height in height sample.
## Range: min_height -- max_height
@export var mean : float
		
## Variance of terrain height in height sample.
@export var variance : float

## Hill frequency / "hillyness" of terrain. Determined by comparing
## value to image FFT results.
@export_range(0, 100) var hill_frequency : float


## Get sum of parameter difference compared to another [FitnessParameters].
## Returns positive [float] that represents total difference amongst values.
func difference(ref: FitnessParameters) -> float:
	var sum = 0
	sum += abs(min_height - ref.min_height)
	sum += abs(max_height - ref.max_height)
	sum += abs(mean - ref.mean)
	sum += abs(variance - ref.variance)
	# sum += abs(hill_frequency - ref.hill_frequency)
	return sum
