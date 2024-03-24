class_name KuikkaTerrainAgent extends Node

## * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
## 	Base class for terrain agents that generate heightmap features.
## 	base class implements [method _generation_process] loop similar to
## 	Godot's [method Node._process] and [method Node._physics_process]. 
## 	[method _generation_process] acts as generation step for advancing agent
##	should be called by [TerrainServerGD] for each agent in its
## 	own [method Node._process] or [method Node._physics_process] loop.

signal generation_finished(agent: KuikkaTerrainAgent)

var agent_type : StringName = ""

## RNG for making random actions in deterministic way
var rng : RandomNumberGenerator = RandomNumberGenerator.new()

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

## Tokens for agent to consume when taking actions. When tokens are
## depleted generation process is considered completed.
var tokens: int = 0:
	set(val):
		tokens = val
		if tokens <= 0:
			generation_finished.emit(self)
			process_mode = Node.PROCESS_MODE_DISABLED

## Mapped area of effect
var area_silhouette : Array[Curve2D]

## Image mask for brush to blend to.
var brush : Image
## Size of brush in pixels.
var brush_size : int = 64


func _init():
	agent_type = &"KuikkaTerrainAgent"


# Called when the node enters the scene tree for the first time.
func _ready():
	process_mode = Node.PROCESS_MODE_DISABLED


func _physics_process(delta):
	if tokens > 0:
		_generation_process()
	else:
		finish_generation()


## Generation step for agent. Should be implemented by inheriting agents
## to implement generation logic.
func _generation_process():
	pass


## Make necessary preparations and start generation process.
## Should be extended by inheriting agents to make necessary preparations.
func start_generation():
	# Start generation if there are tokens left. Otherwise consider generation
	# instantly completed.
	if tokens > 0:
		process_mode = Node.PROCESS_MODE_INHERIT
	else:
		finish_generation()


func finish_generation():
	process_mode = Node.PROCESS_MODE_DISABLED
	generation_finished.emit(self)


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
