class_name KuikkaTerrainAgent extends Node

## * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
## 	Base class for terrain agents that generate heightmap features.
## 	base class implements [method _generation_process] loop similar to
## 	Godot's [method Node._process] and [method Node._physics_process]. 
## 	[method _generation_process] acts as generation step for advancing agent
##	should be called by [TerrainServerGD] for each agent in its
## 	own [method Node._process] or [method Node._physics_process] loop.


## Method used to place genes in area silhouette.
enum GeneDistribute {DIRECT, LINEAR, RECT, DELAUNAY, CONCAVE}

signal generation_finished(agent: KuikkaTerrainAgent)
signal generation_step

## Agent specific parameter collection for generation features,
## extended by inheriting classes.
# var parameters : KuikkaAgentParameters'

## Terrain image used as reference for feature generation.
var terrain_image : TerrainFeatureImage

## Dictionary of features from [terrain_image.features] relevant to this
## agent.
var parameters : Dictionary = {}

var agent_type : StringName = ""

var blend_multiplier : float = 0.05

## RNG for making random actions in deterministic way
var rng : WeightedRNG = WeightedRNG.new()

## Generation seed for RNG
var seed : int = 0:
	set(val):
		seed = val
		rng.set_seed(seed)

## Starting state for RNG to be set by [TerrainServerGD] to avoid each agent
## possibly taking same actions when using same seed.
var state : int = 0:
	set(val):
		state = val
		rng.set_state(state)
	
var heightmap : Image
var gene_mask : Image

## Tokens for agent to consume when taking actions. When tokens are
## depleted generation process is considered completed.
var tokens: int = 0:
	set(val):
		tokens = val
		if tokens <= 0:
			pass
			# generation_finished.emit(self)
			# process_mode = Node.PROCESS_MODE_DISABLED

## Mapped area of effect
var area_silhouette : Dictionary = {
	"agent_travel" :  [],
	"covered_points" : [], # Array of Array[Vector2i] of travel center points.
	"covered_rect" : [],	# Array of Array[Vector2i] of travel coverage rect corner points.
	"gene_points" : [], 	# Array of Vector2
	"gene_weights": [], # Array of float,
	"gene_mask": gene_mask, # Image,
	"voronoi": [] # Array of Delaunay.VoronoiSite
}

## Offset for blending brush rect centered around point.
var offset : Vector2i:
	get:
		return Vector2i(brush_size/2, brush_size/2)

var gene_placement : GeneDistribute = GeneDistribute.RECT

## Image mask for brush to blend to.
var brush : Image
## Size of brush in pixels.
var brush_size : int = 64

var _delaunay = Delaunay.new()


func _init():
	agent_type = &"KuikkaTerrainAgent"


# Called when the node enters the scene tree for the first time.
func _ready():
	process_mode = Node.PROCESS_MODE_DISABLED


func _physics_process(delta):
	pass

## Generation step for agent. Should be implemented by inheriting agents
## to implement generation logic.
func _generation_process():
	generation_step.emit()


## Make necessary preparations and start generation process.
## Should be extended by inheriting agents to make necessary preparations.
func start_generation():
	# Start generation if there are tokens left. Otherwise consider generation
	# instantly completed.
	if tokens > 0:
		print_debug(agent_type, " started run with ", tokens, " tokens.")
		generation_step.connect(func():
									if tokens > 0:
										_generation_process()
									else:
										finish_generation())
		_generation_process.call_deferred()
	else:
		print_debug(agent_type, " no tokens assigned. Skipping generation.")
		finish_generation()


func finish_generation():
	_map_covered_points()
	_create_gene_map()
	process_mode = Node.PROCESS_MODE_DISABLED
	generation_finished.emit(self)


## Create weighted gene map based on agent movements and brush mask.
func _create_gene_map():
	match gene_placement:
		GeneDistribute.RECT:
			_genes_bounding_box()
		GeneDistribute.DELAUNAY:
			_genes_triangulated_bounding_box()
		# GeneDistribute.CONCAVE:
		GeneDistribute.DIRECT:
			_genes_travel_direct()
		_:
			_genes_travel_linear()
		
	area_silhouette["gene_mask"] = gene_mask


## --- Gene coverage options ---

func _genes_travel_linear():
	print_debug("Using linear travel placement for gene points.")
	var points = []
	
	for item in area_silhouette.covered_points:
		points.append_array(item)
	
	
	points = KuikkaUtils.merge_points_by_distance(points, terrain_image.evolution.gene_point_size)
	area_silhouette.gene_points = points
	return


func _genes_travel_direct():
	print_debug("Using direct travel placement for gene points.")
	var points = []
	
	for item in area_silhouette.covered_points:
		points.append_array(item)
	
	area_silhouette.gene_points = points
	return


## Create gene placements from bounding rectangle.
func _genes_bounding_box():
	print_debug("Using bounding rect placement for gene points.")
	var points = []
	var weights = []
	
	for i in area_silhouette.covered_points.size():
		var travel = area_silhouette.covered_points[i]
		var rect = area_silhouette.covered_rect[i]
		
		points.append_array(area_silhouette.covered_points[i])
		# Get weight from effect area mask alpha
		points.append_array(area_silhouette.covered_rect[i])
	
	# Merge by distance
	points = KuikkaUtils.merge_points_by_distance(points, terrain_image.evolution.gene_point_size)
	
	weights.append_array(points.map(func(p): 
		if p.x > 0 and p.x < gene_mask.get_width() and \
		p.y > 0 and p.y < gene_mask.get_height():
			return gene_mask.get_pixel(p.x, p.y).a
		else:
			return 1.0))
	
	area_silhouette.gene_points = points
	area_silhouette.gene_weights = weights
	return
	

## Create gene placements as points from delaunay triangulation.
func _genes_triangulated_bounding_box():
	print_debug("Using Delaunay triangulation placement for gene points.")
	# TODO: weights
	var weights = []
	
	var del : Delaunay = Delaunay.new()
	# TODO: Using Delaunay here will always result in convex
	# polygon which might not be the optimal coverage mask.
	# Implement something using knowledge of area_silhouette.covered_rect
	# rectangle bounding boxes to select boundaries by it instead.
	for travel in area_silhouette.covered_points:
		for p in travel:
			del.add_point(p)
	
	var triangulation = del.triangulate()
	var points = KuikkaUtils.triangulation_get_unique_points(triangulation)
	area_silhouette.gene_points = points
	area_silhouette.gene_weights = weights
	return


## Create gene placements in grid inside concave bounding box.
func _genes_concave_bounding_box():
	printerr("Concave bounding box not yet supported!")

## --- --- --- 


## Add mapped points for calculating agent travel covered points.
func _append_covered_points(pos: Vector2i, offset: Vector2i):
	# area_silhouette.covered_points.append(pos)
	var points = _get_covered_points(pos, offset)
	area_silhouette.covered_points[-1].append_array(points)


## Calculate agent travel covered points as mask bounding points
## for square with side length of [param offset] around point [param pos]
func _get_covered_points(pos: Vector2i, offset: Vector2i, include_center=true) -> Array:
	
	# Get square bounds around given points with side length of offset
	var points = []
	
	if include_center:
		points.append(pos)
	points.append(pos-offset)
	points.append(pos+offset)
	points.append(pos-offset * Vector2i(-1, 1))
	points.append(pos-offset * Vector2i(1, -1))
	return points


## Calculate agent travel covered points as [Rect2i] square
## with side length of [param offset] around point [param pos].
func _get_covered_rectangle(pos: Vector2i, offset: Vector2i) -> Rect2i:
	
	# Get square bounds around given points with side length of offset
	var result : Rect2i = Rect2i(pos-offset, offset*2)
	return result


## Map whole coverage as mask around agent_travel [Curve2D] points.
func _map_covered_points():
	# Create point arrays for each curve separately to
	# separate silhouettes in triangulation phase.
	for curve : Curve2D in area_silhouette.agent_travel:
		var points = []
		var rects = []
		
		# Add bounding square/rectangle of each travel point
		# to points covered by the final polygon of the travel.
		for p in curve.get_baked_points():
			points.append(p)
			rects.append_array(_get_covered_points(p, offset, false))
		
		area_silhouette.covered_points.append(points)
		area_silhouette.covered_rect.append(rects)
	return


## Modulate brush by multiplying with color.
func _modulate_brush(c: Color):
		
	# Flip brush to black for 
	for x in brush.get_width():
		for y in brush.get_height():
			var bc: Color = brush.get_pixel(x, y)
			brush.set_pixel(x, y, bc*c)


## Modulate brush alpha by multiplying with value
func _modulate_brush_alpha(a: float):
	a = clampf(a, 0.0, 1.0)
	
	# Flip brush to black for lakes
	for x in brush.get_width():
		for y in brush.get_height():
			var bc = brush.get_pixel(x, y)
			brush.set_pixel(x, y, Color(bc.r, bc.g, bc.b, bc.a * a))


func _update_brush_size(size):
	brush.resize(size, size)
