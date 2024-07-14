## Height feature profile to save heightmap data.
class_name HeightProfile extends Resource

@export var min : float
@export var max : float
@export var mean : float
@export var median : float
@export var std_dev : float
@export var kurtosis : float
# g > 0 "leaning" to left, g < 0 "leaning" to right
@export var skewness : float
@export var entropy : float
@export var contrast : float
@export var correlation : float
@export var height_range : Vector2

## Calculate comparison value for reference HeightProfile, based on
## how much values for each differ from each other.
func compare(ref: HeightProfile):
	return abs(min-ref.min) + abs(max-ref.max) + abs(mean-ref.mean) +\
	abs(median-ref.median)+abs(std_dev-ref.std_dev)\
	# Additional values
	+abs(skewness-ref.skewness)+abs(entropy-ref.entropy)+abs(kurtosis-ref.kurtosis)


## Compare towards terrain feature generation values.
func compare_tf(ref: TerrainFeature):
	return abs(min-ref.gen_height_min) + abs(max-ref.gen_height_max) + abs(mean-ref.gen_height_mean) +\
	abs(median-ref.gen_height_median)+abs(std_dev-ref.gen_height_std_dev)


## Check if all comparison values are valid
func is_valid() -> bool:
	return min and min != NAN and max and max != NAN and mean and mean != NAN\
			and median and median != NAN and std_dev and std_dev != NAN \
			and kurtosis and kurtosis != NAN and skewness and skewness != NAN \
			and entropy and entropy != NAN
