class_name KuikkaAgentParameters extends Resource

## Parameter colletion for single agent should be extended for each
## type of [KuikkaTerrainAgent] used to contain necessary parameters.


## Amount of token agent starts with
@export var initial_tokens : int = 10

@export_range(0, 1) var blend_weight : float = 0.8
