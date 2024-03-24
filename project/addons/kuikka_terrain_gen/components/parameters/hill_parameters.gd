class_name KuikkaHillParameters extends KuikkaAgentParameters

## Generation parameters for [KuikkaHillAgent]

## Length of agent movement in pixels
@export var move_speed : Vector2 = Vector2(6, 10)
## Sway of changing direction of hill agent movement
@export var direction_sway : float = PI/2

## Treshold at which agent will seek new starting point.
@export_range(0, 1) var jump_treshold: float = 0.1

## Minimum height at which hill will be generated.
@export_range(0, 1) var generation_treshold : float = 0.5

