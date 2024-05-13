class_name TerrainParser extends Node

## Class for parsing data fetched from National Land Survey
## database into format to use for agent control and fitness evaluation.

## Feature image formed by extracting data from NSL database.
var _feature_image : TerrainFeatureImage

const HEIGHT_PROFILE_KEYS = ["min", "max", "mean", "median", "std_dev",
		"kurtosis", "skewness", "entropy"]

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
		"feature": "jarvet",
		"set": "suot",
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
		"parser": LinearRingParser
	},
	"kallioalue": {
		"feature": "kallioAlue",
		"set": "kallioAlueet",
		"parser": LinearRingParser
	}
}


## Create TerrainFeatureImage from collection of heightmaps and GML data.
func parse_data(hmaps: Array, gml: Array):
	_feature_image = TerrainFeatureImage.new()
	
	parse_heightmap_data(hmaps)
	parse_gml_data(gml)
	
	normalize_image()
	
	return _feature_image


## Normalize TerrainFeatureImage values to range 
func normalize_image():
	pass	


## Create TerrainFeatureImage content from heightmaps.
func parse_heightmap_data(hmaps:Array):
	var results = []
	for hmap in hmaps:
		var result = await _parse_heightmap(hmap)
		results.append(result)
	
	var len = results.size()
	
	# If only one heightmap is used, use its result as profile.
	if results.size() == 1:
		_feature_image.height_profile = results[0]
	# Create resulting profile as mean of heightmaps
	else:
		var profile = TerrainFeatureImage.HeightProfile.new()
		for key in HEIGHT_PROFILE_KEYS:
			var value = 0
			results.reduce(func(s, x): return s+x, value)
			profile.set(key, value/len)
			
		profile.height_range = profile.max - profile.min
		_feature_image.height_profile = profile


## Create TerrainFeatureImage content from GML (XML) files.
func parse_gml_data(files:Array):
	var results = []
	for file in files:
		var result = _parse_gml(file)
		results.append(result)


## Parse values from single heightmap.
func _parse_heightmap(path: String):
	var parsed = await KuikkaImgUtil.img_get_stats(path)
	
	if parsed and parsed.size() > 0:
		
		# Heightmap fitness collection.
		var result = TerrainFeatureImage.HeightProfile.new()
		
		for key in HEIGHT_PROFILE_KEYS:
			if parsed.has(key):
				result.set(key, parsed[key])
			else:
				printerr("Image statistics missing key '%s'" % key)
		
		print_debug("Resulting terrain feature image ", result)
		
		return result
		
	printerr("Failed to fetch image statistics.")
	return null


## Parse values from GML file.
func _parse_gml(path: String):
	
	# FIXME: glm_item.root is parsed correctly and has name "Maastotiedot"
	# but _get("item-name") doesn't return wanted result. consider using
	# custom recursive search??
	var gml_item : XMLDocument = XML.parse_file(path)
	var maasto : XMLNode = gml_item.root
	# print_debug(gml_item.root._node_props, " ", gml_item.root.KNOWN_PROPERTIES)
	
	for key in FEATURE_NAMES:
		var item = FEATURE_NAMES[key]
		var node : XMLNode = maasto._get(item["set"])
		if node:
			_feature_image.features[key] = feature_from_gml(key, node) 
		else:
			printerr("Feature data not found in gml. Omitting key '%s'" % key)


## Generate [TerrainFeatureImage.TerrainFeature]
func feature_from_gml(key: String, gml: XMLNode):
	var feat = FEATURE_NAMES[key]
	var feature = TerrainFeatureImage.TerrainFeature.new()
	feature.feature_name = feat["feature"]
	
	var result = []
	
	for c in gml.children:
		# Filter all feature nodes.
		if c.name == feat["feature"]:
			result.append(feat["parser"].parse(c))
	
	var sizes = result.map(func(x): return x[0])
	var heights = result.map(func(x): return x[1])
	
	# Create feature as mean of feature definitions.
	
	# Size mappings
	feature.size_min = sizes.min()
	feature.size_max = sizes.max()
	
	var sum = 0
	sizes.reduce(func(s, x): return s + x, sum)
	feature.size_mean = sum / sizes.size()
	sizes.sort()
	if sizes.size() % 2 == 0:
		feature.size_median = sizes[sizes.size()/2]
	else:
		feature.size_median = sizes[floor(sizes.size()/2)+1]
	
	sum = 0
	sizes.reduce(func(s, x): return s + (x-feature.size_mean)**2, sum)
	feature.size_std_dev = sum / sizes.size()
	
	# Generation height mappings
	feature.gen_height_min = heights.min()
	feature.gen_height_max = heights.max()
	
	sum = 0
	heights.reduce(func(s, x): return s + x, sum)
	feature.gen_height_mean = sum / heights.size()
	
	heights.sort()
	if heights.size() % 2 == 0:
		feature.gen_height_median = heights[heights.size()/2]
	else:
		feature.gen_height_median = heights[floor(heights.size()/2)+1]
	
	sum = 0
	heights.reduce(func(s, x): return s + (x-feature.gen_height_mean)**2, sum)
	feature.gen_height_std_dev = sum / heights.size()
	
	return feature


## Try to get xml nested children in chain with given name if
## parent node exists. Returns null if not found.
static func _xml_parse_nested_if(node: XMLNode, path: Array):
	var item : XMLNode = node
	for segment in path:
		if item:
			item = item._get(segment)
	
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
	##			</gml:LinearRin g>
	## 			</gml:exterior>
	##		</Alue>
	## 	</sijainti>
	## [/code]
	static func parse(node: XMLNode) -> Array:
		var opoint = TerrainParser._xml_parse_nested_if(node, 
									["sijainti", "Piste", "gml:pos"])
		var content_node = TerrainParser._xml_parse_nested_if(node, 
									["sijainti", "Alue", "gml:exterior", 
										"gml:linearRing", "gml:posList"])
		
		if not opoint or not content_node:
			var a = "Piste/gml:pos is null!" if not opoint else ""
			var b = "Alue/gml:posList is null!" if not content_node else ""
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
			origin = Vector3(origin_arr[0], origin_arr[1], origin_arr[2])
		elif dimensions == 2:
			origin = Vector2(origin_arr[0], origin_arr[1])
		
		# Expect posList to contain points in touplets of size srsDimension
		for i in range(dimensions-1, content.size(), dimensions):
			if dimensions == 3:
				var point = Vector3(float(content[i-2]),
									float(content[i-1]),
									float(content[i]))
				pts.append(point)
				radiuses.append(point.distance_to(origin))
				heights.append(float(content[i-1]))
			elif dimensions == 2:
				var point = Vector2(float(content[i-1]),
									float(content[i]))
				pts.append(point)
				radiuses.append(point.distance_to(origin))
		
		var size = 0
		var gen_height = 0
		
		radiuses.reduce(func(size, x): return size + x, size)
		size /= radiuses.size()
		
		heights.reduce(func(gen_height, x): return gen_height + x, gen_height)
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
				var p = Vector3(float(content[i-2]), float(content[i-1]), float(content[i]))
				points.append(p)
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
