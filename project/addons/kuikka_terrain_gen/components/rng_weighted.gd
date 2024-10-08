class_name WeightedRNG extends RandomNumberGenerator

## Random number generator with weighted generation with distribution.

func randi_range_weighted(min, max, mean, std_dev):
	var value = randi_normal_dist(mean, std_dev)
	while value < min or value > max:
		value = randi_normal_dist(mean, std_dev)
	
	return value
	

## Create values based on normal distribution with 
## known mean and standard deviation.
func randi_normal_dist(mean, std_dev):
	return round(randf_normal_dist(mean, std_dev))


func randf_normal_dist(mean, std_dev):
	return randf_range(-1, 1) * std_dev + mean
