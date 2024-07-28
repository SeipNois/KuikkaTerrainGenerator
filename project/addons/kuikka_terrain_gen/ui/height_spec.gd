extends MarginContainer

var profile : HeightProfile

func set_height_profile(new_profile : HeightProfile):
	profile = new_profile
	update_display()


func update_display():
	var range = profile.represent_range.y - profile.represent_range.x
	var m = profile.represent_range.x
	var depth = profile.height_range.y - profile.height_range.x
	update_element(%HeightMin, "%f, (%f)" % [m+profile.min*range/depth, profile.min/depth])
	update_element(%HeightMax, "%f, (%f)" % [m+profile.max*range/depth, profile.max/depth])
	update_element(%HeightMean, "%f, (%f)" % [m+profile.mean*range/depth, profile.mean/depth])
	update_element(%HeightMedian, "%f, (%f)" % [m+profile.median*range/depth, profile.median/depth])
	update_element(%HeightDeviation, "±%f, (±%f)" % [profile.std_dev*range/depth, profile.std_dev/depth])
	update_element(%HeightEntropy, "%f" % [profile.entropy])
	update_element(%HeightSkewness, "%f" % [profile.skewness])
	update_element(%HeightKurtosis, "%f" % [profile.kurtosis])
	
	#update_element(%HeightMin, "%f, (%f)" % [profile.min, (profile.min-m)/range])
	#update_element(%HeightMax, "%f, (%f)" % [profile.max, (profile.max-m)/range])
	#update_element(%HeightMean, "%f, (%f)" % [profile.mean, (profile.mean-m)/range])
	#update_element(%HeightMedian, "%f, (%f)" % [profile.median, (profile.median-m)/range])
	#update_element(%HeightDeviation, "±%f, (±%f)" % [profile.std_dev, (profile.std_dev-m)/range])
	#update_element(%HeightEntropy, "%f" % [profile.entropy])
	#update_element(%HeightSkewness, "%f" % [profile.skewness])
	#update_element(%HeightKurtosis, "%f" % [profile.kurtosis])
	
	update_element(%HeightRange, "[%f , %f]" % [profile.height_range.x, profile.height_range.y])
	update_element(%HeightRepresentRange, "[%f , %f]" % [profile.represent_range.x, profile.represent_range.y])
	

func update_element(element: Node, content):
	element.get_node("Label2").text = str(content)
