extends MarginContainer

## UI Element to display values extracted from terrain.

var feature : TerrainFeature


func set_feature(feat: TerrainFeature):
	feature = feat
	update_display()
	

func update_display():
	%FeatureName.text = feature.feature_name
	update_element(%Density, feature.density)
	update_element(%SizeMinValues, feature.size_min)
	update_element(%SizeMaxValues, feature.size_max)
	update_element(%SizeMeanValues, feature.size_mean)
	update_element(%SizeMedianValues, feature.size_median)
	update_element(%SizeDeviationValues, feature.size_std_dev)	
	
	update_element(%HeightMinValues, feature.gen_height_min)
	update_element(%HeightMaxValues, feature.gen_height_max)
	update_element(%HeightMeanValues, feature.gen_height_mean)
	update_element(%HeightMedianValues, feature.gen_height_median)
	update_element(%HeightDeviationValues, feature.gen_height_std_dev)	


func update_element(element: Node, content):
	element.get_node("Label2").text = str(content)
