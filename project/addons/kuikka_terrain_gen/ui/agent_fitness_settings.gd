class_name AgentFitnessUI extends MarginContainer

signal fitness_min_height_changed(value: float, agent: String)
signal fitness_max_height_changed(value: float, agent: String)
signal fitness_mean_height_changed(value: float, agent: String)
signal fitness_variance_changed(value: float, agent: String)
signal fitness_frequency_changed(value: float, agent: String)


## UI Element for collecting user input fitness settings for given agent.
@export var fitness: FitnessParameters

@export var agent_name : String:
	set(val):
		agent_name = val
		if %Title: %Title.text = agent_name


# Called when the node enters the scene tree for the first time.
func _ready():
	if not fitness:
		fitness = FitnessParameters.new()
	
	%Title.text = agent_name


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

## * * * * * * * * * * * * * * * * * * 
## Signal catchers for settings from ui

func _on_minvalue_value_changed(value):
	fitness.min_height = value
	fitness_min_height_changed.emit(value, agent_name)


func _on_max_value_value_changed(value):
	fitness.max_height = value
	fitness_max_height_changed.emit(value, agent_name)
	

func _on_h_slider_frequency_value_changed(value):
	fitness.hill_frequency = value
	fitness_frequency_changed.emit(value, agent_name)


func _on_variance_spin_box_value_changed(value):
	fitness.variance = value
	fitness_variance_changed.emit(value, agent_name)


func _on_mean_spin_box_value_changed(value):
	fitness.mean = value
	fitness_mean_height_changed.emit(value, agent_name)
	

