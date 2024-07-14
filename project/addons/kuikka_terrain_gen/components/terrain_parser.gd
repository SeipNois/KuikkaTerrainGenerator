class_name TerrainParser extends Node

## Class for parsing data fetched from National Land Survey
## database into format to use for agent control and fitness evaluation.

## Feature image formed by extracting data from NSL database.
var _feature_image : TerrainFeatureImage

const HEIGHT_PROFILE_KEYS = ["min", "max", "mean", "median", "std_dev",
		"kurtosis", "skewness", "entropy"]

#const TERRAIN_FEATURE_KEYS = ["min", "max", "mean", "median", "std_dev",
		#"kurtosis", "skewness", "entropy"]

## Names of features from gml data to generate features for.
const FEATURE_NAMES = {
	"jyrkanne": {
		"feature": "Jyrkanne",
		"set": "jyrkanteet",
		"parser": LineParser
	},
	"niitty": {
		"feature": "Niitty",
		"set": "niityt",
		"parser": LinearRingParser
	},
	"soistuma": {
		"feature": "Soistuma",
		"set": "soistumat",
		"parser": LinearRingParser
	},
	"suo": {
		"feature": "Suo",
		"set": "suot",
		"parser": LinearRingParser
	},
	"jarvi": {
		"feature": "Jarvi",
		"set": "jarvet",
		"parser": LinearRingParser
	},
	"meri": {
		"feature": "Meri",
		"set": "meret",
		"parser": LinearRingParser
	},
	"korkeuskayra": {
		"feature": "Korkeuskayra",
		"set": "korkeuskayrat",
		"parser": LineParser
	},
	"kallioalue": {
		"feature": "KallioAlue",
		"set": "kallioAlueet",
		"parser": LinearRingParser
	}
}


## Create TerrainFeatureImage from collection of heightmaps and GML data.
func parse_data(hmaps: Array, gml: Array, parameters: ImageGenParams):
	_feature_image = TerrainFeatureImage.new()
	
	parse_heightmap_data(hmaps)
	parse_gml_data(gml)
	
	_image_scale_size_values(_feature_image, parameters)
	
	return _feature_image

	
func _image_scale_size_values(image, parameters: ImageGenParams):
	for key in image.features:
		image.features[key] = _feature_scale_size_values(
										image.features[key], parameters)
										
		# Single GML density is for image of size 6000 pixels.
		image.features[key].density /= 10 # round(parameters.width / 600)
	

# Scale gml values by given factor
func _feature_scale_size_values(feature: TerrainFeature, parameters: ImageGenParams):
	var factor = 2
	feature.size_max /= factor
	feature.size_min /= factor
	feature.size_mean /= factor
	feature.size_median /= factor
	feature.size_std_dev /= factor
	return feature


## Create TerrainFeatureImage content from heightmaps.
func parse_heightmap_data(hmaps:Array):
	var results = []
	for hmap in hmaps:
		var result = await _parse_heightmap(hmap)
		results.append(result)
	
	var len = results.size()
	
	# If only one heightmap is used, use its result as profile.
	if results.size() == 1:
		## FIXME: How are values scaled when outside 8 bit 0-255 range???
		_feature_image.height_profile = results[0]
		#var h_stats = KuikkaImgUtil.gdal_fetch_img_stats(hmaps[0])
		_feature_image.height_profile.height_range = Vector2(0, 255)# Vector2(h_stats.min, h_stats.max)
		
	# Create resulting profile as mean of heightmaps
	else:
		var profile = HeightProfile.new()
		for key in HEIGHT_PROFILE_KEYS:
			var value = 0
			results.reduce(func(s, x): return s+x[key], value)
			profile.set(key, value/len)
			
		## TODO: Resolve with different range for different heightmap
		## FIXME: How are values scaled when outside 8 bit 0-255 range???
		## when using multiple maps.
		#var h_stats = KuikkaImgUtil.gdal_fetch_img_stats(hmaps[0])
		
		profile.height_range = Vector2(0, 255)# Vector2(h_stats.min, h_stats.max)
		_feature_image.height_profile = profile


## Create TerrainFeatureImage content from GML (XML) files.
func parse_gml_data(files:Array):
	var results = []
	for file in files:
		var result = _parse_gml(file)
		results.append(result)
	
	var len = results.size()
	
	# Parse results by feature from each gml and calculate average for
	# combined result.
	for key in FEATURE_NAMES:
		var items = results.map(func(item): return item[key] if item.has(key) else null)
		items = items.filter(func(x): return x != null)
		
		var feature = TerrainFeature.new()
		# print_debug(key, " ", feature.get_properties())
		for item in items:
			feature = item.sum(feature)
			print_debug(key, " ", feature.get_properties())
			# print_debug("D ", feature.density)
			
		feature.divide_by(len)
		feature.feature_name = key
		_feature_image.features[key] = feature
		
		# print_debug(_feature_image.features.keys())


## Parse values from single heightmap.
static func _parse_heightmap(path: String) -> HeightProfile:
	var parsed = await KuikkaImgUtil.img_get_stats(path)#, false, true)
	
	if parsed and parsed.size() > 0:
		
		# Heightmap fitness collection.
		var result = HeightProfile.new()
		
		for key in HEIGHT_PROFILE_KEYS:
			if parsed.has(key):
				result.set(key, parsed[key])
			else:
				printerr("Image statistics missing key '%s'" % key)
				result.set(key, NAN)
		return result
		
	printerr("Failed to fetch image statistics.")
	return null


## Parse values from GML file.
func _parse_gml(path: String) -> Dictionary:
	
	var gml_item : XMLDocument = XML.parse_file(path)
	var maasto : XMLNode = gml_item.root
	# print_debug(gml_item.root._node_props, " ", gml_item.root.KNOWN_PROPERTIES)
	
	var result = {}
	
	for key in FEATURE_NAMES:
		var item = FEATURE_NAMES[key]
		var node : XMLNode = maasto._get(item["set"])
		if node:
			result[key] = feature_from_gml(key, node) 
		else:
			printerr("Feature data not found in gml. Omitting key '%s'" % key)
	return result


## Generate [TerrainFeatureImage.TerrainFeature]
func feature_from_gml(key: String, gml: XMLNode):
	var feat = FEATURE_NAMES[key]
	var feature = TerrainFeature.new()
	feature.feature_name = feat["feature"]
	
	var result = []
	
	for c in gml.children:
		# Filter all feature nodes.
		if c.name == feat["feature"]:
			result.append(feat["parser"].parse(c))
	
	if result.size() == 0:
		push_error("Failed to parse GML file.")
		return null
	
	var sizes = result.map(func(x): return x[0])
	var heights = result.map(func(x): return x[1])
	
	if not sizes or not heights:
		push_error("Failed to parse GML file.")
		return null
	
	# Create feature as mean of feature definitions.
	
	feature.density = result.size()
	
	# Size mappings
	feature.size_min = sizes.min()
	feature.size_max = sizes.max()
	
	var sum = 0
	sum = sizes.reduce(func(s, x): return s + x, sum)
	feature.size_mean = sum / sizes.size()
	sizes.sort()
	if sizes.size() % 2 == 0:
		feature.size_median = sizes[sizes.size()/2]
	else:
		feature.size_median = sizes[floor(sizes.size()/2)+1]
	
	sum = 0
	sum = sizes.reduce(func(s, x): return s + (x-feature.size_mean)**2, sum)
	feature.size_std_dev = sqrt(sum / sizes.size())
	
	# Generation height mappings
	feature.gen_height_min = heights.min()
	feature.gen_height_max = heights.max()
	
	sum = 0
	sum = heights.reduce(func(s, x): return s + x, sum)
	feature.gen_height_mean = sum / heights.size()
	
	heights.sort()
	if heights.size() % 2 == 0:
		feature.gen_height_median = heights[heights.size()/2]
	else:
		feature.gen_height_median = heights[floor(heights.size()/2)+1]
	
	sum = 0
	sum = heights.reduce(func(s, x): return s + (x-feature.gen_height_mean)**2, sum)
	feature.gen_height_std_dev = sqrt(sum / heights.size())
	
	return feature



## Try to get xml nested children in chain with given name if
## parent node exists. Returns null if not found.
static func _xml_parse_nested_if(node: XMLNode, path: Array):
	var item : XMLNode = node
	for segment in path:
		if item:
			var parent = item
			item = item._get(segment)
			
			if not item:
				push_warning("XMLNode %s not found under %s" % [parent.name, segment])
			
	return item


## * * * * * * * * * * * * * * * * * * 
## Parsers for different GMLNode types.

class FeatureParser:
	static func parse(node: XMLNode) -> Array:
		printerr("FeatureParser.parse() should be implemented by inheriting class!")
		return []
	
	
class LinearRingParser extends FeatureParser:
	## Parse features represented as 
	## [code]
	## 	<sijainti>
	## 	  <Piste></Piste>
	##		<Alue>
	## 			<gml:exterior>
	## 			<gml:LinearRing>
	##				<gml:posList></gml:posList>
	##			</gml:LinearRing>
	## 			</gml:exterior>
	##		</Alue>
	## 	</sijainti>
	## [/code]
	static func parse(node: XMLNode) -> Array:
		var op_keys = ["sijainti", "Piste", "gml:pos"]
		var opoint = TerrainParser._xml_parse_nested_if(node, 
									op_keys)
		var content_keys = ["sijainti", "Alue", "gml:exterior", 
										"gml:LinearRing", "gml:posList"]
		var content_node = TerrainParser._xml_parse_nested_if(node, 
																content_keys)
		
		if not opoint or not content_node:
			var a = "/".join(op_keys) + " is null!" if not opoint else ""
			var b = "/".join(content_keys) + " is null!" if not content_node else ""
			printerr("Failed to parse XMLNode ", node.name, " ", node ,"%s %s" % [a, b])
			return [NAN, NAN]
		
		var dimensions = int(opoint.attributes["srsDimension"])
									
		var content = content_node.content.split(" ")
		
		var origin_arr = opoint.content.split(" ")
		var origin
		
		var pts = []
		var radiuses = []
		var heights = []
		
		if dimensions == 3:
			origin = Vector3(float(origin_arr[0]), float(origin_arr[2]), float(origin_arr[1]))
		elif dimensions == 2:
			origin = Vector2(float(origin_arr[0]), float(origin_arr[1]))
		
		# Expect posList to contain points in touplets of size srsDimension
		for i in range(dimensions-1, content.size(), dimensions):
			if dimensions == 3:
				# (E,N,H) Long Lat Up -> (X,Y,Z) Long, Up, Lat
				# Coordinates: Convert from XY, Z-UP, to Godot coordinates Y -UP 
				var point = Vector3(float(content[i-2]),
									float(content[i]),
									float(content[i-1]))
				pts.append(point)
				radiuses.append(point.distance_to(origin))
				heights.append(float(content[i]))
			# TODO: 2-dimensional would be planar coordinates? 
			# (Not present in NSL data)
			elif dimensions == 2:
				var point = Vector2(float(content[i-1]),
									float(content[i]))
				pts.append(point)
				radiuses.append(point.distance_to(origin))
		
		var size = 0
		var gen_height = 0
		
		size = radiuses.reduce(func(size, x): return size + x, size)
		size /= radiuses.size()
		
		gen_height = heights.reduce(func(gen_height, x): return gen_height + x, gen_height)
		gen_height /= heights.size()
		
		# Return array with feature size and generation height.
		return [size, gen_height]


class LineParser extends FeatureParser:
	## Parse features represented as 
	## [code]
	## 	<sijainti>
	## 		<Murtoviiva>
	## 		</Murtoviiva>	
	## 	</sijainti>
	##		
	## [/code]
	static func parse(node: XMLNode) -> Array:
		var line_pos_list = TerrainParser._xml_parse_nested_if(node, 
									["sijainti", "Murtoviiva", "gml:posList"])
		
		if not line_pos_list:
			var a = "Murtoviiva/gml:posList is null!" if not line_pos_list else ""
			printerr("Failed to parse XMLNode ", node.name, " ", node, "%s" % a)
			return [NAN, NAN]
		
		var dimensions = int(line_pos_list.attributes["srsDimension"]) if line_pos_list else 3
		var content_node = line_pos_list
		var content = content_node.content.split(" ")
		
		var points = []
		
		for i in range(dimensions-1, content.size(), dimensions):
			if dimensions == 3:
				# (E,N,H) Long Lat Up -> (X,Y,Z) Long, Up, Lat
				# Coordinates: Convert from XY, Z-UP, to Godot coordinates Y -UP 
				# TODO: Korkeuskäyrä doesn't seem to follow this coordinate system?
				var p = Vector3(float(content[i-2]), float(content[i]), float(content[i-1]))
				points.append(p)
			# TODO: 2-dimensional would be planar coordinates? 
			# (Not present in NSL data)
			elif dimensions == 2:
				var p = Vector2(float(content[i-1]), float(content[i]))
				points.append(p)
		
		var pos = points[0]
		# Size as summed segment length of line a->b->...->c
		var size = 0
		for i in points.size()-2:
			size += points[i].distance_to(points[i+1])
		
		var height = 0
		height = points.reduce(func(h, p): return h + p.y, height)
		height /= points.size()
		
		return [size, height]
