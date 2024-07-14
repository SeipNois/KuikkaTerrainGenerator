extends MarginContainer

var profile : HeightProfile

func set_height_profile(new_profile : HeightProfile):
	profile = new_profile
	update_display()


func update_display():
	var range = profile.height_range.y - profile.height_range.x
	var m = profile.height_range.x
	update_element(%HeightMin, "%f, (%f)" % [m+profile.min*range, profile.min])
	update_element(%HeightMax, "%f, (%f)" % [m+profile.max*range, profile.max])
	update_element(%HeightMean, "%f, (%f)" % [m+profile.mean*range, profile.mean])
	update_element(%HeightMedian, "%f, (%f)" % [m+profile.median*range, profile.median])
	update_element(%HeightDeviation, "±%f, (±%f)" % [profile.std_dev*range, profile.std_dev])
	update_element(%HeightEntropy, "%f" % [profile.entropy])
	update_element(%HeightSkewness, "%f" % [profile.skewness])
	update_element(%HeightKurtosis, "%f" % [profile.kurtosis])
	# update_element(%HeightRange, "[%f , %f]" % [profile.height_range.x, profile.height_range.y])
	
	

func update_element(element: Node, content):
	element.get_node("Label2").text = str(content)
