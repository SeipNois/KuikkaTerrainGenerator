class_name HeightSampleDB extends Resource

## Array of paths to heightsamples to use to generate samples Dictionary.
@export var unsorted_samples : Array = []

## Database of samples as { [String agent_name] : [Array](image_sample_paths) }
@export var samples : Dictionary = {}


## Get samples for given agent.
func get_samples(area: String):
	if area in samples:
		return samples[area]
	else:
		return []


## Set samples for given agent.
func set_samples(area: String, new_samples: Array):
	samples[area] = new_samples


## Add new sample to pool of given agent.
func append_sample(area: String, sample_path: String):
	if area in samples:
		samples[area].append(sample_path)
	else:
		samples[area] = [sample_path]
